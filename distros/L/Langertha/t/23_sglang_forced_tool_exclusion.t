#!/usr/bin/env perl
# ABSTRACT: SGLang refuses a forced tool_choice together with a response_format (karr k245)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Engine::SGLang;

# Why (karr k245, ADR 0024): SGLang's OpenAI server raises "tool_choice
# 'required' or a named tool cannot be combined with response_format, regex, or
# ebnf" (python/sglang/srt/entrypoints/openai/protocol.py, since 307a90f6d3 /
# 17ba2c2e7c) whenever tools carry a tool-call constraint, a response_format
# sets an output constraint (json_schema, json_object -> json_schema
# '{"type":"object"}', structural_tag; not text) and tool_choice is required or
# a named tool. tool_choice auto + response_format is accepted. Engine::SGLang
# claims tool_choice_any/named and response_format_json_schema, so chat_f does
# no ADR 0005 rewrite and the caller got an opaque 400. The exclusion seam now
# passes tool_choice_forced so the rule refuses exactly the forced case and
# leaves tools + auto + response_format alone. All mocked, no live calls.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $SCHEMA = {
  type       => 'object',
  properties => { city => { type => 'string' } },
  required   => ['city'],
};
my $TOOL = {
  type     => 'function',
  function => { name => 'get_weather', description => 'Weather', parameters => $SCHEMA },
};
my $JSON_SCHEMA_RF = { type => 'json_schema', json_schema => { name => 'x', schema => $SCHEMA } };
my $JSON_OBJECT_RF = { type => 'json_object' };

sub mock {
  return Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      model   => 'default',
      choices => [{ message => { role => 'assistant', content => '{"city":"Berlin"}' } }],
    }),
  ]);
}

sub engine {
  my ($mock) = @_;
  return Langertha::Engine::SGLang->new(
    url => 'http://localhost:30000/v1',
    ( $mock ? ( _async_http => $mock ) : () ),
  );
}

sub run {
  my ($code) = @_;
  my $ok = eval { $code->()->get; 1 };
  return ( $ok, $@ );
}

my @forced = (
  [ 'required string'       => 'required' ],
  [ 'named tool (OpenAI)'   => { type => 'function', function => { name => 'get_weather' } } ],
  [ 'named tool (canonical)'=> { type => 'tool', name => 'get_weather' } ],
  [ 'any (canonical)'       => { type => 'any' } ],
);

for my $case (@forced) {
  my ( $label, $tc ) = @$case;
  for my $rf ( [ json_schema => $JSON_SCHEMA_RF ], [ json_object => $JSON_OBJECT_RF ] ) {
    my $mock = mock();
    my ( $ok, $err ) = run( sub { engine($mock)->chat_f(
      messages        => [ { role => 'user', content => 'hi' } ],
      tools           => [$TOOL],
      tool_choice     => $tc,
      response_format => $rf->[1],
    ) } );
    ok( !$ok, "SGLang: forced tool_choice ($label) + $rf->[0] croaks" );
    like( $err, qr/SGLang/, "  croak names the engine ($label, $rf->[0])" );
    like( $err, qr/tool_choice/, "  croak names tool_choice ($label, $rf->[0])" );
    like( $err, qr/response_format/, "  croak names response_format ($label, $rf->[0])" );
    is( $mock->request_count, 0, "  nothing reached the wire ($label, $rf->[0])" );
  }
}

# The streaming path consults the same seam.
{
  my ( $ok, $err ) = run( sub { engine(mock())->chat_stream_realtime_f(
    messages        => [ { role => 'user', content => 'hi' } ],
    tools           => [$TOOL],
    tool_choice     => 'required',
    response_format => $JSON_SCHEMA_RF,
  ) } );
  ok( !$ok, 'SGLang streaming: forced tool_choice + response_format croaks' );
  like( $err, qr/tool_choice.*response_format|response_format.*tool_choice/s,
    'SGLang streaming croak is the exclusion, not a transport failure' );
}

# Accepted by SGLang: must reach the wire unchanged.
my @allowed = (
  [ 'tools + auto + json_schema' => {
      tools => [$TOOL], tool_choice => 'auto', response_format => $JSON_SCHEMA_RF },
    { tool_choice => 'auto', response_format => 'json_schema' } ],
  [ 'tools + no tool_choice + json_schema' => {
      tools => [$TOOL], response_format => $JSON_SCHEMA_RF },
    { response_format => 'json_schema' } ],
  [ 'tools + required, no response_format' => {
      tools => [$TOOL], tool_choice => 'required' },
    { tool_choice => 'required' } ],
  [ 'tools + required + response_format text' => {
      tools => [$TOOL], tool_choice => 'required', response_format => { type => 'text' } },
    { tool_choice => 'required', response_format => 'text' } ],
  [ 'json_schema alone' => { response_format => $JSON_SCHEMA_RF },
    { response_format => 'json_schema' } ],
);

for my $case (@allowed) {
  my ( $label, $args, $want ) = @$case;
  my $mock = mock();
  my ( $ok, $err ) = run( sub { engine($mock)->chat_f(
    messages => [ { role => 'user', content => 'hi' } ], %$args,
  ) } );
  ok( $ok, "SGLang: $label is not refused" ) or diag $err;
  is( $mock->request_count, 1, "  $label reached the wire" );
  my ($req) = $mock->requests;
  next unless $req;
  my $body = $json->decode( $req->content );
  is( $body->{tool_choice}, $want->{tool_choice}, "  $label: tool_choice on the wire" )
    if exists $want->{tool_choice};
  is( $body->{response_format}{type}, $want->{response_format},
    "  $label: response_format on the wire" ) if exists $want->{response_format};
}

# The seam contract: a rule sees tool_choice_forced next to the existing keys,
# read from the request before any tool_choice gate can drop it.
{
  package Test::SGLangRecorder;
  use Moose;
  extends 'Langertha::Engine::SGLang';
  our @SEEN;
  sub model_capability_exclusions { return ( qr// => sub { shift; push @SEEN, {@_}; return } ) }
  __PACKAGE__->meta->make_immutable;
}

for my $case (
  [ 'absent' => undef, 0 ],
  [ 'auto'   => 'auto', 0 ],
  [ 'none'   => 'none', 0 ],
  [ 'required' => 'required', 1 ],
  [ 'named'  => { type => 'function', function => { name => 'get_weather' } }, 1 ],
) {
  my ( $label, $tc, $want ) = @$case;
  @Test::SGLangRecorder::SEEN = ();
  my $engine = Test::SGLangRecorder->new( url => 'http://localhost:30000/v1', _async_http => mock() );
  run( sub { $engine->chat_f(
    messages => [ { role => 'user', content => 'hi' } ],
    tools    => [$TOOL],
    ( defined $tc ? ( tool_choice => $tc ) : () ),
  ) } );
  is( scalar @Test::SGLangRecorder::SEEN, 1, "seam: rule called once ($label)" );
  my $seen = $Test::SGLangRecorder::SEEN[0] || {};
  is( $seen->{tool_choice_forced}, $want, "seam: tool_choice_forced for $label" );
  ok( exists $seen->{has_tools} && exists $seen->{streaming} && exists $seen->{response_format},
    "seam: existing keys still passed ($label)" );
}

# karr k249: the guard sees the engine-level response_format too, and the
# per-request value wins over it exactly as on the wire.
{
  my $mock = mock();
  my ( $ok, $err ) = run( sub { Langertha::Engine::SGLang->new(
    url => 'http://localhost:30000/v1', response_format => $JSON_SCHEMA_RF,
    _async_http => $mock,
  )->chat_f(
    messages => [ { role => 'user', content => 'hi' } ],
    tools    => [$TOOL], tool_choice => 'required',
  ) } );
  ok( !$ok, 'SGLang: engine-level json_schema + forced tool_choice croaks (k249)' );
  like( $err, qr/tool_choice.*response_format/s, '  croak is the exclusion' );
  is( $mock->request_count, 0, '  nothing reached the wire' );
}
{
  my $mock = mock();
  my ( $ok, $err ) = run( sub { Langertha::Engine::SGLang->new(
    url => 'http://localhost:30000/v1', response_format => $JSON_SCHEMA_RF,
    _async_http => $mock,
  )->chat_f(
    messages        => [ { role => 'user', content => 'hi' } ],
    tools           => [$TOOL], tool_choice => 'required',
    response_format => { type => 'text' },
  ) } );
  ok( $ok, 'SGLang: per-request text overrides engine-level json_schema (k249)' ) or diag $err;
  my ($req) = $mock->requests;
  is( $req && $json->decode( $req->content )->{response_format}{type}, 'text',
    '  the per-request response_format is the one on the wire' );
}

done_testing;
