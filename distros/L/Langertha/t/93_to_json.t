use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

use Langertha::Usage;
use Langertha::Cost;
use Langertha::UsageRecord;
use Langertha::RateLimit;
use Langertha::Tool;
use Langertha::ToolCall;
use Langertha::ToolChoice;
use Langertha::Response;

# convert_blessed => 1 is the encoder configuration this whole file is about:
# the common consumer setup, and the one Langertha::Plugin::Langfuse uses.
# Every assertion goes through a real encode + decode round trip — a
# can('TO_JSON') check would pass just as happily on a method returning junk.
my $json = JSON::MaybeXS->new( canonical => 1, convert_blessed => 1 );

# Always nest: the failure this fixes is an object buried in a structure the
# caller assembled, not an object handed to the encoder on purpose.
sub roundtrip { return $json->decode( $json->encode( $_[0] ) ) }

# --- Langertha::Usage ---
{
  my $u = Langertha::Usage->new( input_tokens => 100, output_tokens => 50 );
  my $got = roundtrip( { usage => $u } );
  is( $got->{usage},
    { input_tokens => 100, output_tokens => 50, total_tokens => 150 },
    'Usage round-trips as its canonical hash (lazy total_tokens included)' );
}

# --- Langertha::RateLimit: raw stays out of the implicit path ---
{
  my $rl = Langertha::RateLimit->new(
    requests_limit     => 100,
    requests_remaining => 99,
    tokens_limit       => 40000,
    tokens_remaining   => 39500,
    raw                => {
      'x-ratelimit-limit-requests'     => '100',
      'x-ratelimit-remaining-requests' => '99',
    },
  );

  my $got = roundtrip( { rate_limit => $rl } );
  is( $got->{rate_limit},
    {
      requests_limit     => 100,
      requests_remaining => 99,
      tokens_limit       => 40000,
      tokens_remaining   => 39500,
    },
    'RateLimit round-trips its normalized fields' );

  ok( !exists $got->{rate_limit}{raw},
    'RateLimit TO_JSON keeps the provider raw headers out of foreign logs/traces' );

  # The explicit path is unchanged: a caller who asks for raw still gets it.
  ok( exists $rl->to_hash->{raw}, 'to_hash still carries raw (contract unchanged)' );
  is( $rl->to_hash->{raw}{'x-ratelimit-limit-requests'}, '100',
    'to_hash raw content intact' );
}

# --- Langertha::ToolCall ---
{
  my $tc = Langertha::ToolCall->new(
    name      => 'search_files',
    arguments => { pattern => '*.pm', depth => 2 },
    id        => 'call_abc',
  );
  my $got = roundtrip( { tool_call => $tc } );
  is( $got->{tool_call},
    {
      id        => 'call_abc',
      name      => 'search_files',
      arguments => { pattern => '*.pm', depth => 2 },
      synthetic => 0,
    },
    'ToolCall round-trips with nested arguments' );

  my $synth = roundtrip( {
    tool_call => Langertha::ToolCall->new(
      name      => 'extract',
      arguments => { summary => 'hi' },
      synthetic => 1,
    ),
  } );
  is( $synth->{tool_call}{synthetic}, 1,
    'synthetic flag survives the round trip' );
}

# --- Langertha::Tool ---
{
  my $t = Langertha::Tool->new(
    name         => 'list_files',
    description  => 'List files',
    input_schema => { type => 'object', properties => { path => { type => 'string' } } },
  );
  my $got = roundtrip( { tool => $t } );
  is( $got->{tool},
    {
      name         => 'list_files',
      description  => 'List files',
      input_schema => { type => 'object', properties => { path => { type => 'string' } } },
    },
    'Tool round-trips as its canonical hash' );
}

# --- Langertha::Cost ---
{
  my $c = Langertha::Cost->new( input_usd => 0.001, output_usd => 0.002 );
  my $got = roundtrip( { cost => $c } );
  is( $got->{cost},
    {
      input_cost_usd       => 0.001,
      output_cost_usd      => 0.002,
      cache_read_cost_usd  => 0,
      cache_write_cost_usd => 0,
      total_cost_usd       => 0.003,
      currency             => 'USD',
    },
    'Cost round-trips as its canonical hash (lazy total included)' );
}

# --- Langertha::UsageRecord ---
{
  my $rec = Langertha::UsageRecord->new(
    usage      => Langertha::Usage->new( input_tokens => 100, output_tokens => 50 ),
    cost       => Langertha::Cost->new( input_usd => 0.001, output_usd => 0.002 ),
    model      => 'gpt-4o-mini',
    provider   => 'openai',
    api_key_id => 'tenant-1',
    tool_calls => 2,
    tool_names => [ 'list_files', 'read_file' ],
  );
  my $got = roundtrip( { record => $rec } );
  is( $got->{record}{model}, 'gpt-4o-mini', 'UsageRecord model' );
  is( $got->{record}{input_tokens}, 100, 'UsageRecord tokens flattened' );
  is( $got->{record}{total_cost_usd} + 0, 0.003, 'UsageRecord cost flattened' );
  is( $got->{record}{tool_names}[1], 'read_file', 'UsageRecord tool names' );
  is( $got->{record}{api_key_id}, 'tenant-1', 'UsageRecord api_key_id' );
}

# --- Langertha::ToolChoice ---
{
  my $named = roundtrip( { tool_choice => Langertha::ToolChoice->specific('extract') } );
  is( $named->{tool_choice}, { type => 'tool', name => 'extract' },
    'ToolChoice round-trips a named tool' );

  my $auto = roundtrip( { tool_choice => Langertha::ToolChoice->auto } );
  is( $auto->{tool_choice}, { type => 'auto' },
    'ToolChoice omits the undef name' );
}

# --- The scenario the change exists for ---
# A consumer writes response metadata to a trace or a JSONL log. tool_calls
# and rate_limit are objects on the declared contract, so they reach the
# encoder without ever announcing themselves as objects; usage joins them once
# it is coerced to a Langertha::Usage. Before TO_JSON this killed the encode
# deep in the call stack, far from where the objects were created.
{
  my $response = Langertha::Response->new(
    content    => 'hello',
    model      => 'claude-sonnet-4-6',
    tool_calls => [ { name => 'ping', arguments => { host => 'example.com' }, id => 'toolu_1' } ],
    rate_limit => Langertha::RateLimit->new(
      requests_remaining => 42,
      raw                => { 'x-ratelimit-remaining-requests' => '42' },
    ),
  );

  my $got = roundtrip( {
    model      => $response->model,
    tool_calls => $response->tool_calls,
    rate_limit => $response->rate_limit,
    usage      => Langertha::Usage->from_response($response),
  } );

  is( $got->{tool_calls}[0]{name}, 'ping',
    'Response->tool_calls encodes through ToolCall TO_JSON' );
  is( $got->{tool_calls}[0]{arguments}{host}, 'example.com',
    'tool call arguments survive the trace payload' );
  is( $got->{rate_limit}{requests_remaining}, 42,
    'Response->rate_limit encodes through RateLimit TO_JSON' );
  ok( !exists $got->{rate_limit}{raw},
    'no provider headers leak into the trace payload' );
  is( $got->{usage}{total_tokens}, 0,
    'Usage encodes through TO_JSON' );
}

# --- Langertha::Response TO_JSON: canonical, bounded shape (karr #50) ---
# A bare Response now encodes identically on every JSON::MaybeXS backend when
# convert_blessed is on. The shape is content + present metadata; raw and
# probes are deliberately excluded (raw duplicates everything, probes can hold
# megabytes of tensor data). See "TO_JSON — the canonical, bounded
# representation" in Langertha::Response.
{
  my $response = Langertha::Response->new(
    content       => 'hello',
    model         => 'claude-sonnet-4-6',
    id            => 'msg_1',
    finish_reason => 'end_turn',
    created       => 1700000000,
    thinking      => 'let me think',
    usage         => { input_tokens => 100, output_tokens => 50 },
    tool_calls    => [ { name => 'ping', arguments => { host => 'example.com' }, id => 'toolu_1' } ],
    rate_limit    => Langertha::RateLimit->new(
      requests_remaining => 42,
      raw                => { 'x-ratelimit-remaining-requests' => '42' },
    ),
    timing => { total_seconds => 1.5 },
    raw    => { the => 'whole provider payload' },
    probes => { qk_cache => [ [1, 2], [3, 4] ] },
  );

  my $got = roundtrip( { response => $response } );
  is( $got->{response}{content}, 'hello', 'TO_JSON carries content' );
  is( $got->{response}{model}, 'claude-sonnet-4-6', 'TO_JSON carries model' );
  is( $got->{response}{id}, 'msg_1', 'TO_JSON carries id' );
  is( $got->{response}{finish_reason}, 'end_turn', 'TO_JSON carries finish_reason' );
  is( $got->{response}{created}, 1700000000, 'TO_JSON carries created' );
  is( $got->{response}{thinking}, 'let me think', 'TO_JSON carries thinking' );
  is( $got->{response}{usage}{total_tokens}, 150, 'TO_JSON carries usage via Usage TO_JSON' );
  is( $got->{response}{tool_calls}[0]{name}, 'ping', 'TO_JSON carries tool_calls via ToolCall TO_JSON' );
  is( $got->{response}{rate_limit}{requests_remaining}, 42, 'TO_JSON carries rate_limit via RateLimit TO_JSON' );
  ok( !exists $got->{response}{rate_limit}{raw}, 'no provider headers leak into the trace payload' );
  is( $got->{response}{timing}{total_seconds}, 1.5, 'TO_JSON carries timing' );
  ok( !exists $got->{response}{raw}, 'raw stays out of TO_JSON' );
  ok( !exists $got->{response}{probes}, 'probes stay out of TO_JSON' );

  # to_hash is the same canonical shape, directly.
  my $h = $response->to_hash;
  is( $h->{content}, 'hello', 'to_hash content' );
  is( $h->{model}, 'claude-sonnet-4-6', 'to_hash model' );
  ok( !exists $h->{raw}, 'to_hash excludes raw' );
  ok( !exists $h->{probes}, 'to_hash excludes probes' );
}

# --- Backend uniformity: every JSON::MaybeXS backend encodes identically ---
# The defect karr #50 fixes: Cpanel::JSON::XS used to fall back to the ""
# overload (emitting the content string), JSON::XS and JSON::PP threw. Now all
# three emit the same canonical hash.
#
# JSON::MaybeXS picks whichever backend is installed, so this has to cover all
# of them — but JSON::XS is optional (JSON::MaybeXS prefers Cpanel::JSON::XS),
# and neither a backend nobody installed nor a regressed one may abort the file
# before done_testing. Missing backends are skipped and an encode that throws
# is reported as a failed assertion. The comparison must never quietly shrink
# to nothing either, so the backends really compared are named in every
# assertion, the skipped ones are reported, and having fewer than two left to
# compare is itself a failure rather than a silent pass.
{
  my $response = Langertha::Response->new(
    content => 'hello',
    model   => 'gpt-4o',
    usage   => { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15 },
  );

  my ( @available, @missing, %encoded );
  for my $mod (qw(Cpanel::JSON::XS JSON::XS JSON::PP)) {
    ( my $file = $mod ) =~ s{::}{/}g;
    unless ( eval { require "$file.pm"; 1 } ) {
      push @missing, $mod;
      next;
    }
    push @available, $mod;
    my $enc = $mod->new->convert_blessed(1)->canonical(1);
    $encoded{$mod} = eval { $enc->encode( { response => $response } ) };
    ok( defined $encoded{$mod}, "$mod encodes a Response without throwing" )
      or diag($@);
  }
  note( 'JSON backends compared: ' . join( ', ', @available ) );
  note( 'JSON backends not installed, skipped: ' . join( ', ', @missing ) ) if @missing;

  ok( @available >= 2,
    'at least two JSON backends to compare (' . join( ', ', @available ) . ')' );

  # Identity is transitive, so comparing every backend against the first covers
  # all pairs while still naming which two backends each assertion checked.
  my ( $reference, @rest ) = @available;
  for my $mod (@rest) {
    is( $encoded{$mod}, $encoded{$reference}, "$reference and $mod encode identically" );
  }
  if ( defined $reference && defined $encoded{$reference} ) {
    # The whole decoded hash, not a ->{content} lookup: the karr #50 symptom
    # was the "" overload emitting the bare content string, and a lookup into
    # that string would die instead of failing an assertion.
    is( $json->decode( $encoded{$reference} )->{response},
      {
        content => 'hello',
        model   => 'gpt-4o',
        usage   => { input_tokens => 10, output_tokens => 5, total_tokens => 15 },
      },
      "uniform shape is the canonical hash ($reference)" );
  }
}

# --- Stringification still works alongside TO_JSON ---
{
  my $response = Langertha::Response->new( content => 'hello' );
  is( "$response", 'hello', 'string overload still returns content' );
}

# --- The engine's own encoder ($engine->json) honors convert_blessed too, so
#     the "house default" the value objects' POD names is true on the encoder
#     every engine builds — not only on Plugin::Langfuse (karr #120). ---
{
  require Langertha::Engine::OpenAI;
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'test', model => 'gpt-4o' );
  my $u = Langertha::Usage->new( input_tokens => 3, output_tokens => 4 );
  my $back = $engine->json->decode( $engine->json->encode( { usage => $u } ) );
  is( $back->{usage},
    { input_tokens => 3, output_tokens => 4, total_tokens => 7 },
    'engine->json encodes a blessed value object via TO_JSON (karr k120)' );
}

# --- Langertha::Content::Image (karr k273): a message array holding images
#     must encode for logs/traces (knarr k33 choked on it), and the implicit
#     path must never carry the base64 payload — one photo would be megabytes
#     in every trace line. ---
{
  require Langertha::Content::Image;
  my $bytes = 'x' x 1000;
  my $inline = Langertha::Content::Image->from_data( $bytes,
    media_type => 'image/png', detail => 'low' );
  my $remote = Langertha::Content::Image->from_url('https://img.test/cat.jpg');
  my $data_url = Langertha::Content::Image->new(
    url => 'data:image/gif;base64,R0lGODlh', media_type => 'image/gif' );

  my $got = roundtrip( [ { role => 'user', content => [ 'what?', $inline, $remote, $data_url ] } ] );
  is( $got->[0]{content}, [
      'what?',
      { type => 'image', source => 'base64', media_type => 'image/png',
        detail => 'low', bytes => 1000 },
      { type => 'image', source => 'url', url => 'https://img.test/cat.jpg',
        media_type => 'image/jpeg' },
      { type => 'image', source => 'base64', media_type => 'image/gif' },
    ],
    'Content::Image TO_JSON: compact shape, decoded byte count, no payload' );

  my $encoded = $json->encode( { img => $inline } );
  unlike( $encoded, qr/\Q${\ $inline->base64 }\E/, 'the base64 payload is not in the JSON' );
  unlike( $encoded, qr/R0lGODlh/, '... nor a data: URL passed as url' );

  require Langertha::Engine::OpenAI;
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'test', model => 'gpt-4o' );
  my $back = $engine->json->decode( $engine->json->encode( { messages => [
    { role => 'user', content => [ $remote ] } ] } ) );
  is( $back->{messages}[0]{content}[0]{source}, 'url',
    'engine->json (Role::JSON, convert_blessed) encodes a message array with an image' );
}

done_testing;
