#!/usr/bin/env perl
# ABSTRACT: simple_embedding_result / simple_transcription_call / simple_image_result over real LWP and Net::Async::HTTP: sync/async parity of the CallResult
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Net::Async::HTTP; require IO::Async::Loop; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async (the async backend under test)';
}

use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OpenAI;

# karr k314 (ADR 0034, ADR 0027 parity): the CallResult a non-chat call
# returns -- value, usage, rate limit, model, timing -- must be the same
# whether the call ran sync over LWP, async over Net::Async::HTTP or over the
# sync LWP shim a clean install falls back to. Rate limit and usage come from
# real response headers and bodies here, not from a mock of either library.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my @RATE = ( 'x-ratelimit-remaining-requests' => 42, 'x-ratelimit-limit-requests' => 50 );

sub json_response {
  HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json', @RATE ], $json->encode( $_[0] ) );
}

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($request) = @_;
  my $path = $request->uri->path;
  return HTTP::Response->new( 429, 'Too Many Requests',
    [ 'Content-Type' => 'application/json', 'Retry-After' => 3, @RATE ],
    $json->encode({ error => { message => 'Slow down' } }) ) if $path =~ m{^/limited/};
  return json_response({ model => 'text-embedding-3-large-v9',
      data => [ { index => 0, embedding => [ 0.5, 1 ] } ], usage => { prompt_tokens => 2, total_tokens => 2 } })
    if $path =~ m{/embeddings\z};
  return json_response({ text => 'transcript',
      usage => { type => 'tokens', input_tokens => 10, output_tokens => 3, total_tokens => 13 } })
    if $path =~ m{/audio/transcriptions\z};
  return json_response({ created => 1, data => [ { b64_json => 'aGk=' } ],
      usage => { input_tokens => 9, output_tokens => 100, total_tokens => 109 } })
    if $path =~ m{/images/generations\z};
  return HTTP::Response->new( 404, 'Not Found' );
} );
my $base = $server->url;
my $loop = IO::Async::Loop->new;

sub engine {
  my ( $url, $backend ) = @_;
  return Langertha::Engine::OpenAI->new( api_key => 'sk-test', url => $url,
    $backend eq 'shim' ? ( _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ) ) : () );
}

# One call on all three paths; returns { backend => { result, error, engine } }.
sub run_all {
  my ( $url, $method, @args ) = @_;
  my %out;
  my $sync = engine( $url, 'sync' );
  $out{sync} = eval { { result => $sync->$method(@args), error => '' } } // { error => $@ };
  $out{sync}{engine} = $sync;
  for my $backend (qw( nahttp shim )) {
    my $e = engine( $url, $backend );
    my $method_f = "${method}_f";
    my $f = $e->$method_f(@args);
    $loop->await($f) unless $f->is_ready;
    $out{$backend} = $f->is_done ? { result => $f->get, error => '' } : { error => scalar $f->failure };
    $out{$backend}{engine} = $e;
  }
  s/ at \S+ line \d+\.?\n?\z// for map { $_->{error} } values %out;
  return \%out;
}

sub parity {
  my ( $out, %want ) = @_;
  for my $backend (qw( sync nahttp shim )) {
    my $r = $out->{$backend}{result};
    is $out->{$backend}{error}, '', "no error ($backend)";
    isa_ok $r, 'Langertha::CallResult';
    is_deeply $r->value, $want{value}, "value ($backend)";
    is $r->usage->total_tokens, $want{total_tokens}, "usage ($backend)";
    is $r->rate_limit->requests_remaining, 42, "rate limit ($backend)";
    is $r->model, $want{model}, "model ($backend)";
    ok $r->has_total_seconds && $r->total_seconds > 0, "total_seconds measured ($backend)";
  }
}

subtest 'simple_embedding_result' => sub {
  parity( run_all( "$base/ok/v1", 'simple_embedding_result', 'hello' ),
    value => [ 0.5, 1 ], total_tokens => 2, model => 'text-embedding-3-large-v9' );
};

subtest 'simple_transcription_call' => sub {
  my $audio = join '', map { chr } 0 .. 255;
  parity( run_all( "$base/ok/v1", 'simple_transcription_call', \$audio, filename => 'a.wav' ),
    value => 'transcript', total_tokens => 13, model => 'gpt-transcribe' );
};

subtest 'simple_image_result' => sub {
  parity( run_all( "$base/ok/v1", 'simple_image_result', 'cat' ),
    value => [ { b64_json => 'aGk=' } ], total_tokens => 109, model => 'gpt-image-2' );
};

subtest 'a 429 fails with the same text everywhere and leaves the rate limit on the engine' => sub {
  my $out = run_all( "$base/limited/v1", 'simple_embedding_result', 'hello' );
  for my $backend (qw( sync nahttp shim )) {
    like $out->{$backend}{error}, qr/429 Too Many Requests \(retry after 3s\).*Slow down/,
      "failure text ($backend)";
    is $out->{$backend}{engine}->rate_limit->requests_remaining, 42, "engine rate limit ($backend)";
  }
  is $out->{nahttp}{error}, $out->{sync}{error}, 'async text equals sync text';
};

done_testing;
