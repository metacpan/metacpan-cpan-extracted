use strict;
use warnings;
use Test2::V0;

# k14: Knarr serves /.well-known/langertha.json so `raider --provider HOST`
# can configure itself from what this Knarr actually exposes. The manifest
# comes from the network to clients, so it must never carry Knarr's config:
# no upstream URL, key, key variable name, engine class, upstream model name
# or passthrough target. Capabilities must be honest per endpoint: the
# serving engine's (model-scoped) flags, narrowed to what the protocol
# forwards. Needs a Langertha core with Langertha::Manifest (unreleased at
# the time of writing); t/66_manifest_absent.t covers the older core.

BEGIN {
  eval { require Langertha::Manifest::Builder; 1 }
    or plan skip_all => 'installed Langertha has no Langertha::Manifest::Builder'
      . ' (unreleased core; run with -I/path/to/langertha/lib)';
}

BEGIN {
  # Offline gateway for auto_discover: a real Langertha engine whose model
  # list comes without a network call.
  package LangerthaX::Engine::TestManifestGateway;
  use Moose;
  extends 'Langertha::Engine::OpenAI';
  sub list_models { [ 'vendor-a/model-one', 'vendor-b/model-two' ] }
  __PACKAGE__->meta->make_immutable;
  $INC{'LangerthaX/Engine/TestManifestGateway.pm'} = __FILE__;
}

use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;
use Langertha::Manifest;
use Langertha::Manifest::Builder;
use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Image;
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new;
$loop->add($http);

# Values that must never appear in the published manifest.
$ENV{KNARR_TEST_UPSTREAM_KEY} = 'sk-upstream-secret-4711';
delete $ENV{KNARR_TEST_UNSET_KEY};
my @SECRETS = (
  'sk-upstream-secret-4711',     # upstream key from api_key_env
  'KNARR_TEST_UPSTREAM_KEY',     # its variable name
  'KNARR_TEST_UNSET_KEY',
  'sk-ant-literal-secret',       # literal api_key in the config
  'internal-upstream.example',   # upstream URLs
  'gpu-box.internal',
  'passthrough-target.internal', # passthrough target
  'sk-lf-langfuse-secret',       # langfuse secret
  'pk-lf-langfuse-public',
  'gpt-5.6', 'claude-opus-4-1', 'qwen3',  # upstream model names behind aliases
  'OllamaOpenAI', 'Engine::', 'engine', 'api_key_env',
);

sub surface_config {
  my (%extra) = @_;
  return Langertha::Knarr::Config->new( data => {
    models => {
      'gpt-alias' => {
        engine => 'OpenAI', model => 'gpt-5.6',
        url => 'http://internal-upstream.example:9999/v1',
        api_key_env => 'KNARR_TEST_UPSTREAM_KEY',
      },
      'claude-alias' => {
        engine => 'Anthropic', model => 'claude-opus-4-1',
        api_key => 'sk-ant-literal-secret',
      },
      'local' => {
        engine => 'OllamaOpenAI', model => 'qwen3',
        url => 'http://gpu-box.internal:11434/v1',
      },
      # Its key variable is unset: the router cannot serve it, so it is not
      # published.
      'broken' => {
        engine => 'OpenAI', model => 'gpt-5.6',
        api_key_env => 'KNARR_TEST_UNSET_KEY',
      },
    },
    passthrough => { openai => 'http://passthrough-target.internal/v1' },
    langfuse => { public_key => 'pk-lf-langfuse-public', secret_key => 'sk-lf-langfuse-secret',
      url => 'http://internal-upstream.example:3000' },
    %extra,
  } );
}

sub start_knarr {
  my (%args) = @_;
  my $config = delete $args{config};
  my $router = Langertha::Knarr::Router->new( config => $config );
  my $knarr = Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Router->new( router => $router ),
    router  => $router,
    loop    => $loop,
    port    => 0,
    %args,
  );
  $knarr->start;
  return ( $knarr, $knarr->_server->read_handle->sockport, $router );
}

sub get_manifest {
  my ( $port, %headers ) = @_;
  my $req = HTTP::Request->new( GET => "http://127.0.0.1:$port/.well-known/langertha.json" );
  $req->header( $_ => $headers{$_} ) for keys %headers;
  return $http->do_request( request => $req )->get;
}

sub model_entry {
  my ( $data, $id, $endpoint ) = @_;
  my ($m) = grep { $_->{id} eq $id && $_->{endpoint_ref} eq $endpoint } @{ $data->{models} };
  return $m;
}

sub no_leaks {
  my ( $body, $label ) = @_;
  for my $secret (@SECRETS) {
    unlike $body, qr/\Q$secret\E/, "$label: no '$secret' in the manifest";
  }
}

# --- Native server, open proxy -------------------------------------------
my ( $knarr, $port, $router ) = start_knarr( config => surface_config() );
{
  my $resp = get_manifest($port);
  is $resp->code, 200, 'manifest served';
  like scalar $resp->header('Content-Type'), qr{application/json}, 'JSON content type';
  my $body = $resp->decoded_content;

  my $parsed = eval { Langertha::Manifest->from_json($body) };
  ok $parsed, 'core Manifest validator accepts it' or diag $@;
  my $data = $json->decode($body);

  is $data->{provider_id}, 'knarr', 'provider_id';
  is $data->{issuer}, "http://127.0.0.1:$port", 'issuer is the request origin';
  is [ map { [ @{$_}{qw( id dialect base_url )} ] } @{ $data->{endpoints} } ], [
    [ 'openai',    'openai-chat',      "http://127.0.0.1:$port/v1" ],
    [ 'anthropic', 'anthropic-compat', "http://127.0.0.1:$port" ],
    [ 'ollama',    'ollama',           "http://127.0.0.1:$port" ],
  ], 'one endpoint per protocol with a manifest dialect (A2A/ACP/AG-UI not published)';
  ok !exists $_->{auth_ref}, "endpoint $_->{id}: no auth_ref on an open proxy"
    for @{ $data->{endpoints} };
  is $data->{auth}, [], 'no auth entry on an open proxy';

  is [ sort map { "$_->{endpoint_ref}:$_->{id}" } @{ $data->{models} } ], [
    'anthropic:claude-alias', 'anthropic:gpt-alias', 'anthropic:local',
    'ollama:claude-alias',    'ollama:gpt-alias',    'ollama:local',
    'openai:claude-alias',    'openai:gpt-alias',    'openai:local',
  ], 'every servable alias on every endpoint; the unservable one is left out';

  # Capabilities: only what the serving engine has for that model ...
  my %allowed = map { $_ => 1 } Langertha::Manifest::Builder->model_capabilities;
  for my $m ( @{ $data->{models} } ) {
    my ($engine) = $router->resolve( $m->{id} );
    my $engine_caps = $engine->meta->clone_object( $engine )->engine_capabilities;
    for my $cap ( sort keys %{ $m->{capabilities} } ) {
      ok $allowed{$cap}, "$m->{endpoint_ref}:$m->{id}: $cap is a public model capability";
      ok $engine_caps->{$cap}, "$m->{endpoint_ref}:$m->{id}: $cap is the engine's own";
    }
  }
  # ... and never an engine-level flag, even where the engine has it.
  ok !exists model_entry( $data, 'gpt-alias', 'openai' )->{capabilities}{embedding},
    'embedding (an engine operation, not a chat capability) is not published';

  # ... narrowed to what the protocol forwards.
  my $gpt_openai = model_entry( $data, 'gpt-alias', 'openai' )->{capabilities};
  ok $gpt_openai->{$_}, "gpt-alias on openai: $_"
    for qw( chat streaming tools_native tool_choice_named response_format_json_schema );
  my $gpt_anthropic = model_entry( $data, 'gpt-alias', 'anthropic' )->{capabilities};
  ok $gpt_anthropic->{tools_native}, 'gpt-alias on anthropic: tools are forwarded';
  ok !$gpt_anthropic->{$_}, "gpt-alias on anthropic: $_ is not forwarded, not claimed"
    for qw( response_format_json_schema response_format_json_object seed prompt_cache_key );
  my $gpt_ollama = model_entry( $data, 'gpt-alias', 'ollama' )->{capabilities};
  ok !$gpt_ollama->{$_}, "gpt-alias on ollama: $_ is not forwarded, not claimed"
    for qw( tool_choice_named tool_choice_auto response_format_json_schema response_size );
  ok $gpt_ollama->{$_}, "gpt-alias on ollama: $_ is forwarded" for qw( tools_native temperature );
  # thinking / think arrive as reasoning_effort (k13).
  ok $gpt_anthropic->{reasoning_effort}, 'gpt-alias on anthropic: reasoning_effort is forwarded';
  ok $gpt_ollama->{reasoning_effort}, 'gpt-alias on ollama: reasoning_effort is forwarded';

  no_leaks( $body, 'native' );
}

# --- image_input (k32): per model, and only where the image parts arrive --
# Knarr translates every protocol's image parts into core image objects
# (k33), so a vision model claims image_input on every endpoint. On a core
# too old to write those objects in every format the parts pass through
# untranslated and are readable only by engines whose content format has that
# shape (OpenAI image_url: OpenAI-shape engines, Gemini translates; Anthropic
# image blocks: Anthropic-shape engines; Ollama's images array: the native
# Ollama engine).
{
  my $config = Langertha::Knarr::Config->new( data => { models => {
    'gpt'      => { engine => 'OpenAI',    model => 'gpt-5.6',          api_key => 'sk-test' },
    'claude'   => { engine => 'Anthropic', model => 'claude-opus-4-1',  api_key => 'sk-test' },
    'claude-2' => { engine => 'Anthropic', model => 'claude-2.1',       api_key => 'sk-test' },
    'gemini'   => { engine => 'Gemini',    model => 'gemini-2.5-flash', api_key => 'sk-test' },
    'hermes'   => { engine => 'NousResearch', model => 'Hermes-4-70B',  api_key => 'sk-test' },
  } } );
  my ( undef, $img_port ) = start_knarr( config => $config );
  my $data = $json->decode( get_manifest($img_port)->decoded_content );
  my %expect = Langertha::Knarr::Image::translates() ? (
    'gpt'      => { openai => 1, anthropic => 1, ollama => 1 },
    'claude'   => { openai => 1, anthropic => 1, ollama => 1 },
    'claude-2' => { openai => 0, anthropic => 0, ollama => 0 },  # text-only model, same engine
    'gemini'   => { openai => 1, anthropic => 1, ollama => 1 },
    'hermes'   => { openai => 0, anthropic => 0, ollama => 0 },  # engine makes no claim
  ) : (
    'gpt'      => { openai => 1, anthropic => 0, ollama => 0 },
    'claude'   => { openai => 0, anthropic => 1, ollama => 0 },
    'claude-2' => { openai => 0, anthropic => 0, ollama => 0 },
    'gemini'   => { openai => 1, anthropic => 0, ollama => 0 },
    'hermes'   => { openai => 0, anthropic => 0, ollama => 0 },
  );
  for my $id ( sort keys %expect ) {
    for my $ep ( sort keys %{ $expect{$id} } ) {
      my $entry = model_entry( $data, $id, $ep );
      ok $entry, "$ep:$id published" or next;
      is !!$entry->{capabilities}{image_input}, !!$expect{$id}{$ep},
        "$ep:$id: image_input " . ( $expect{$id}{$ep} ? 'claimed' : 'not claimed' );
    }
  }
}

# --- Auth reflection ------------------------------------------------------
{
  my ( undef, $auth_port ) = start_knarr( config => surface_config(), auth_token => 'knarr-proxy-token-99' );
  is get_manifest($auth_port)->code, 401, 'protected like /v1/models: no key, 401';

  my $resp = get_manifest( $auth_port, Authorization => 'Bearer knarr-proxy-token-99' );
  is $resp->code, 200, 'with the proxy key: 200';
  my $body = $resp->decoded_content;
  ok eval { Langertha::Manifest->from_json($body) }, 'validates' or diag $@;
  my $data = $json->decode($body);
  is $data->{auth}, [ { id => 'api', type => 'api_key' } ], 'proxy_api_key reflected as api_key auth';
  is [ map { $_->{auth_ref} } @{ $data->{endpoints} } ], [ ('api') x 3 ], 'every endpoint references it';
  unlike $body, qr/knarr-proxy-token-99/, 'the proxy key itself is not published';
  no_leaks( $body, 'auth' );

  is get_manifest( $auth_port, 'x-api-key' => 'knarr-proxy-token-99' )->code, 200,
    'x-api-key works too';
}

# --- Public base URL ------------------------------------------------------
{
  my ( undef, $pub_port ) = start_knarr( config => surface_config(),
    public_url => 'https://knarr.example/base/' );
  my $data = $json->decode( get_manifest($pub_port)->decoded_content );
  is $data->{issuer}, 'https://knarr.example', 'issuer from public_url';
  is [ map { $_->{base_url} } @{ $data->{endpoints} } ], [
    'https://knarr.example/base/v1', 'https://knarr.example/base', 'https://knarr.example/base',
  ], 'endpoint URLs from public_url, never from the request';

  my $cfg = surface_config( public_url => 'https://from-config.example' );
  is $cfg->public_url, 'https://from-config.example', 'Config carries public_url';
}

{
  my $resp = get_manifest( $port, 'X-Forwarded-Proto' => 'https' );
  my $data = $json->decode( $resp->decoded_content );
  is $data->{endpoints}[0]{base_url}, "https://127.0.0.1:$port/v1",
    'X-Forwarded-Proto https switches the derived scheme';

  $resp = get_manifest( $port, 'X-Forwarded-Proto' => 'gopher' );
  $data = $json->decode( $resp->decoded_content );
  is $data->{endpoints}[0]{base_url}, "http://127.0.0.1:$port/v1",
    'an unknown X-Forwarded-Proto is ignored';

  $resp = get_manifest( $port, Host => 'evil.example/path?x=1' );
  is $resp->code, 400, 'a Host that is not a host[:port] is refused';
  like $json->decode( $resp->decoded_content )->{error}{message}, qr/Host/, 'JSON error names the Host';
}

# --- auto_discover results are part of the surface ------------------------
{
  my $config = Langertha::Knarr::Config->new( data => {
    auto_discover => 1,
    models => {
      gateway => {
        engine => 'TestManifestGateway', model => 'vendor-a/model-one',
        url => 'http://internal-upstream.example:9999/v1',
        api_key_env => 'KNARR_TEST_UPSTREAM_KEY',
      },
    },
  } );
  my ( undef, $disc_port ) = start_knarr( config => $config );
  my $body = get_manifest($disc_port)->decoded_content;
  ok eval { Langertha::Manifest->from_json($body) }, 'validates' or diag $@;
  my $data = $json->decode($body);
  is [ sort map { $_->{id} } grep { $_->{endpoint_ref} eq 'openai' } @{ $data->{models} } ],
    [ 'gateway', 'vendor-a/model-one', 'vendor-b/model-two' ],
    'configured alias plus discovered models';
  ok model_entry( $data, 'vendor-b/model-two', 'openai' )->{capabilities}{tools_native},
    'a discovered model carries its engine capabilities';
  unlike $body, qr/\Q$_\E/, "discovery: no '$_'"
    for qw( internal-upstream.example sk-upstream-secret-4711 KNARR_TEST_UPSTREAM_KEY TestManifestGateway );
}

# --- No router: listed ids, chat only; the cache follows the listing -----
{
  my $models = [ { id => 'agent-one', object => 'model' } ];
  my $plain = Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Code->new( code => sub { 'x' }, models => $models ),
    loop => $loop, port => 0,
  );
  $plain->start;
  my $plain_port = $plain->_server->read_handle->sockport;
  my $data = $json->decode( get_manifest($plain_port)->decoded_content );
  is model_entry( $data, 'agent-one', 'openai' )->{capabilities}, { chat => JSON::MaybeXS::true() },
    'without a router a model claims chat only';

  push @$models, { id => 'agent-two', object => 'model' };
  $data = $json->decode( get_manifest($plain_port)->decoded_content );
  ok model_entry( $data, 'agent-two', 'openai' ), 'a changed model listing is picked up (cache invalidated)';
}

# --- PSGI -----------------------------------------------------------------
SKIP: {
  skip 'Plack::Test not installed', 1
    unless eval { require Plack::Test; require HTTP::Request::Common; 1 };
  require Langertha::Knarr::PSGI;
  my $app  = Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app;
  my $test = Plack::Test->create($app);
  my $resp = $test->request( HTTP::Request::Common::GET('http://knarr.local:8080/.well-known/langertha.json') );
  is $resp->code, 200, 'PSGI: manifest served';
  my $body = $resp->decoded_content;
  ok eval { Langertha::Manifest->from_json($body) }, 'PSGI: validates' or diag $@;
  my $data = $json->decode($body);
  is $data->{endpoints}[0]{base_url}, 'http://knarr.local:8080/v1', 'PSGI: base URL from the request';
  is scalar( grep { $_->{endpoint_ref} eq 'openai' } @{ $data->{models} } ), 3, 'PSGI: same model surface';
  no_leaks( $body, 'PSGI' );
}

done_testing;
