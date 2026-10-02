#!/usr/bin/env perl
# ABSTRACT: Public hooks a sibling agent dist builds on instead of core privates (k190/k192)
use strict; use warnings;
use Test2::Bundle::More;

# langertha-raider used to call $engine->_async_http->do_request,
# $engine->_async_http->loop, $engine->_langfuse_timestamp and parsed provider
# usage by hand. These tests pin the public contract that replaces those reach-ins.

BEGIN {
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use Future;
use Future::AsyncAwait;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use Langertha::Usage;
use Langertha::Engine::OpenAI;

{
  package RecordingClient;
  sub new { bless { calls => [] }, shift }
  sub do_request {
    my ($self, %args) = @_;
    push @{ $self->{calls} }, \%args;
    return Future->done( $self->{response} );
  }
}

sub engine_with { Langertha::Engine::OpenAI->new( api_key => 'testkey', model => 'gpt-4o-mini', @_ ) }

subtest 'async_request_f: public face of the do_request contract' => sub {
  my $client = RecordingClient->new;
  $client->{response} = HTTP::Response->new( 200, 'OK', [], '{"ok":1}' );
  my $engine  = engine_with( _async_http => $client );
  my $request = HTTP::Request->new( POST => 'http://example.invalid/v1/chat/completions' );

  my $f = $engine->async_request_f($request);
  isa_ok( $f, ['Future'], 'returns a Future' );
  my $response = $f->get;
  isa_ok( $response, ['HTTP::Response'], 'resolves to the HTTP::Response' );
  is( $response->content, '{"ok":1}', 'the backend response is returned verbatim' );
  is( scalar @{ $client->{calls} }, 1, 'one backend call' );
  is( $client->{calls}[0]{request}, $request, 'the request is handed to do_request as request =>' );

  my $on_header = sub { };
  $engine->async_request_f( $request, on_header => $on_header )->get;
  is( $client->{calls}[1]{on_header}, $on_header, 'on_header passes through for streaming' );
};

subtest 'async_request_f: an HTTP error status resolves, the caller checks is_success' => sub {
  my $client = RecordingClient->new;
  $client->{response} = HTTP::Response->new( 429, 'Too Many Requests', [], 'slow down' );
  my $engine = engine_with( _async_http => $client );
  my $f = $engine->async_request_f( HTTP::Request->new( GET => 'http://example.invalid/' ) );
  ok( $f->is_done, 'a 4xx resolves the future, it does not fail it' );
  ok( !$f->get->is_success, 'the error status is on the response' );
};

subtest 'async_request_f: works over the SyncHTTP fallback backend' => sub {
  require Langertha::Request::SyncHTTP;
  {
    package CannedUA;
    use parent 'LWP::UserAgent';
    sub request { HTTP::Response->new( 200, 'OK', [], 'sync body' ) }
  }
  my $engine = engine_with( _async_http => Langertha::Request::SyncHTTP->new( user_agent => CannedUA->new ) );
  my $f = $engine->async_request_f( HTTP::Request->new( GET => 'http://example.invalid/' ) );
  ok( $f->is_ready, 'already complete: no event loop needed' );
  is( $f->get->content, 'sync body', 'resolves with the sync response' );
};

subtest 'async_loop: undef where the backend has no loop (Maybe[loop])' => sub {
  is( engine_with( _async_http => RecordingClient->new )->async_loop, undef,
    'an injected client without ->loop: undef' );
  require Langertha::Request::SyncHTTP;
  my $sync = Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new );
  is( engine_with( _async_http => $sync )->async_loop, undef, 'the sync fallback: undef, no loop promised' );
};

SKIP: {
  skip 'Net::Async::HTTP not installed', 2
    unless eval { require Net::Async::HTTP; require IO::Async::Loop; require IO::Async::Loop::Poll; 1 };

  subtest 'async_loop: the loop the active backend runs on' => sub {
    my $default = engine_with();
    is( $default->async_loop, $default->_async_loop, 'default backend: the loop it was added to' );
    is( $default->async_loop, IO::Async::Loop->new, 'which by default is the process-wide loop' );

    my $foreign = IO::Async::Loop::Poll->new;
    isnt( $foreign, IO::Async::Loop->new, 'test setup: a loop that is not the singleton' );

    my $http = Net::Async::HTTP->new;
    $foreign->add($http);
    my $injected = engine_with( _async_http => $http );
    is( $injected->async_loop, $foreign, 'injected client on a foreign loop: THAT loop' );

    my $ctor = engine_with( _async_loop => $foreign );
    is( $ctor->async_loop, $foreign, '_async_loop constructor arg: the default backend sits on it' );
    $foreign->remove($_) for grep { $_->loop } $http, $ctor->_async_http;
  };

  subtest 'async_loop: a timer on it completes inside a chain driven by the backend loop' => sub {
    my $foreign = IO::Async::Loop::Poll->new;
    my $http = Net::Async::HTTP->new;
    $foreign->add($http);
    my $engine = engine_with( _async_http => $http );
    my $chain = (async sub {
      await $foreign->delay_future( after => 0.01 );   # stands in for the engine's HTTP
      await $engine->async_loop->delay_future( after => 0.01 );
      return 'done';
    })->();
    local $SIG{ALRM} = sub { die "hang: timer on a loop nobody drives\n" };
    alarm 5;
    my $result = eval { $chain->get };
    alarm 0;
    is( $result, 'done', 'no hang: one loop drives both awaits' );
    $foreign->remove($http);
  };
}

subtest 'langfuse_timestamp: public "now" in the Langfuse ISO format' => sub {
  my $engine = engine_with();
  my $ts = $engine->langfuse_timestamp;
  like( $ts, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z\z/, 'ISO-8601 UTC with milliseconds' );
  my ($year) = $ts =~ /\A(\d{4})/;
  is( $year, (gmtime)[5] + 1900, 'UTC now' );
  like( $engine->_langfuse_timestamp, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z\z/,
    'the private name keeps working' );
};

subtest 'Usage->from_raw: locates usage in every raw body shape' => sub {
  my @cases = (
    [ 'OpenAI chat', { usage => { prompt_tokens => 10, completion_tokens => 4, total_tokens => 14 } }, 10, 4, 14 ],
    [ 'Anthropic',   { usage => { input_tokens => 7, output_tokens => 3 } }, 7, 3, 10 ],
    [ 'Gemini',      { usageMetadata => { promptTokenCount => 11, candidatesTokenCount => 5, totalTokenCount => 20 } }, 11, 5, 20 ],
    [ 'Ollama native', { message => {}, prompt_eval_count => 6, eval_count => 2 }, 6, 2, 8 ],
    [ 'Responses envelope', { type => 'response.completed', response => { usage => { input_tokens => 9, output_tokens => 1, total_tokens => 10 } } }, 9, 1, 10 ],
  );
  for my $case (@cases) {
    my ( $name, $data, $in, $out, $total ) = @$case;
    my $usage = Langertha::Usage->from_raw($data);
    isa_ok( $usage, ['Langertha::Usage'], "$name: a Usage" );
    is( $usage->input_tokens,  $in,    "$name: input_tokens" );
    is( $usage->output_tokens, $out,   "$name: output_tokens" );
    is( $usage->total_tokens,  $total, "$name: total_tokens" );
  }
};

subtest 'Usage->from_raw: undef when the body reports no usage' => sub {
  is( Langertha::Usage->from_raw({ choices => [] }), undef, 'no usage block' );
  is( Langertha::Usage->from_raw({ usage => 'nope' }), undef, 'a non-hash usage is no usage' );
  is( Langertha::Usage->from_raw(undef), undef, 'undef body' );
  is( Langertha::Usage->from_raw([]), undef, 'non-hash body' );
  my $body = { choices => [] };
  Langertha::Usage->from_raw($body);
  ok( !exists $body->{response}, 'probing does not autovivify the caller body' );
};

subtest 'Usage->from_hash reads Gemini camelCase; existing spellings win' => sub {
  my $usage = Langertha::Usage->from_hash({ promptTokenCount => 3, candidatesTokenCount => 2, totalTokenCount => 6 });
  is_deeply( [ $usage->input_tokens, $usage->output_tokens, $usage->total_tokens ], [ 3, 2, 6 ], 'camelCase counts' );
  my $mixed = Langertha::Usage->from_hash({ prompt_tokens => 8, promptTokenCount => 3 });
  is( $mixed->input_tokens, 8, 'snake_case wins over camelCase' );
};

subtest 'Usage->from_response: old inputs unchanged, raw Gemini bodies understood' => sub {
  my $old = Langertha::Usage->from_response({ usage => { prompt_tokens => 5, completion_tokens => 7 } });
  is( $old->total_tokens, 12, 'usage-key hash as before' );
  my $none = Langertha::Usage->from_response({ choices => [] });
  isa_ok( $none, ['Langertha::Usage'], 'still always a Usage' );
  is( $none->total_tokens, 0, 'zeros when absent, as before' );
  my $gemini = Langertha::Usage->from_response({ usageMetadata => { promptTokenCount => 4, candidatesTokenCount => 1 } });
  is( $gemini->input_tokens, 4, 'Gemini raw body now parsed' );
};

done_testing;
