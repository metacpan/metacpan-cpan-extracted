use strict;
use warnings;
use utf8;
use Test2::V0;

# langfuse.transport: otel sends each traced request to Langfuse's OTLP/HTTP
# endpoint as JSON-encoded OpenTelemetry spans instead of an ingestion batch.
# Every assertion reads the request a fake Langfuse received over HTTP, so
# the span building, the JSON encode and the POST are the real path. The
# default transport stays the ingestion API.

use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;
use Encode qw( encode_utf8 );
use MIME::Base64 qw( encode_base64 );
use Time::HiRes qw( time );

use Langertha::Response;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Tracing;
use Future;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::Passthrough;

delete local $ENV{KNARR_LANGFUSE_TRANSPORT};

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Fake Langfuse: keeps every POST it is sent.
my @posts;
my $langfuse = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ( $server, $req ) = @_;
    push @posts, {
      path    => $req->path,
      auth    => scalar $req->header('Authorization'),
      type    => scalar $req->header('Content-Type'),
      version => scalar $req->header('x-langfuse-ingestion-version'),
      body    => $json->decode( $req->body ),
    };
    my $resp = HTTP::Response->new(200);
    $resp->content_type('application/json');
    $resp->content('{}');
    $resp->content_length( length $resp->content );
    $req->respond($resp);
  },
);
$loop->add($langfuse);
$langfuse->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $langfuse_url = 'http://127.0.0.1:' . $langfuse->read_handle->sockport;

sub config {
  my (%langfuse) = @_;
  return Langertha::Knarr::Config->new( data => {
    models   => {},
    langfuse => { public_key => 'pk-lf-test', secret_key => 'sk-lf-test',
                  url => $langfuse_url, trace_name => 'knarr-test', %langfuse },
  } );
}

sub tracing { Langertha::Knarr::Tracing->new( config => config( transport => 'otel', @_ ) ) }

sub next_post {
  my $deadline = time + 5;
  $loop->loop_once(0.05) until @posts || time > $deadline;
  return shift @posts;
}

# The two spans of the next OTLP export, as ( root, generation ), with
# their attributes flattened into a hash for reading.
sub next_spans {
  my $post = next_post() or return fail('Langfuse received nothing');
  is $post->{path}, '/api/public/otel/v1/traces', 'posted to the OTLP traces endpoint';
  my $rs = $post->{body}{resourceSpans};
  is scalar @$rs, 1, 'one resourceSpans entry';
  my $spans = $rs->[0]{scopeSpans}[0]{spans};
  is scalar @$spans, 2, 'root span and generation span' or return;
  my ($root) = grep { !exists $_->{parentSpanId} } @$spans;
  my ($gen)  = grep {  exists $_->{parentSpanId} } @$spans;
  ok $root && $gen, 'one root, one child' or return;
  $_->{attr} = attr_hash( $_->{attributes} ) for $root, $gen;
  return ( $root, $gen, $post );
}

sub attr_hash {
  my ($attrs) = @_;
  my %h;
  for my $a (@$attrs) {
    my $v = $a->{value};
    $h{ $a->{key} } = exists $v->{arrayValue}
      ? [ map { $_->{stringValue} } @{ $v->{arrayValue}{values} } ]
      : $v->{stringValue};
  }
  return \%h;
}

my $messages = [ { role => 'user', content => 'grüß dich' } ];

subtest 'transport resolution' => sub {
  is config()->langfuse_transport, 'ingestion', 'default is ingestion';
  is config( transport => 'otel' )->langfuse_transport, 'otel', 'langfuse.transport: otel';
  {
    local $ENV{KNARR_LANGFUSE_TRANSPORT} = '"OTel"';
    is config()->langfuse_transport, 'otel', 'KNARR_LANGFUSE_TRANSPORT, quotes and case ignored';
    is config( transport => 'ingestion' )->langfuse_transport, 'ingestion', 'config beats the env var';
  }
  my $bad = config( transport => 'grpc' );
  like dies { $bad->langfuse_transport }, qr/langfuse\.transport 'grpc' must be ingestion or otel/,
    'an unknown transport croaks';
  ok( ( grep { /langfuse\.transport 'grpc'/ } $bad->validate ), 'validate reports it' );
  like dies { Langertha::Knarr::Tracing->new( config => config( transport => 'grpc' ) ) },
    qr/must be ingestion or otel/, 'an enabled tracer refuses it when built';
  ok lives { Langertha::Knarr::Tracing->new( config => Langertha::Knarr::Config->new(
    data => { models => {}, langfuse => { transport => 'grpc' } } ) ) },
    'a disabled tracer does not care';
};

# A cold Langfuse under load took ~6 s to answer, past the old fixed 5 s,
# and Knarr logged a timeout for a trace Langfuse stored after all.
subtest 'flush timeout resolution' => sub {
  delete local $ENV{KNARR_LANGFUSE_TIMEOUT};
  is config()->langfuse_timeout, 15, 'default 15 seconds';
  is config( timeout => 30 )->langfuse_timeout, 30, 'langfuse.timeout';
  is config( timeout => 0 )->langfuse_timeout, 0, '0 is allowed (no limit)';
  {
    local $ENV{KNARR_LANGFUSE_TIMEOUT} = '"2.5"';
    is config()->langfuse_timeout, 2.5, 'KNARR_LANGFUSE_TIMEOUT, quotes stripped';
    is config( timeout => 7 )->langfuse_timeout, 7, 'config beats the env var';
  }
  my $bad = config( timeout => 'soon' );
  like dies { $bad->langfuse_timeout }, qr/langfuse\.timeout 'soon' must be a number of seconds/,
    'a non-number croaks';
  ok( ( grep { /langfuse\.timeout 'soon'/ } $bad->validate ), 'validate reports it' );
  like dies { Langertha::Knarr::Tracing->new( config => config( timeout => 'soon' ) ) },
    qr/must be a number of seconds/, 'an enabled tracer refuses it when built';

  # The HTTP client is what enforces it (t/86_tracing_timeout.t runs one
  # into a hanging Langfuse); Net::Async::HTTP keeps it in {timeout}.
  my $client_timeout = sub {
    Langertha::Knarr::Tracing->new( config => config(@_) )->_http->{timeout};
  };
  is( $client_timeout->(), 15, 'the flush client gets the default' );
  is( $client_timeout->( timeout => 30 ), 30, 'and a configured value' );
  ok( !defined $client_timeout->( timeout => 0 ),
    '0 sets none (Net::Async::HTTP would time out at once on 0)' );
};

subtest 'routed chat: trace and generation as OTLP spans' => sub {
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub {
      Langertha::Response->new( content => 'hi', model => 'gpt-test-0613',
        usage => { prompt_tokens => 42, completion_tokens => 17 } );
    } ),
    tracing => tracing(),
  );
  my $r = $handler->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'openai', model => 'gpt-test',
      messages => $messages ) )->get;
  is $r->content, 'hi', 'response passed through the decorator';

  my ( $root, $gen, $post ) = next_spans() or return;
  is $post->{auth}, 'Basic ' . encode_base64( 'pk-lf-test:sk-lf-test', '' ), 'Basic auth public:secret';
  is $post->{type}, 'application/json', 'OTLP JSON encoding';
  is $post->{version}, '4', 'x-langfuse-ingestion-version: 4';
  is $post->{body}{resourceSpans}[0]{scopeSpans}[0]{scope}{name}, 'Langertha::Knarr::Tracing', 'scope name';

  like $root->{traceId}, qr/\A[0-9a-f]{32}\z/, 'trace id: 16 bytes hex';
  is $gen->{traceId}, $root->{traceId}, 'both spans in one trace';
  like $_->{spanId}, qr/\A[0-9a-f]{16}\z/, 'span id: 8 bytes hex' for $root, $gen;
  isnt $gen->{spanId}, $root->{spanId}, 'distinct span ids';
  is $gen->{parentSpanId}, $root->{spanId}, 'generation is the root span\'s child';
  is $root->{kind}, 2, 'root span kind SERVER';
  is $gen->{kind}, 3, 'generation span kind CLIENT';
  is $root->{name}, 'knarr-test', 'root span named after the trace name';
  is $gen->{name}, 'proxy-request', 'generation span name';
  for my $span ( $root, $gen ) {
    like $span->{$_}, qr/\A[1-9][0-9]{18}\z/, "$_ in Unix nanoseconds, as a string"
      for qw( startTimeUnixNano endTimeUnixNano );
    ok $span->{endTimeUnixNano} >= $span->{startTimeUnixNano}, 'ends after it starts';
    ok !exists $span->{status}, 'no error status';
  }

  is $root->{attr}, {
    'langfuse.trace.name'            => 'knarr-test',
    'langfuse.trace.tags'            => ['knarr'],
    'langfuse.observation.type'      => 'span',
    'langfuse.observation.input'     => D(),
    'langfuse.observation.output'    => 'hi',
    'langfuse.trace.metadata.format' => 'openai',
    'langfuse.trace.metadata.model'  => 'gpt-test',
    'langfuse.trace.metadata.engine' => 'Langertha::Knarr::Handler::Code',
    'langfuse.trace.metadata.params' => D(),
  }, 'root span carries the trace attributes';
  is $json->decode( encode_utf8( $root->{attr}{'langfuse.observation.input'} ) ),
    $messages, 'trace input: the messages, JSON, non-ASCII intact';
  is $json->decode( $root->{attr}{'langfuse.trace.metadata.params'} ),
    { temperature => undef, max_tokens => undef, tools => undef }, 'params JSON-encoded';

  is $gen->{attr}, {
    'langfuse.trace.name'                  => 'knarr-test',
    'langfuse.trace.tags'                  => ['knarr'],
    'langfuse.observation.type'            => 'generation',
    'langfuse.observation.model.name'      => 'gpt-test-0613',
    'langfuse.observation.input'           => $root->{attr}{'langfuse.observation.input'},
    'langfuse.observation.output'          => 'hi',
    'langfuse.observation.usage_details'   => '{"input":42,"output":17,"total":59}',
  }, 'generation span: model, io, usage in Langfuse keys';
};

subtest 'engine timing drives the generation span times' => sub {
  my $tracing = tracing();
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai', messages => $messages );
  $tracing->end_trace( $trace, output => 'hi',
    timing => { ttft_seconds => 0.25, total_seconds => 1.5 },
    response_id => 'chatcmpl-123',
    tool_calls  => [ { id => 'c1', name => 'lookup', arguments => { q => 'x' } } ],
    rate_limit  => { requests_remaining => 9 },
    thinking    => 'hmm' );
  my ( $root, $gen ) = next_spans() or return;
  is $gen->{endTimeUnixNano} - $gen->{startTimeUnixNano}, 1_500_000_000,
    'generation lasts total_seconds from the start';
  is $gen->{startTimeUnixNano}, $root->{startTimeUnixNano}, 'both start when start_trace ran';
  like $gen->{attr}{'langfuse.observation.completion_start_time'},
    qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z\z/, 'completion start as ISO 8601';
  my $meta = 'langfuse.observation.metadata.';
  is $json->decode( $gen->{attr}{"${meta}timing"} ), { ttft_seconds => 0.25, total_seconds => 1.5 },
    'timing recorded verbatim';
  is $gen->{attr}{"${meta}response_id"}, 'chatcmpl-123', 'response id';
  is $gen->{attr}{"${meta}thinking"}, 'hmm', 'thinking';
  is $json->decode( $gen->{attr}{"${meta}rate_limit"} ), { requests_remaining => 9 }, 'rate limit';
  is $json->decode( $gen->{attr}{"${meta}tool_calls"} ),
    [ { id => 'c1', name => 'lookup', arguments => { q => 'x' } } ], 'full tool calls';
};

# k70: the generation's model is the one the backend reported, the name the
# client was answered under goes into the metadata; k66: a raw passthrough
# answered through the chain after a 401 records that status on the trace.
subtest 'reported model, configured name and passthrough fallback' => sub {
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub {
      Langertha::Knarr::Response->new( content => 'hi', model => 'my-alias',
        upstream_model => 'gpt-4o-2024-08-06' );
    } ),
    tracing => tracing(),
  );
  $handler->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'openai', model => 'my-alias',
      messages => $messages, extra => { passthrough_fallback => 401 } ) )->get;
  my ( $root, $gen ) = next_spans() or return;
  is $gen->{attr}{'langfuse.observation.model.name'}, 'gpt-4o-2024-08-06', 'the model that answered';
  is $gen->{attr}{'langfuse.observation.metadata.configured_model'}, 'my-alias',
    'the configured name in the generation metadata';
  is $root->{attr}{'langfuse.trace.metadata.passthrough_fallback'}, '401',
    'the refusing status in the trace metadata';
};

# k66: a trace opened late starts at the given instant, not at "now".
subtest 'start_hires sets the span start' => sub {
  my $tracing = tracing();
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai',
    start_hires => [ 1_700_000_000, 250_000 ] );
  $tracing->end_trace( $trace, output => 'hi', timing => { total_seconds => 2 } );
  my ( $root, $gen ) = next_spans() or return;
  is $_->{startTimeUnixNano}, '1700000000250000000', "$_->{name} starts at start_hires"
    for $root, $gen;
  is $gen->{endTimeUnixNano}, '1700000002250000000', 'the generation ends total_seconds later';
};

# k69: a routed stream carries the backend's usage and reported model to
# the trace.
{
  package UsageStream::Handler;
  use Moose;
  extends 'Langertha::Knarr::Handler::Code';
  sub handle_stream_f {
    my @parts = ( 'Hel', 'lo' );
    return Future->done( Langertha::Knarr::Stream->new(
      generator      => sub { @parts ? shift @parts : undef },
      model          => 'my-alias',
      upstream_model => 'gpt-4o-2024-08-06',
      usage          => { prompt_tokens => 5, completion_tokens => 6 },
    ) );
  }
  __PACKAGE__->meta->make_immutable;
}

subtest 'routed stream: usage and reported model' => sub {
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => UsageStream::Handler->new( code => sub { 'unused' } ),
    tracing => tracing(),
  );
  my $stream = $handler->handle_stream_f( Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'openai', model => 'my-alias',
      stream => 1, messages => $messages ) )->get;
  my $text = '';
  while ( defined( my $chunk = $stream->next_chunk_f->get ) ) { $text .= $chunk }
  is $text, 'Hello', 'the stream passed through';
  my ( $root, $gen ) = next_spans() or return;
  is $gen->{attr}{'langfuse.observation.output'}, 'Hello', 'accumulated output';
  is $json->decode( $gen->{attr}{'langfuse.observation.usage_details'} ),
    { input => 5, output => 6, total => 11 }, 'the stream\'s usage in Langfuse keys';
  is $gen->{attr}{'langfuse.observation.model.name'}, 'gpt-4o-2024-08-06', 'the model that answered';
  is $gen->{attr}{'langfuse.observation.metadata.configured_model'}, 'my-alias', 'the configured name';
};

subtest 'a provider usage hash maps like the ingestion path' => sub {
  my $tracing = tracing();
  my $trace = $tracing->start_trace( model => 'claude-test', format => 'anthropic' );
  $tracing->end_trace( $trace, output => '[passthrough]', usage => { input_tokens => 3, output_tokens => 4 } );
  my ( $root, $gen ) = next_spans() or return;
  is $json->decode( $gen->{attr}{'langfuse.observation.usage_details'} ),
    { input => 3, output => 4, total => 7 }, 'Anthropic counts in Langfuse keys';
  ok !exists $gen->{attr}{'langfuse.observation.input'}, 'no messages, no input attribute';
};

# k65: usage_details are exclusive buckets, total their sum; Anthropic
# counts its cache beside input_tokens, OpenAI's cached_tokens inside
# prompt_tokens.
subtest 'cache counts in their own usage_details buckets' => sub {
  my $tracing = tracing();
  for my $case (
    [ Anthropic => { input_tokens => 12, cache_read_input_tokens => 50000,
                     cache_creation_input_tokens => 2000, output_tokens => 300 },
      { input => 12, input_cached_tokens => 50000, input_cache_creation => 2000,
        output => 300, total => 52312 } ],
    [ OpenAI => { prompt_tokens => 50012, completion_tokens => 300, total_tokens => 50312,
                  prompt_tokens_details => { cached_tokens => 50000 } },
      { input => 12, input_cached_tokens => 50000, output => 300, total => 50312 } ],
  ) {
    my ( $name, $usage, $expect ) = @$case;
    my $trace = $tracing->start_trace( model => 'm', format => lc $name );
    $tracing->end_trace( $trace, output => '[passthrough]', usage => $usage );
    my ( $root, $gen ) = next_spans() or return;
    is $json->decode( $gen->{attr}{'langfuse.observation.usage_details'} ), $expect,
      "$name: uncached input, cache read and write apart";
  }
};

{
  package CachedUsageStream::Handler;
  use Moose;
  extends 'Langertha::Knarr::Handler::Code';
  sub handle_stream_f {
    my @parts = ( 'Hel', 'lo' );
    return Future->done( Langertha::Knarr::Stream->new(
      generator => sub { @parts ? shift @parts : undef },
      usage     => { input_tokens => 12, cache_read_input_tokens => 50000,
                     cache_creation_input_tokens => 2000, output_tokens => 300 },
    ) );
  }
  __PACKAGE__->meta->make_immutable;
}

subtest 'routed stream: cache counts in their own buckets' => sub {
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => CachedUsageStream::Handler->new( code => sub { 'unused' } ),
    tracing => tracing(),
  );
  my $stream = $handler->handle_stream_f( Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'claude-test',
      stream => 1, messages => $messages ) )->get;
  1 while defined $stream->next_chunk_f->get;
  my ( $root, $gen ) = next_spans() or return;
  is $json->decode( $gen->{attr}{'langfuse.observation.usage_details'} ),
    { input => 12, input_cached_tokens => 50000, input_cache_creation => 2000,
      output => 300, total => 52312 }, 'the stream\'s usage, cache apart';
};

subtest 'no usage: no usage attribute, not a 0/0/0' => sub {
  my $tracing = tracing();
  for my $usage ( undef, {}, { error => 'overloaded' } ) {
    my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai' );
    $tracing->end_trace( $trace, output => 'hi', defined $usage ? ( usage => $usage ) : () );
    my ( $root, $gen ) = next_spans() or return;
    ok !exists $gen->{attr}{'langfuse.observation.usage_details'}, 'no usage_details';
  }
};

subtest 'error: ERROR status on the generation and the trace' => sub {
  my $tracing = tracing();
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai', messages => $messages );
  $tracing->end_trace( $trace, error => 'upstream exploded' );
  my ( $root, $gen ) = next_spans() or return;
  for my $case ( [ generation => $gen ], [ root => $root ] ) {
    my ( $name, $span ) = @$case;
    is $span->{status}, { code => 2, message => 'upstream exploded' },
      "$name: span status ERROR with the message";
    is $span->{attr}{'langfuse.observation.level'}, 'ERROR', "$name: level ERROR";
    is $span->{attr}{'langfuse.observation.status_message'}, 'upstream exploded',
      "$name: status message";
  }
  ok !exists $gen->{attr}{'langfuse.observation.output'}, 'no generation output';
  ok !exists $gen->{attr}{'langfuse.observation.usage_details'}, 'no usage';
  is $root->{attr}{'langfuse.observation.output'}, 'upstream exploded', 'the trace output is the error';
  is $root->{attr}{'langfuse.observation.type'}, 'span', 'the root stays a span';
};

subtest 'an unencodable trace is dropped, not thrown' => sub {
  my $tracing = tracing();
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai',
    params => { poison => bless( {}, 'Test::Unencodable' ) } );
  ok lives { $tracing->end_trace( $trace, output => 'hi' ) }, 'end_trace survives it' or note $@;
  my $t2 = $tracing->start_trace( model => 'gpt-test', format => 'openai' );
  $tracing->end_trace( $t2, output => 'later' );
  my ( $root, $gen ) = next_spans() or return;
  is $gen->{attr}{'langfuse.observation.output'}, 'later', 'only the following trace shipped';
  $loop->loop_once(0.1);
  is scalar @posts, 0, 'nothing else was posted';
};

# The raw passthrough reads usage and the answering model off a copy of the
# upstream's bytes (k61) and hands them to end_trace; the OTel transport
# must carry them like the ingestion one.
subtest 'raw passthrough traces through the OTel transport too' => sub {
  my $backend = Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Code->new( code => sub {
      Langertha::Response->new( content => 'UPSTREAM', model => 'gpt-mystery-0613',
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

  my ( $root, $gen ) = next_spans() or return;
  is $gen->{attr}{'langfuse.observation.output'}, '[passthrough]', 'the passthrough generation';
  is $root->{attr}{'langfuse.trace.metadata.engine'}, 'passthrough', 'marked as passthrough';
  is $gen->{attr}{'langfuse.observation.model.name'}, 'gpt-mystery-0613', 'the model that answered';
  is $root->{attr}{'langfuse.trace.metadata.model'}, 'gpt-mystery', 'the model the client asked for';
  is $json->decode( $gen->{attr}{'langfuse.observation.usage_details'} ),
    { input => 3, output => 4, total => 7 }, 'the upstream\'s usage in Langfuse keys';
};

subtest 'default transport is still the ingestion batch' => sub {
  my $tracing = Langertha::Knarr::Tracing->new( config => config() );
  is $tracing->transport, 'ingestion', 'ingestion by default';
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai', messages => $messages );
  $tracing->end_trace( $trace, output => 'hi', usage => { input => 1, output => 2 } );
  my $post = next_post() or return fail('Langfuse received nothing');
  is $post->{path}, '/api/public/ingestion', 'posted to the ingestion API';
  ok !defined $post->{version}, 'no OTel ingestion-version header';
  is [ map { $_->{type} } @{ $post->{body}{batch} } ],
    [qw( trace-create generation-create generation-update trace-create )], 'the usual four events';
  is $post->{body}{batch}[2]{body}{usageDetails}, { input => 1, output => 2, total => 3 },
    'usage in Langfuse keys';
};

done_testing;
