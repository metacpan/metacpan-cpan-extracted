#!/usr/bin/env perl
# ABSTRACT: chat_f / chat_stream_realtime_f / Langertha::Chat warn when a per-request model flips a model-scoped wire decision
use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';
use JSON::MaybeXS;
use Moose::Util ();
use Test::MockAsyncHTTP;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Moonshot;
use Langertha::Engine::NousResearch;
use Langertha::Engine::DeepSeek;
use Langertha::Engine::Gemini;
use Langertha::CachedContent;

# karr k352 (split from k238). A `model` passed to chat_f or
# chat_stream_realtime_f is no canonical control: it rides %extra into the
# request builder and overrides the body's model field, while every
# model-scoped wire decision still reads the engine's chat_model -- the layer-3
# capability corrections (ADR 0019), the exclusion rules (ADR 0024), the
# reasoning profile (ADR 0023), the reasoning temperature gate (ADR 0025), the
# per-model tool_wire_format (ADR 0033) and the per-model body keys. A Claude
# slug passed per request to a NousResearch engine configured for a Hermes
# model therefore got the hermes tool prompt instead of native tools, and
# nothing said so. Langertha does not re-scope per request (that would be a
# second engine); it warns, naming what flips.
#
# The warning must stay quiet where nothing flips -- the same model, or a
# different model whose decisions this request does not consult -- or it is
# noise a caller learns to ignore. So only the decisions the request consults
# are compared. All mocked, no live calls.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $file = __FILE__;

my $openai_reply = { choices => [ { index => 0, finish_reason => 'stop',
  message => { role => 'assistant', content => 'ok' } } ] };
my $anthropic_reply = { id => 'msg_1', type => 'message', role => 'assistant',
  content => [ { type => 'text', text => 'ok' } ], stop_reason => 'end_turn' };

sub mock { Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( $_[0] // $openai_reply ) ] ) }

my $TOOL = {
  name        => 'get_weather',
  description => 'Weather for a city',
  inputSchema => { type => 'object', properties => { city => { type => 'string' } }, required => ['city'] },
};
my $MSGS = [ { role => 'user', content => 'weather?' } ];

# Runs chat_f on $engine with %opts; returns ( \@override_warnings, $body ).
sub chat_f_run {
  my ( $engine, %opts ) = @_;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $engine->chat_f( messages => $MSGS, %opts )->get;
  my ($request) = $engine->_async_http->requests;
  return ( [ grep { /per-request model/ } @warns ], $json->decode( $request->content ) );
}

sub openai { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o', _async_http => mock(), @_ ) }
sub nous   { Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B', _async_http => mock(), @_ ) }

subtest 'no override, or the same model: silent' => sub {
  my ($warns) = chat_f_run( openai() );
  is( scalar @$warns, 0, 'no model key: no warning' );
  ($warns) = chat_f_run( openai(), model => 'gpt-4o', max_tokens => 50, temperature => 0.3 );
  is( scalar @$warns, 0, 'model equal to chat_model: no warning' ) or diag @$warns;
  ($warns) = chat_f_run( openai(), model => '' );
  is( scalar @$warns, 0, 'an empty model is no override: no warning' ) or diag @$warns;
};

subtest 'a different model whose decisions this request does not consult: silent' => sub {
  # gpt-4o and gpt-5.6 differ in the completion-length key and the reasoning
  # profile, but a plain chat sends no length and no temperature/reasoning.
  my ( $warns, $body ) = chat_f_run( openai(), model => 'gpt-5.6' );
  is( scalar @$warns, 0, 'plain chat: no warning' ) or diag @$warns;
  is( $body->{model}, 'gpt-5.6', 'the override still goes out as the body model' );

  # Hermes-4-70B vs a Claude slug differ in tool wire and tool capabilities,
  # none of which a tool-less request consults.
  ($warns) = chat_f_run( nous(), model => 'anthropic/claude-sonnet-4.6' );
  is( scalar @$warns, 0, 'NousResearch without tools: no warning' ) or diag @$warns;

  # Two Hermes models share every decision, tools included.
  ($warns) = chat_f_run( nous(), model => 'Hermes-4-405B', tools => [$TOOL] );
  is( scalar @$warns, 0, 'Hermes to Hermes with tools: no warning' ) or diag @$warns;
};

subtest 'NousResearch: a Claude slug on a Hermes engine keeps the hermes wire (k238)' => sub {
  my ( $warns, $body ) = chat_f_run( nous(), model => 'anthropic/claude-sonnet-4.6', tools => [$TOOL] );
  is( scalar @$warns, 1, 'one warning' ) or diag @$warns;
  like( $warns->[0], qr/per-request model 'anthropic\/claude-sonnet-4\.6'.*chat_model 'Hermes-4-70B'/s,
    'names the override and the configured model' );
  like( $warns->[0], qr/tool_wire_format/, 'names the tool wire' );
  like( $warns->[0], qr/supports\('tools_native'\)/, 'names the tools capability' );
  ok( !exists $body->{tools}, 'the request still rides the hermes prompt (status quo, now warned)' );
  is( $body->{model}, 'anthropic/claude-sonnet-4.6', 'with the override as the body model' );
};

subtest 'a constructor tool_wire_format holds for every model: silent' => sub {
  # ADR 0033: tool_wire_format => ... wins on any slug, so the override flips
  # no tool wire (the probe resolves only a builder-made tag again, k251).
  my ($warns) = chat_f_run( nous( tool_wire_format => 'openai' ),
    model => 'anthropic/claude-sonnet-4.6', tools => [$TOOL] );
  is( scalar @$warns, 0, 'forced openai wire: no warning' ) or diag @$warns;
};

subtest 'OpenAI: completion-length key and temperature gate follow chat_model' => sub {
  my ( $warns, $body ) = chat_f_run( openai(), model => 'gpt-5.6', max_tokens => 100 );
  is( scalar @$warns, 1, 'max_tokens: one warning' ) or diag @$warns;
  like( $warns->[0], qr/completion-length key/, 'names the length key' );
  ok( exists $body->{max_tokens} && !exists $body->{max_completion_tokens},
    'the body still uses the gpt-4o key the gpt-5.6 wire rejects' );

  ($warns) = chat_f_run( openai(), model => 'gpt-5.6', temperature => 0.7 );
  is( scalar @$warns, 1, 'temperature: one warning' ) or diag @$warns;
  like( $warns->[0], qr/temperature gate/, 'names the ADR 0025 gate' );

  ($warns) = chat_f_run( openai(), model => 'gpt-5.6', reasoning_effort => 'high' );
  is( scalar @$warns, 1, 'reasoning_effort: one warning' ) or diag @$warns;
  like( $warns->[0], qr/reasoning profile/, 'names the ADR 0023 profile' );
};

subtest 'Anthropic: a layer-3 capability consulted by the request' => sub {
  my $anth = sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6',
    _async_http => mock($anthropic_reply), @_ ) };
  # claude-opus-4-8 takes no temperature (layer 3); a request without one
  # consults nothing that differs.
  my ($warns) = chat_f_run( $anth->(), model => 'claude-opus-4-8' );
  is( scalar @$warns, 0, 'no temperature: no warning' ) or diag @$warns;
  ($warns) = chat_f_run( $anth->(), model => 'claude-opus-4-8', temperature => 0.5 );
  is( scalar @$warns, 1, 'per-request temperature: one warning' ) or diag @$warns;
  like( $warns->[0], qr/supports\('temperature'\)/, 'names the temperature capability' );
  ($warns) = chat_f_run( $anth->( temperature => 0.5 ), model => 'claude-opus-4-8' );
  is( scalar @$warns, 1, 'engine temperature attribute: one warning' ) or diag @$warns;
};

subtest 'Moonshot: named tool_choice and the per-model response size' => sub {
  my $moon = sub { Langertha::Engine::Moonshot->new( api_key => 'k', model => 'kimi-k2.5',
    _async_http => mock(), @_ ) };
  my ($warns) = chat_f_run( $moon->(), model => 'kimi-k3', tools => [$TOOL],
    tool_choice => { type => 'tool', name => 'get_weather' }, max_tokens => 100 );
  is( scalar @$warns, 1, 'forced tool: one warning' ) or diag @$warns;
  like( $warns->[0], qr/supports\('tool_choice_named'\)/, 'names the named-tool capability' );
  unlike( $warns->[0], qr/response_size/, 'a per-request max_tokens makes the size default moot' );

  # kimi-k3 defaults to a larger response size (ADR 0019 k225) that a plain
  # request sends as its max_tokens.
  ($warns) = chat_f_run( $moon->(), model => 'kimi-k3' );
  is( scalar @$warns, 1, 'plain chat: one warning' ) or diag @$warns;
  like( $warns->[0], qr/response_size default/, 'names the response size default' );
};

{
  package Test::ModelExclusionEngine;
  use Moose;
  extends 'Langertha::Engine::OpenAI';
  our @FIRED;
  sub model_capability_exclusions { return ( 'gpt-4o' => sub { push @FIRED, 1; return } ) }
  __PACKAGE__->meta->make_immutable;
}

subtest 'a model-keyed exclusion rule follows chat_model (ADR 0024)' => sub {
  my $engine = sub { Test::ModelExclusionEngine->new( api_key => 'k', model => 'gpt-4o', _async_http => mock() ) };
  my ($warns) = chat_f_run( $engine->(), model => 'gpt-4.1' );
  is( scalar @$warns, 0, 'no tools / response_format: no warning' ) or diag @$warns;
  @Test::ModelExclusionEngine::FIRED = ();
  ($warns) = chat_f_run( $engine->(), model => 'gpt-4.1', tools => [$TOOL] );
  is( scalar @$warns, 1, 'tools: one warning' ) or diag @$warns;
  like( $warns->[0], qr/model_capability_exclusions/, 'names the exclusion rules' );
  is( scalar @Test::ModelExclusionEngine::FIRED, 1, 'the gpt-4o rule still ran for the gpt-4.1 request' );
};

subtest 'names the caller, and warns on every request' => sub {
  my $engine = openai( _async_http => Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response($openai_reply) ] ) );
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my $line = __LINE__ + 1;
  $engine->chat_f( messages => $MSGS, model => 'gpt-5.6', max_tokens => 10 )->get;
  $engine->chat_f( messages => $MSGS, model => 'gpt-5.6', max_tokens => 10 )->get;
  my @hits = grep { /per-request model/ } @warns;
  is( scalar @hits, 2, 'a per-request value warns every time' ) or diag @warns;
  like( $hits[0], qr/\Q at $file line $line.\E/, "names this file's call line" );
};

subtest 'Gemini: cached_content is consulted only with a bound cachedContent' => sub {
  # The Gemini layer 2 grants cached_content to 2.5 / 3 and clears it on 2.0
  # (and moves reasoning_effort / thinking_budget); a request with no bound
  # cache, no tools and no reasoning control uses none of that.
  my $gemini_reply = { candidates => [ { finishReason => 'STOP',
    content => { role => 'model', parts => [ { text => 'ok' } ] } } ] };
  my $gemini = sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash',
    _async_http => mock($gemini_reply), @_ ) };
  my ($warns) = chat_f_run( $gemini->(), model => 'gemini-2.0-flash' );
  is( scalar @$warns, 0, 'no cachedContent, no tools: no warning' ) or diag @$warns;

  ($warns) = chat_f_run( $gemini->( cached_content => Langertha::CachedContent->new( name => 'cachedContents/abc' ) ),
    model => 'gemini-2.0-flash' );
  is( scalar @$warns, 1, 'bound cachedContent: one warning' ) or diag @$warns;
  like( $warns->[0], qr/supports\('cached_content'\)/, 'names the cached_content capability' );
};

{
  package Test::UnlistedFlagEngine;
  use Moose;
  extends 'Langertha::Engine::OpenAI';
  # A model-scoped correction of a flag %CAP_CONSULTED_BY does not list.
  sub model_capability_corrections { return ( 'gpt-4.1' => { prompt_cache_key => 0 } ) }
  __PACKAGE__->meta->make_immutable;
}

subtest 'a flag the table does not list is always compared' => sub {
  # So a new model-scoped flag errs toward a warning, not toward silence.
  my ($warns) = chat_f_run( Test::UnlistedFlagEngine->new( api_key => 'k', model => 'gpt-4o', _async_http => mock() ),
    model => 'gpt-4.1' );
  is( scalar @$warns, 1, 'plain chat: one warning' ) or diag @$warns;
  like( $warns->[0], qr/supports\('prompt_cache_key'\)/, 'names the unlisted flag' );
};

subtest 'NousResearch: the reasoning prompt follows chat_model (ADR 0033)' => sub {
  my ( $warns, $body ) = chat_f_run( nous( reasoning => 1 ), model => 'anthropic/claude-sonnet-4.6' );
  is( scalar @$warns, 1, 'reasoning => 1: one warning' ) or diag @$warns;
  like( $warns->[0], qr/reasoning prompt/, 'names the reasoning prompt' );
  is( $body->{messages}[0]{role}, 'system', 'the Hermes reasoning prompt still goes out (status quo, now warned)' );
  ($warns) = chat_f_run( nous( reasoning => 1 ), model => 'Hermes-4-405B' );
  is( scalar @$warns, 0, 'Hermes to Hermes: no warning' ) or diag @$warns;
};

subtest 'DeepSeek: the thinking switch follows chat_model (k362)' => sub {
  # reasoning_kwargs_for sends thinking:{type:enabled} on the V3.2 line and a
  # flat reasoning_effort on V4, decided off chat_model. Every DeepSeek id
  # resolves the same reasoning profile, so without its own named decision a
  # per-request model crossing the V3 line flipped the wire silently.
  my $ds = sub { Langertha::Engine::DeepSeek->new( api_key => 'k', model => 'deepseek-flash',
    _async_http => mock(), @_ ) };
  my ( $warns, $body ) = chat_f_run( $ds->(), model => 'deepseek-v3.2', reasoning_effort => 'high' );
  is( scalar @$warns, 1, 'per-request reasoning_effort: one warning' ) or diag @$warns;
  like( $warns->[0], qr/thinking switch/, 'names the thinking switch' );
  is( $body->{reasoning_effort}, 'high', 'the body still carries the V4 flat effort (status quo, now warned)' );
  ok( !exists $body->{thinking}, 'and no V3.2 thinking toggle' );

  ($warns) = chat_f_run( $ds->( reasoning_effort => 'low' ), model => 'deepseek-v3.2' );
  is( scalar @$warns, 1, 'engine reasoning_effort attribute: one warning' ) or diag @$warns;

  ($warns) = chat_f_run( $ds->(), model => 'deepseek-v3.2' );
  is( scalar @$warns, 0, 'no reasoning control: no warning' ) or diag @$warns;

  ($warns) = chat_f_run( $ds->(), model => 'deepseek-v4-pro', reasoning_effort => 'high' );
  is( scalar @$warns, 0, 'V4 to V4: no warning' ) or diag @$warns;
};

{
  package Test::CroakingDecisionEngine;
  use Moose;
  extends 'Langertha::Engine::OpenAI';
  # A decision that cannot be computed for one model.
  sub _max_tokens_key { $_[0]->chat_model eq 'boom' ? die "no key for boom\n" : 'max_tokens' }
  __PACKAGE__->meta->make_immutable;
}

subtest 'a decision that croaks for the override: silent, the request goes on' => sub {
  my $engine = Test::CroakingDecisionEngine->new( api_key => 'k', model => 'gpt-4o', _async_http => mock() );
  my @all;
  local $SIG{__WARN__} = sub { push @all, $_[0] };
  my $response = $engine->chat_f( messages => $MSGS, model => 'boom', max_tokens => 10 )->get;
  ok( defined $response, 'chat_f still answers' );
  is( scalar @all, 0, 'no warning of any kind' ) or diag @all;
  unlike( $@ // '', qr/no key for boom/, 'the swallowed error does not leak into $@' );
  my ($request) = $engine->_async_http->requests;
  is( $json->decode( $request->content )->{model}, 'boom', 'the request went out with the override' );
};

{
  # Records what chat_stream_realtime_f hands to chat_stream_request and stops
  # there: the claim is the warning, not the transport.
  package Test::StopAtStreamRequest;
  use Moose::Role;
  around chat_stream_request => sub { die "stop before sending\n" };
}

subtest 'chat_stream_realtime_f warns the same way' => sub {
  my $stream = sub {
    my (%opts) = @_;
    my $engine = Moose::Util::with_traits( 'Langertha::Engine::NousResearch', 'Test::StopAtStreamRequest' )
      ->new( api_key => 'k', model => 'Hermes-4-70B' );
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    ok( !eval { $engine->chat_stream_realtime_f( messages => $MSGS, %opts )->get; 1 }, 'stopped' );
    is( $@, "stop before sending\n", 'at the recording stop, not an earlier croak' );
    return [ grep { /per-request model/ } @warns ];
  };
  my $warns = $stream->( model => 'anthropic/claude-sonnet-4.6', tools => [$TOOL] );
  is( scalar @$warns, 1, 'tools: one warning' ) or diag @$warns;
  like( $warns->[0], qr/chat_stream_realtime_f.*tool_wire_format/s, 'names the stream call and the tool wire' );
  $warns = $stream->( model => 'Hermes-4-70B', tools => [$TOOL] );
  is( scalar @$warns, 0, 'same model: no warning' ) or diag @$warns;
};

# karr k360. Langertha::Chat's model attribute rides %extra straight into
# chat_request / chat_stream_request / build_tool_chat_request, past chat_f, so
# the same silent flip happened there without a word. Every Chat entry point
# now raises the engine's own warning, with the features the call uses (the
# wrapper's temperature, the gathered tools, streaming), once per call.
{
  package Test::CannedUA;
  use parent -norequire, 'LWP::UserAgent';
  sub new { my ( $class, $body ) = @_; my $self = LWP::UserAgent::new($class); $self->{body} = $body; $self->{sent} = []; $self }
  sub sent { $_[0]{sent} }
  sub request {
    my ( $self, $request ) = @_;
    push @{ $self->{sent} }, $request;
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
      JSON::MaybeXS->new( utf8 => 1 )->encode( $self->{body} ) );
  }
}
{
  package Test::OneToolMCP;
  use Future;
  sub new { bless { tool => $_[1] }, $_[0] }
  sub list_tools { Future->done( [ $_[0]{tool} ] ) }
  sub call_tool { die "no tool call expected\n" }
}

subtest 'Langertha::Chat: its model warns like a per-request model (k360)' => sub {
  require Langertha::Chat;
  require HTTP::Response;
  require LWP::UserAgent;
  my $moon = sub { Langertha::Engine::Moonshot->new( api_key => 'k', model => 'kimi-k2.5',
    _async_http => mock(), @_ ) };
  my $capture = sub {
    my ($code) = @_;
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    $code->();
    return [ grep { /per-request model/ } @warns ];
  };

  # kimi-k3 has a larger response-size default (ADR 0019 k225), which a plain
  # chat sends as its max_tokens.
  my $engine = $moon->();
  my $line = __LINE__ + 1;
  my $warns = $capture->( sub { Langertha::Chat->new( engine => $engine, model => 'kimi-k3' )->simple_chat_f('hi')->get } );
  is( scalar @$warns, 1, 'simple_chat_f: one warning' ) or diag @$warns;
  like( $warns->[0], qr/Langertha::Chat->simple_chat_f got a per-request model 'kimi-k3'.*chat_model 'kimi-k2\.5'/s,
    'names the Chat call, the override and the configured model' );
  like( $warns->[0], qr/response_size default/, 'names the flipped decision' );
  like( $warns->[0], qr/\Q at $file line $line.\E/, "names this file's call line" );
  my ($request) = $engine->_async_http->requests;
  is( $json->decode( $request->content )->{model}, 'kimi-k3', 'the request still goes out with the override' );

  $warns = $capture->( sub { Langertha::Chat->new( engine => $moon->(), model => 'kimi-k2.5' )->simple_chat_f('hi')->get } );
  is( scalar @$warns, 0, 'the same model: no warning' ) or diag @$warns;
  $warns = $capture->( sub { Langertha::Chat->new( engine => $moon->() )->simple_chat_f('hi')->get } );
  is( scalar @$warns, 0, 'no model: no warning' ) or diag @$warns;

  my $sync = $moon->( user_agent => Test::CannedUA->new($openai_reply) );
  $warns = $capture->( sub { Langertha::Chat->new( engine => $sync, model => 'kimi-k3' )->simple_chat('hi') } );
  is( scalar @$warns, 1, 'simple_chat: one warning' ) or diag @$warns;
  like( $warns->[0], qr/Langertha::Chat->simple_chat got/, 'names simple_chat' );

  # The wrapper's own temperature is a request feature: claude-opus-4-8 takes
  # none (layer 3), which only matters when one is sent.
  my $anth = sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6',
    _async_http => mock($anthropic_reply) ) };
  $warns = $capture->( sub { Langertha::Chat->new( engine => $anth->(), model => 'claude-opus-4-8' )->simple_chat_f('hi')->get } );
  is( scalar @$warns, 0, 'Anthropic without temperature: no warning' ) or diag @$warns;
  $warns = $capture->( sub { Langertha::Chat->new( engine => $anth->(), model => 'claude-opus-4-8',
    temperature => 0.5 )->simple_chat_f('hi')->get } );
  is( scalar @$warns, 1, 'the Chat temperature: one warning' ) or diag @$warns;
  like( $warns->[0], qr/supports\('temperature'\)/, 'names the temperature capability' );

  # The tool loop: the gathered tools are a request feature, and the loop
  # warns once per call, not once per iteration.
  my $mcp = Test::OneToolMCP->new($TOOL);
  $warns = $capture->( sub { Langertha::Chat->new( engine => nous(), model => 'anthropic/claude-sonnet-4.6',
    mcp_servers => [$mcp] )->simple_chat_with_tools_f('hi')->get } );
  is( scalar @$warns, 1, 'simple_chat_with_tools_f: one warning' ) or diag @$warns;
  like( $warns->[0], qr/simple_chat_with_tools_f.*tool_wire_format/s, 'names the loop call and the tool wire' );
  $warns = $capture->( sub { Langertha::Chat->new( engine => nous( user_agent => Test::CannedUA->new($openai_reply) ),
    model => 'anthropic/claude-sonnet-4.6', mcp_servers => [$mcp] )->simple_chat_with_tools('hi') } );
  is( scalar @$warns, 1, 'simple_chat_with_tools: one warning' ) or diag @$warns;
  $warns = $capture->( sub { Langertha::Chat->new( engine => nous(), model => 'Hermes-4-405B',
    mcp_servers => [$mcp] )->simple_chat_with_tools_f('hi')->get } );
  is( scalar @$warns, 0, 'Hermes to Hermes in the loop: no warning' ) or diag @$warns;

  # simple_chat_stream: stopped at chat_stream_request, the claim is the warning.
  my $streamer = Moose::Util::with_traits( 'Langertha::Engine::NousResearch', 'Test::StopAtStreamRequest' )
    ->new( api_key => 'k', model => 'Hermes-4-70B', reasoning => 1 );
  $warns = $capture->( sub {
    ok( !eval { Langertha::Chat->new( engine => $streamer, model => 'anthropic/claude-sonnet-4.6' )
      ->simple_chat_stream( sub {}, 'hi' ); 1 }, 'stream stopped' );
    is( $@, "stop before sending\n", 'at the recording stop' );
  } );
  is( scalar @$warns, 1, 'simple_chat_stream: one warning' ) or diag @$warns;
  like( $warns->[0], qr/simple_chat_stream.*reasoning prompt/s, 'names the stream call and the reasoning prompt' );

  # Gemini names the model in the URL: the Chat model now routes there (k357).
  my $gemini_reply = { candidates => [ { finishReason => 'STOP',
    content => { role => 'model', parts => [ { text => 'ok' } ] } } ] };
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash',
    _async_http => mock($gemini_reply) );
  $capture->( sub { Langertha::Chat->new( engine => $gemini, model => 'gemini-2.5-pro' )->simple_chat_f('hi')->get } );
  ($request) = $gemini->_async_http->requests;
  like( $request->uri, qr{/models/gemini-2\.5-pro:generateContent}, 'Gemini: the Chat model names the URL model' );
};

done_testing;
