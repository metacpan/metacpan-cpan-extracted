use strict;
use warnings;
use Test2::V0;

# Langfuse's ingestion API stores a generation's token usage only under its
# own keys. Sent as Langertha::Usage's canonical input_tokens / output_tokens
# / total_tokens, the keys are dropped on ingestion and the generation shows
# 0 / 0 / 0 although the provider reported real counts (verified against
# Langfuse 2.95.11). Every assertion below reads the batch as a fake Langfuse
# received it over HTTP, so the whole path -- mapping, JSON encode, POST --
# is the real one.
#
# The shape sent works on both server generations: `usage` { input, output,
# total, unit } is what Langfuse v2 reads, `usageDetails` { input, output,
# total } what v3 reads (and it wins over `usage` there); v2's schema strips
# the key it does not know.

use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;
use Time::HiRes qw( time );

use Langertha::Response;
use Langertha::Usage;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::Passthrough;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Fake Langfuse: keeps every ingestion batch it is sent.
my @batches;
my $langfuse = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ( $server, $req ) = @_;
    push @batches, {
      path => $req->path,
      auth => scalar $req->header('Authorization'),
      body => $json->decode( $req->body ),
    };
    my $resp = HTTP::Response->new(207);
    $resp->content_type('application/json');
    $resp->content('{"successes":[],"errors":[]}');
    $resp->content_length( length $resp->content );
    $req->respond($resp);
  },
);
$loop->add($langfuse);
$langfuse->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $langfuse_url = 'http://127.0.0.1:' . $langfuse->read_handle->sockport;

sub tracing {
  return Langertha::Knarr::Tracing->new( config => Langertha::Knarr::Config->new( data => {
    models   => {},
    langfuse => { public_key => 'pk-lf-test', secret_key => 'sk-lf-test', url => $langfuse_url },
  } ) );
}

# The generation-update of the next batch Langfuse receives.
sub next_generation_update {
  my $deadline = time + 5;
  $loop->loop_once(0.05) until @batches || time > $deadline;
  my $batch = shift @batches or return fail('Langfuse received no batch');
  is $batch->{path}, '/api/public/ingestion', 'posted to the ingestion endpoint';
  my ($gen) = grep { $_->{type} eq 'generation-update' } @{ $batch->{body}{batch} };
  ok $gen, 'batch carries a generation-update' or return;
  return $gen->{body};
}

sub traced_usage {
  my ($usage) = @_;
  my $tracing = tracing();
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai',
    messages => [ { role => 'user', content => 'hi' } ] );
  $tracing->end_trace( $trace, output => 'hi', defined $usage ? ( usage => $usage ) : () );
  return next_generation_update();
}

my %LANGFUSE_USAGE = ( usage => { input => 3, output => 4, total => 7, unit => 'TOKENS' },
                       usageDetails => { input => 3, output => 4, total => 7 } );

subtest 'routed response: Langertha::Usage reaches Langfuse under its keys' => sub {
  my $tracing = tracing();
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub {
      Langertha::Response->new( content => 'hi', model => 'gpt-test',
        usage => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 } );
    } ),
    tracing => $tracing,
  );
  my $r = $handler->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'openai', model => 'gpt-test',
      messages => [ { role => 'user', content => 'hi' } ] ) )->get;
  is $r->content, 'hi', 'response passed through the decorator';

  my $gen = next_generation_update() or return;
  is $gen->{usage},        $LANGFUSE_USAGE{usage},        'usage: v2 shape with the real counts';
  is $gen->{usageDetails}, $LANGFUSE_USAGE{usageDetails}, 'usageDetails: v3 shape with the real counts';
  ok !exists $gen->{usage}{$_}, "no $_ key Langfuse would drop"
    for qw( input_tokens output_tokens total_tokens );
};

subtest 'a Langertha::Usage object maps the same' => sub {
  my $gen = traced_usage( Langertha::Usage->new( input_tokens => 3, output_tokens => 4 ) ) or return;
  is { map { $_ => $gen->{$_} } qw( usage usageDetails ) }, \%LANGFUSE_USAGE,
    'total derived from input + output';
};

# A provider's own usage hash (what a raw upstream body carries) maps the
# same way as the routed path's Langertha::Usage.
for my $case (
  [ 'OpenAI'    => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 } ],
  [ 'Anthropic' => { input_tokens => 3, output_tokens => 4 } ],
  [ 'Ollama'    => { prompt_eval_count => 3, eval_count => 4 } ],
  [ 'Langfuse'  => { input => 3, output => 4, total => 7 } ],
  [ 'Langfuse, counts as strings' => { input => '3', output => '4' } ],
) {
  my ( $name, $usage ) = @$case;
  subtest "$name usage hash" => sub {
    my $gen = traced_usage($usage) or return;
    is { map { $_ => $gen->{$_} } qw( usage usageDetails ) }, \%LANGFUSE_USAGE,
      'mapped to the Langfuse keys';
  };
}

subtest 'no usage: no usage keys, not a 0/0/0' => sub {
  for my $usage ( undef, {}, { error => 'overloaded' }, { prompt_tokens_details => { cached_tokens => 0 } },
                  Langertha::Usage->from_hash( { error => 'overloaded' } ) ) {
    my $gen = traced_usage($usage) or return;
    ok !exists $gen->{usage},        'no usage';
    ok !exists $gen->{usageDetails}, 'no usageDetails';
  }
};

# k65: prompt-cache counts. Langfuse's usage details are exclusive buckets:
# input is the uncached input, cache reads go to input_cached_tokens, cache
# writes to input_cache_creation, and total is the sum -- Langfuse prices
# each bucket, so a count in two of them is charged twice. Anthropic counts
# its cache beside input_tokens, OpenAI's cached_tokens is part of
# prompt_tokens. v2's usage knows no buckets and keeps the whole input.
my %ANTHROPIC_CACHED = ( input_tokens => 12, cache_read_input_tokens => 50000,
                         cache_creation_input_tokens => 2000, output_tokens => 300 );
my %LANGFUSE_ANTHROPIC_CACHED = (
  usage        => { input => 52012, output => 300, total => 52312, unit => 'TOKENS' },
  usageDetails => { input => 12, input_cached_tokens => 50000, input_cache_creation => 2000,
                    output => 300, total => 52312 },
);

for my $case (
  [ 'Anthropic, cache read and write' => { %ANTHROPIC_CACHED }, \%LANGFUSE_ANTHROPIC_CACHED ],
  [ 'Anthropic, cache counts as strings' =>
    { map { $_ => "$ANTHROPIC_CACHED{$_}" } keys %ANTHROPIC_CACHED }, \%LANGFUSE_ANTHROPIC_CACHED ],
  [ 'Anthropic, as a Langertha::Usage' =>
    Langertha::Usage->from_hash( { %ANTHROPIC_CACHED } ), \%LANGFUSE_ANTHROPIC_CACHED ],
  [ 'OpenAI, cached_tokens inside prompt_tokens' =>
    { prompt_tokens => 50012, completion_tokens => 300, total_tokens => 50312,
      prompt_tokens_details => { cached_tokens => 50000 } },
    { usage        => { input => 50012, output => 300, total => 50312, unit => 'TOKENS' },
      usageDetails => { input => 12, input_cached_tokens => 50000, output => 300, total => 50312 } } ],
  [ 'OpenAI, cache write inside prompt_tokens' =>
    { prompt_tokens => 100, completion_tokens => 5,
      prompt_tokens_details => { cached_tokens => 60, cache_write_tokens => 30 } },
    { usage        => { input => 100, output => 5, total => 105, unit => 'TOKENS' },
      usageDetails => { input => 10, input_cached_tokens => 60, input_cache_creation => 30,
                        output => 5, total => 105 } } ],
  [ 'OpenAI, no cache hit' =>
    { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7,
      prompt_tokens_details => { cached_tokens => 0 } }, \%LANGFUSE_USAGE ],
  [ 'Anthropic message_delta, output only' => { output_tokens => '7' },
    { usage        => { input => 0, output => 7, total => 7, unit => 'TOKENS' },
      usageDetails => { input => 0, output => 7, total => 7 } } ],
  [ 'Langfuse keys with cache buckets' =>
    { input => 12, input_cached_tokens => 50000, input_cache_creation => 2000, output => 300 },
    \%LANGFUSE_ANTHROPIC_CACHED ],
) {
  my ( $name, $usage, $expect ) = @$case;
  subtest "cache: $name" => sub {
    my $before = ref $usage eq 'HASH' ? $json->encode($usage) : undef;
    my $gen = traced_usage($usage) or return;
    is { map { $_ => $gen->{$_} } qw( usage usageDetails ) }, $expect,
      'each count in exactly one bucket';
    is $json->encode($usage), $before, 'the provider hash is left as it was' if defined $before;
  };
}

subtest 'cache: routed response' => sub {
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub {
      Langertha::Response->new( content => 'hi', model => 'claude-test',
        usage => { %ANTHROPIC_CACHED } );
    } ),
    tracing => tracing(),
  );
  $handler->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'claude-test',
      messages => [ { role => 'user', content => 'hi' } ] ) )->get;
  my $gen = next_generation_update() or return;
  is { map { $_ => $gen->{$_} } qw( usage usageDetails ) }, \%LANGFUSE_ANTHROPIC_CACHED,
    'the engine\'s cache counts in their own buckets';
};

{
  package CachedUsageStream::Handler;
  use Moose;
  extends 'Langertha::Knarr::Handler::Code';
  sub handle_stream_f {
    my @parts = ( 'Hel', 'lo' );
    return Future->done( Langertha::Knarr::Stream->new(
      generator => sub { @parts ? shift @parts : undef },
      usage     => { %ANTHROPIC_CACHED },
    ) );
  }
  __PACKAGE__->meta->make_immutable;
}

subtest 'cache: routed stream' => sub {
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => CachedUsageStream::Handler->new( code => sub { 'unused' } ),
    tracing => tracing(),
  );
  my $stream = $handler->handle_stream_f( Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'claude-test', stream => 1,
      messages => [ { role => 'user', content => 'hi' } ] ) )->get;
  1 while defined $stream->next_chunk_f->get;
  my $gen = next_generation_update() or return;
  is { map { $_ => $gen->{$_} } qw( usage usageDetails ) }, \%LANGFUSE_ANTHROPIC_CACHED,
    'the stream\'s cache counts in their own buckets';
};

# Raw passthrough pipes the upstream bytes 1:1; its trace reads the usage off
# a copy of them (k61), so the generation carries the upstream's own counts
# under Langfuse's keys -- the same mapping as a routed response.
subtest 'raw passthrough: the upstream\'s usage under Langfuse\'s keys' => sub {
  my $backend = Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Code->new( code => sub {
      Langertha::Response->new( content => 'UPSTREAM', model => 'gpt-mystery',
        usage => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 } );
    } ),
    loop => $loop,
    port => 0,
  );
  $backend->start;
  my $bport = $backend->_server->read_handle->sockport;

  my $config = Langertha::Knarr::Config->new( data => {
    models => {}, default => undef,
    passthrough => { openai => "http://127.0.0.1:$bport" },
  } );
  my $router = Langertha::Knarr::Router->new( config => $config );
  my $passthrough = Langertha::Knarr::Handler::Passthrough->new(
    upstreams => $config->passthrough, loop => $loop );
  my $front = Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Router->new(
      router => $router, passthrough => $passthrough ),
    loop            => $loop,
    port            => 0,
    router          => $router,
    raw_passthrough => $passthrough,
    tracing         => tracing(),
  );
  $front->start;
  my $fport = $front->_server->read_handle->sockport;

  my $http = Net::Async::HTTP->new;
  $loop->add($http);
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$fport/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->header( Authorization => 'Bearer sk-client' );
  $req->content( $json->encode( { model => 'gpt-mystery',
    messages => [ { role => 'user', content => 'hi' } ] } ) );
  my $resp = $http->do_request( request => $req )->get;
  is $resp->code, 200, 'raw passthrough answered';
  like $resp->decoded_content, qr/"prompt_tokens":3/, 'upstream usage reached the client 1:1';

  my $gen = next_generation_update() or return;
  is $gen->{output}, '[passthrough]', 'the passthrough generation';
  is $gen->{usage},        $LANGFUSE_USAGE{usage},        'usage: v2 shape with the upstream counts';
  is $gen->{usageDetails}, $LANGFUSE_USAGE{usageDetails}, 'usageDetails: v3 shape with the upstream counts';
};

done_testing;
