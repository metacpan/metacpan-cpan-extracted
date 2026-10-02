#!/usr/bin/env perl
# ABSTRACT: probe_model_capabilities_f learns image_input from the provider's own model metadata (k270)

use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Path::Tiny qw( path );
use HTTP::Response;
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use Langertha::Request::SyncHTTP;
use Langertha::Manifest::Builder;
use Langertha::ModelProbe;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::Mistral;
use Langertha::Engine::Ollama;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Engine::LMStudio;
use Langertha::Engine::LMStudioOpenAI;
use Langertha::Engine::LMStudioAnthropic;
use Langertha::Engine::LlamaCpp;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::TSystems;
use Langertha::Engine::AKI;

# karr k270 (ADR 0032): gateways and self-hosted servers make no static
# image_input claim, because the model behind them is unknown to the client
# (ADR 0019 k266 Update). Their own metadata does know: OpenRouter's
# architecture.input_modalities, Mistral's capabilities.vision, LM Studio's
# capabilities.vision, Ollama's /api/show capabilities, llama.cpp's /props
# modalities.vision. An explicit, opt-in probe stores those facts per engine
# instance; engine_capabilities applies them after the static per-model table,
# and the provider's statement wins for the models it describes -- in both
# directions. Nothing probes implicitly: supports() must never do network I/O,
# and without a probe every answer is the static one. The fixtures are shaped
# from each provider's documented response (no live calls, no captures exist).

delete @ENV{ grep { /\ALANGERTHA_/ } keys %ENV };

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub fixture { path( 't/data', $_[0] )->slurp_raw }

sub json_response {
  my ( $body, $code ) = @_;
  $code //= 200;
  return HTTP::Response->new( $code, $code == 200 ? 'OK' : 'Not Found',
    [ 'Content-Type' => 'application/json' ], $body );
}

my %OLLAMA_SHOW = (
  'llava'    => 'ollama_show_llava.json',
  'llama3.3' => 'ollama_show_llama.json',
  'llama2'   => 'ollama_show_legacy.json',
  'llava:latest' => 'ollama_show_llava.json',
);

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($req) = @_;
  my $path   = $req->uri->path;
  my $method = $req->method;
  if ( $path eq '/or/api/v1/models' && $method eq 'GET' ) {
    return json_response( '{"error":{"message":"No auth credentials found","code":401}}', 401 )
      unless ( $req->header('Authorization') // '' ) eq 'Bearer or-key';
    return json_response( fixture('openrouter_models_probe.json') );
  }
  if ( $path eq '/tsi/v2/models' && $method eq 'GET' ) {
    return json_response( '{"detail":"Unauthorized"}', 401 )
      unless ( $req->header('Authorization') // '' ) eq 'Bearer tsi-key';
    return json_response( fixture('tsystems_models_probe.json') );
  }
  return json_response( fixture('mistral_models_probe.json') )
    if $path eq '/mistral/v1/models' && $method eq 'GET';
  return json_response( fixture('mistral_models.json') )
    if $path eq '/mistral-old/v1/models' && $method eq 'GET';
  return json_response( fixture('lmstudio_api_v1_models.json') )
    if $path eq '/lms/api/v1/models' && $method eq 'GET';
  # "Require Authentication" on: LM Studio documents only the Bearer header
  # for its native REST API (lmstudio.ai/docs/developer/core/authentication).
  if ( $path eq '/lms-auth/api/v1/models' && $method eq 'GET' ) {
    return json_response( '{"error":"Unauthorized"}', 401 )
      unless ( $req->header('Authorization') // '' ) eq 'Bearer lms-token';
    return json_response( fixture('lmstudio_api_v1_models.json') );
  }
  if ( $path eq '/ollama/api/show' && $method eq 'POST' ) {
    my $model = eval { $json->decode( $req->content )->{model} } // '';
    return json_response( fixture( $OLLAMA_SHOW{$model} ) ) if $OLLAMA_SHOW{$model};
    return json_response( '{"error":"llama runner process has terminated"}', 500 )
      if $model eq 'broken';
    return json_response( qq{{"error":"model '$model' not found"}}, 404 );
  }
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/html' ],
    '<html><body>Welcome to nginx!</body></html>' )
    if $path eq '/nonjson/api/v1/models';
  if ( $path =~ m{\A/llama-(vision|text|legacy)/props\z} && $method eq 'GET' ) {
    return json_response( fixture("llamacpp_props_$1.json") );
  }
  return json_response( '{"error":"no route"}', 404 );
} );
my $base = $server->url;

# A client that dies on any request: proves a code path sends nothing.
{
  package My::ForbiddenHTTP;
  sub do_request { die "no request may be sent\n" }
}
my $forbidden = bless {}, 'My::ForbiddenHTTP';

sub sync_http { Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 10 ) ) }

sub claims { $_[0]->supports('image_input') ? 1 : 0 }

sub error_of {
  my ($code) = @_;
  return eval { $code->(); 1 } ? '' : "$@";
}

# ---------------------------------------------------------------------------
subtest 'no probe: static answers, no request, empty store' => sub {
  for my $engine (
    Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'openai/gpt-4o', _async_http => $forbidden ),
    Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'llava', _async_http => $forbidden ),
    Langertha::Engine::LlamaCpp->new( url => 'http://h/v1', _async_http => $forbidden ),
  ) {
    is claims($engine), 0, ref($engine) . ': no static claim';
    is_deeply $engine->learned_model_capabilities, {}, ref($engine) . ': nothing learned';
  }
  my $mistral = Langertha::Engine::Mistral->new( api_key => 'k', _async_http => $forbidden );
  is claims($mistral), 1, 'Mistral default model keeps its static claim';

  # No default model and none configured: supports() answers instead of
  # croaking on chat_model (the table walk sees '').
  my $router = Langertha::Engine::OpenRouter->new( api_key => 'k', _async_http => $forbidden );
  is claims($router), 0, 'OpenRouter without a model: no claim, no croak';
};

subtest 'engines without a probe resolve to {} without a request' => sub {
  for my $engine (
    Langertha::Engine::OpenAI->new( api_key => 'k', _async_http => $forbidden ),
    Langertha::Engine::Anthropic->new( api_key => 'k', _async_http => $forbidden ),
  ) {
    is $engine->model_metadata_format, undef, ref($engine) . ': no metadata format';
    is_deeply $engine->probe_model_capabilities, {}, ref($engine) . ': empty result';
    is_deeply $engine->learned_model_capabilities, {}, ref($engine) . ': store stays empty';
  }
  my $ollama = Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', _async_http => $forbidden );
  is_deeply $ollama->probe_model_capabilities, {},
    'per-model format with no model: no request, empty result';
};

# ---------------------------------------------------------------------------
# Per engine, on the default backend and on the sync LWP shim (ADR 0027 parity).
for my $backend ( [ default => sub { () } ], [ sync => sub { ( _async_http => sync_http() ) } ] ) {
  my ( $label, $http ) = @$backend;

  subtest "OpenRouter ($label): input_modalities, static no-claim + probe yes -> yes" => sub {
    my $e = Langertha::Engine::OpenRouter->new(
      url => "$base/or/api/v1", api_key => 'or-key', model => 'openai/gpt-4o', $http->() );
    is claims($e), 0, 'before the probe: no claim';
    my $learned = $e->probe_model_capabilities;
    is_deeply $learned, {
      'openai/gpt-4o'        => { image_input => 1 },
      'deepseek/deepseek-r1' => { image_input => 0 },
    }, 'every model in /models is learned (id and canonical_slug coincide here)';
    is claims($e), 1, 'after the probe: the model sees images';
    my $r1 = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'deepseek/deepseek-r1' );
    is claims($r1), 0, 'the store is per instance: a fresh engine knows nothing';
  };

  subtest "Mistral ($label): capabilities.vision per id and alias" => sub {
    my $e = Langertha::Engine::Mistral->new(
      url => "$base/mistral", api_key => 'k', model => 'mistral-large-pixtral-2411', $http->() );
    is claims($e), 0, 'static table makes no claim for this id';
    my $learned = $e->probe_model_capabilities;
    is $learned->{'mistral-small-latest'}{image_input}, 1, 'alias learned';
    is $learned->{'mistral-small-2603'}{image_input},   1, 'id learned';
    is $learned->{'codestral-latest'}{image_input},     0, 'text-only alias learned as 0';
    is claims($e), 1, 'static no-claim + probe yes -> yes';
  };

  # k365: the Anthropic face is the same LM Studio server; its url is the
  # server root (it appends /v1/messages), so the native /api/v1/models sits
  # directly under it.
  subtest "LMStudio native + OpenAI + Anthropic face ($label): /api/v1/models capabilities.vision" => sub {
    for my $e (
      Langertha::Engine::LMStudio->new( url => "$base/lms", model => 'google/gemma-4-26b-a4b', $http->() ),
      Langertha::Engine::LMStudioOpenAI->new( url => "$base/lms/v1", model => 'google/gemma-4-26b-a4b', $http->() ),
      Langertha::Engine::LMStudioAnthropic->new( url => "$base/lms", model => 'google/gemma-4-26b-a4b', $http->() ),
      Langertha::Engine::LMStudioAnthropic->new( url => "$base/lms/", model => 'google/gemma-4-26b-a4b', $http->() ),
    ) {
      is $e->model_metadata_url, "$base/lms/api/v1/models", ref($e) . ': native models URL';
      is claims($e), 0, ref($e) . ': no claim before the probe';
      my $learned = $e->probe_model_capabilities;
      is_deeply $learned, {
        'google/gemma-4-26b-a4b' => { image_input => 1 },
        'deepseek-r1'            => { image_input => 0 },
      }, ref($e) . ': llm entries learned, the embedding entry (no capabilities) gives no fact';
      is claims($e), 1, ref($e) . ': vision model claims after the probe';
    }
  };

  subtest "Ollama native + OllamaOpenAI ($label): /api/show capabilities" => sub {
    for my $e (
      Langertha::Engine::Ollama->new( url => "$base/ollama", model => 'llava', $http->() ),
      Langertha::Engine::OllamaOpenAI->new( url => "$base/ollama/v1", model => 'llava', $http->() ),
    ) {
      is claims($e), 0, ref($e) . ': no claim before the probe';
      is_deeply $e->probe_model_capabilities, { llava => { image_input => 1 } },
        ref($e) . ': chat_model probed by default';
      is claims($e), 1, ref($e) . ': llava sees images';
      is_deeply $e->probe_model_capabilities( models => [qw( llama3.3 llama2 )] ),
        { 'llama3.3' => { image_input => 0 } },
        ref($e) . ': one request per model; a server without capabilities gives no fact';
      is_deeply $e->learned_model_capabilities, {
        llava => { image_input => 1 }, 'llama3.3' => { image_input => 0 },
      }, ref($e) . ': facts merge into the store';
    }
  };

  # karr k281: TSystems AIFS documents GET /v2/models with a nullable
  # data[].meta_data.input_modalities string array in its public OpenAPI
  # (llm-server.llmhub.t-systems.net/openapi.json). DOCS ONLY: no key exists,
  # so the fixture is shaped from that schema, not captured. The static
  # table (catch-all no-claim + documented vision rows) stays the answer
  # for every model the document does not describe.
  subtest "TSystems ($label): /v2/models meta_data.input_modalities" => sub {
    my $e = Langertha::Engine::TSystems->new(
      url => "$base/tsi/v2", api_key => 'tsi-key', model => 'Llama-3.3-70B-Instruct', $http->() );
    is $e->model_metadata_format, 'tsystems', 'format tag';
    is $e->model_metadata_url, "$base/tsi/v2/models", 'the /v2 models list of the engine url';
    is +Langertha::Engine::TSystems->new( api_key => 'k' )->model_metadata_url,
      'https://llm-server.llmhub.t-systems.net/v2/models', 'default: the documented GET /v2/models';
    is claims($e), 0, 'static catch-all: no claim for Llama 3.3';
    my $learned = $e->probe_model_capabilities;
    is_deeply $learned, {
      'gemma-4-31b-it'      => { image_input => 1 },
      'gpt-oss-120b'        => { image_input => 0 },
      'Qwen3.6-35B-A3B-FP8' => { image_input => 1 },
    }, 'image matched case-insensitively; null input_modalities, empty or null meta_data give no fact';
    is claims($e), 0, 'a model with null input_modalities keeps its static answer';

    my $gemma = Langertha::Engine::TSystems->new( api_key => 'k', model => 'gemma-4-31b-it', _async_http => $forbidden );
    $gemma->import_learned_capabilities($learned);
    is claims($gemma), 1, 'gemma-4 claims from the learned fact';
    my $oss = Langertha::Engine::TSystems->new( api_key => 'k', model => 'gpt-oss-120b', _async_http => $forbidden );
    $oss->import_learned_capabilities($learned);
    is claims($oss), 0, 'gpt-oss-120b learned as text-only';
    my $static_yes = Langertha::Engine::TSystems->new( api_key => 'k', model => 'gemma-4-31b-it',
      _async_http => $forbidden );
    is claims($static_yes), 1, 'unprobed: the static gemma-4 row already claims';
    $static_yes->import_learned_capabilities( { 'gemma-4-31b-it' => { image_input => 0 } } );
    is claims($static_yes), 0, 'a provider no beats the static yes';

    is_deeply $e->probe_model_capabilities( models => 'all' ), $learned, "models => 'all' reads the same catalogue";
    my $bad = Langertha::Engine::TSystems->new( url => "$base/tsi/v2", api_key => 'wrong', $http->() );
    like error_of( sub { $bad->probe_model_capabilities } ), qr/Langertha::Engine::TSystems model metadata probe failed: 401/,
      'the Bearer key is sent (a wrong key is refused)';
  };

  subtest "LlamaCpp ($label): /props modalities.vision" => sub {
    my $vision = Langertha::Engine::LlamaCpp->new( url => "$base/llama-vision/v1", $http->() );
    is claims($vision), 0, 'no claim before the probe';
    is_deeply $vision->probe_model_capabilities, { default => { image_input => 1 } },
      'the one loaded model is keyed by the id asked about (chat_model)';
    is claims($vision), 1, 'vision server claims after the probe';

    my $text = Langertha::Engine::LlamaCpp->new( url => "$base/llama-text/v1", model => 'llama', $http->() );
    is_deeply $text->probe_model_capabilities, { llama => { image_input => 0 } }, 'text server learned as 0';
    is claims($text), 0, 'text server stays without claim';

    my $legacy = Langertha::Engine::LlamaCpp->new( url => "$base/llama-legacy/v1", $http->() );
    is_deeply $legacy->probe_model_capabilities, {}, 'a server without modalities gives no fact';
  };
}

# k365: LMStudioAnthropic sends its token as x-api-key (what /v1/messages
# takes), but the native /api/v1/models documents only Bearer. With "Require
# Authentication" on, the probe must carry the token as Bearer or it 401s;
# the chat wire keeps its x-api-key header and gains nothing.
subtest 'LMStudioAnthropic: the probe carries the token as Bearer, chat does not' => sub {
  my $e = Langertha::Engine::LMStudioAnthropic->new(
    url => "$base/lms-auth", api_key => 'lms-token', model => 'google/gemma-4-26b-a4b' );
  is $e->probe_model_capabilities->{'google/gemma-4-26b-a4b'}{image_input}, 1,
    'auth-enabled server answers the probe';
  is claims($e), 1, 'vision model claims after the probe';

  my $chat = $e->chat('Hi');
  is $chat->header('x-api-key'), 'lms-token', 'chat request keeps x-api-key';
  is $chat->header('Authorization'), undef, 'chat request gets no Bearer header';
};

# ---------------------------------------------------------------------------
subtest 'precedence: probe is authoritative for the models it reports' => sub {
  my $e = Langertha::Engine::Mistral->new(
    url => "$base/mistral-old", api_key => 'k', model => 'mistral-small-latest' );
  is claims($e), 1, 'static table claims mistral-small-latest';
  $e->probe_model_capabilities;
  is claims($e), 0, 'static yes + probe no -> no';
  $e->clear_learned_model_capabilities;
  is claims($e), 1, 'clear_learned_model_capabilities restores the static answer';

  my $unreported = Langertha::Engine::OpenRouter->new(
    url => "$base/or/api/v1", api_key => 'or-key', model => 'x/not-listed' );
  $unreported->probe_model_capabilities;
  is claims($unreported), 0, 'a model the document does not describe keeps its static answer';
  my $static_yes = Langertha::Engine::Mistral->new(
    url => "$base/mistral", api_key => 'k', model => 'pixtral-12b-2409' );
  $static_yes->probe_model_capabilities;
  is claims($static_yes), 1, 'static yes on an unreported model is kept';
};

subtest 'a learned yes cannot open a closed wire' => sub {
  {
    package My::ClosedRouter;
    use Moose;
    extends 'Langertha::Engine::OpenRouter';
    around engine_capabilities => sub {
      my ( $orig, $self, @rest ) = @_;
      my $caps = $self->$orig(@rest);
      delete $caps->{image_input};    # layer 2: this endpoint never carries images
      return $caps;
    };
    __PACKAGE__->meta->make_immutable;
  }
  {
    package My::AKIWithProbe;    # AKI native does not compose Role::ImageInput (layer 1)
    use Moose;
    extends 'Langertha::Engine::AKI';
    sub model_metadata_format { 'openrouter' }
    sub model_metadata_url    { "$base/or/api/v1/models" }
    around generate_http_request => sub {
      my ( $orig, $self, @args ) = @_;
      my $req = $self->$orig(@args);
      $req->header( Authorization => 'Bearer or-key' );
      return $req;
    };
    __PACKAGE__->meta->make_immutable;
  }
  my $closed = My::ClosedRouter->new( url => "$base/or/api/v1", api_key => 'or-key', model => 'openai/gpt-4o' );
  $closed->probe_model_capabilities;
  is $closed->learned_model_capabilities->{'openai/gpt-4o'}{image_input}, 1, 'the fact is learned';
  is claims($closed), 0, 'layer 2 still has the last word';

  my $aki = My::AKIWithProbe->new( api_key => 'k', model => 'openai/gpt-4o' );
  $aki->probe_model_capabilities;
  is claims($aki), 0, 'a learned yes does not assert a flag the composed roles do not grant';
};

subtest 'errors fail loud' => sub {
  my $e = Langertha::Engine::Ollama->new( url => "$base/ollama", model => 'broken' );
  my $f = $e->probe_model_capabilities_f( models => [qw( llava broken )] );
  $f->await;
  ok $f->is_failed, 'a 500 fails the future';
  like scalar $f->failure, qr/Langertha::Engine::Ollama model metadata probe failed: 500/,
    'the failure names the engine and the status';
  like scalar $f->failure, qr/llama runner process has terminated/, 'and carries the provider body';
  is_deeply $e->learned_model_capabilities, {}, 'nothing from the failed call is stored';

  my $html = Langertha::Engine::OpenRouter->new( url => "$base/nonjson/api/v1", api_key => 'k', model => 'm' );
  like error_of( sub { $html->probe_model_capabilities } ),
    qr{\ALangertha::Engine::OpenRouter model metadata probe: response from /nonjson/api/v1/models is not JSON},
    'a 200 that is not JSON fails with an engine-named error, not a decoder message';

  my $bad = Langertha::Engine::OpenRouter->new( url => "$base/or/api/v1", api_key => 'wrong', model => 'm' );
  like error_of( sub { $bad->probe_model_capabilities } ), qr/401/,
    'auth header is sent (a wrong key is refused)';

  like error_of( sub { $e->probe_model_capabilities( models => 'llava' ) } ), qr/must be an ArrayRef/,
    'models must be an ArrayRef';
};

subtest 'supports() leaves the caller $@ alone' => sub {
  # A model-less engine croaks inside chat_model; the capability walk catches
  # that croak and must not leak it into the caller's $@ (review of k270).
  my $router = Langertha::Engine::OpenRouter->new( api_key => 'k', _async_http => $forbidden );
  $@ = "caller's own error\n";    ## no critic (Variables::RequireLocalizedPunctuationVars)
  $router->supports('image_input');
  is $@, "caller's own error\n", '$@ unchanged after supports()';
  $@ = '';
  $router->supports('image_input');
  is $@, '', 'an empty $@ stays empty';
};

subtest 'Ollama: a model the server does not have gives no fact, the others are kept' => sub {
  my $e = Langertha::Engine::Ollama->new( url => "$base/ollama", model => 'llava' );
  is_deeply $e->probe_model_capabilities( models => [qw( llava missing llama3.3 )] ), {
    llava => { image_input => 1 }, 'llama3.3' => { image_input => 0 },
  }, '404 for "missing" is skipped, llava and llama3.3 are learned';
  is claims($e), 1, 'the learned fact applies';
};

subtest 'only non-empty plain strings are model ids' => sub {
  my $e = Langertha::Engine::Ollama->new( url => "$base/ollama", model => 'llava' );
  is_deeply $e->probe_model_capabilities( models => [ {}, ['llava'], '', undef, 'llava' ] ),
    { llava => { image_input => 1 } }, 'references, empty and undef ids are ignored (no request for them)';
  is_deeply [ sort keys %{ $e->learned_model_capabilities } ], ['llava'], 'no odd key in the store';
  my $facts = Langertha::ModelProbe->extract( openrouter => { data => [
    { id => { not => 'a string' }, architecture => { input_modalities => ['image'] } },
    { id => '', canonical_slug => 'x/y', architecture => { input_modalities => ['text'] } },
  ] }, [] );
  is_deeply $facts, { 'x/y' => { image_input => 0 } }, 'a non-string id in the document is not a key';
};

subtest 'tolerant id matching: Ollama :latest, OpenRouter variants' => sub {
  my $tagged = Langertha::Engine::Ollama->new( url => "$base/ollama", model => 'llava:latest' );
  $tagged->probe_model_capabilities( models => ['llava'] );
  is claims($tagged), 1, 'llava:latest finds a fact learned as llava';

  my $bare = Langertha::Engine::OllamaOpenAI->new( url => "$base/ollama/v1", model => 'llava' );
  $bare->probe_model_capabilities( models => ['llava:latest'] );
  is claims($bare), 1, 'llava finds a fact learned as llava:latest';

  my $other_tag = Langertha::Engine::Ollama->new( url => "$base/ollama", model => 'llava:13b' );
  $other_tag->probe_model_capabilities( models => ['llava'] );
  is claims($other_tag), 0, 'another tag is another model: no match';

  for my $case ( [ 'openai/gpt-4o:online' => 1 ], [ 'deepseek/deepseek-r1:free' => 0 ] ) {
    my ( $model, $want ) = @$case;
    my $e = Langertha::Engine::OpenRouter->new( url => "$base/or/api/v1", api_key => 'or-key', model => $model );
    $e->probe_model_capabilities;
    is claims($e), $want, "$model falls back to its base id";
  }

  my $probe = 'Langertha::ModelProbe';
  is_deeply [ $probe->lookup_ids( ollama => 'llava' ) ], [ 'llava', 'llava:latest' ], 'ollama: bare adds :latest';
  is_deeply [ $probe->lookup_ids( ollama => 'llava:latest' ) ], [ 'llava:latest', 'llava' ], 'ollama: :latest adds bare';
  is_deeply [ $probe->lookup_ids( openrouter => 'openai/gpt-4o:nitro' ) ],
    [ 'openai/gpt-4o:nitro', 'openai/gpt-4o' ], 'openrouter: exact variant first, then base';
  is_deeply [ $probe->lookup_ids( mistral => 'mistral-small-latest' ) ], ['mistral-small-latest'],
    'other formats match exactly';

  my $exact = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'openai/gpt-4o:free' );
  $exact->_set_learned_model_capabilities( {
    'openai/gpt-4o:free' => { image_input => 0 }, 'openai/gpt-4o' => { image_input => 1 },
  } );
  is claims($exact), 0, 'a listed variant wins over its base id';
};

subtest 'a probe on a clone does not write into its source' => sub {
  my $e = Langertha::Engine::OpenRouter->new( url => "$base/or/api/v1", api_key => 'or-key', model => 'openai/gpt-4o' );
  my $clone = $e->meta->clone_object($e);
  $clone->probe_model_capabilities;
  is claims($clone), 1, 'the clone learned';
  is claims($e), 0, 'the source did not';
};

subtest 'Manifest::Builder publishes probed facts' => sub {
  my $e = Langertha::Engine::OpenRouter->new( url => "$base/or/api/v1", api_key => 'or-key', model => 'openai/gpt-4o' );
  my @models = ( 'openai/gpt-4o', 'deepseek/deepseek-r1' );
  my $before = Langertha::Manifest::Builder->new->add_engine( $e, models => \@models )->manifest;
  ok !( grep { $_->supports('image_input') } @{ $before->models } ), 'unprobed: no model claims image_input';
  $e->probe_model_capabilities;
  my $after = Langertha::Manifest::Builder->new->add_engine( $e, models => \@models )->manifest;
  my %claim = map { $_->id => ( $_->supports('image_input') ? 1 : 0 ) } @{ $after->models };
  is_deeply \%claim, { 'openai/gpt-4o' => 1, 'deepseek/deepseek-r1' => 0 },
    'probed: each model entry carries its learned fact';
};

# ---------------------------------------------------------------------------
# karr k282 (knarr k37): the store is per instance, so a gateway holding one
# engine instance per discovered model (300 OpenRouter slugs) would fetch the
# same catalogue 300 times. One probe with models => 'all' learns the whole
# document; import_learned_capabilities hands it to the other instances with
# no request of their own. No hidden I/O, no global cache: the caller shares.
subtest "one probe fills many instances (models => 'all' + import)" => sub {
  my $prober = Langertha::Engine::OpenRouter->new( url => "$base/or/api/v1", api_key => 'or-key' );
  my $learned = $prober->probe_model_capabilities( models => 'all' );
  is_deeply $learned, {
    'openai/gpt-4o'        => { image_input => 1 },
    'deepseek/deepseek-r1' => { image_input => 0 },
  }, 'a model-less engine learns the whole catalogue from one request';
  is_deeply $prober->learned_model_capabilities, $learned, 'the result is exactly what was stored';
  $learned->{'openai/gpt-4o'}{image_input} = 0;
  is $prober->learned_model_capabilities->{'openai/gpt-4o'}{image_input}, 1,
    'the result is the caller\'s copy, not the store';
  $learned->{'openai/gpt-4o'}{image_input} = 1;

  my %want = ( 'openai/gpt-4o' => 1, 'deepseek/deepseek-r1' => 0, 'openai/gpt-4o:online' => 1 );
  for my $model ( sort keys %want ) {
    my $e = Langertha::Engine::OpenRouter->new( api_key => 'k', model => $model, _async_http => $forbidden );
    is claims($e), 0, "$model: no claim before the import";
    is_deeply $e->import_learned_capabilities($learned), $learned, "$model: import returns what it merged";
    is claims($e), $want{$model}, "$model: answers from the imported fact without a request";
  }

  my $copy = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'openai/gpt-4o', _async_http => $forbidden );
  $copy->import_learned_capabilities( $prober->learned_model_capabilities );
  is claims($copy), 1, 'learned_model_capabilities of one instance imports into another';

  my $mistral = Langertha::Engine::Mistral->new( url => "$base/mistral-old", api_key => 'k', model => 'mistral-small-latest' );
  is claims($mistral), 1, 'static yes before the import';
  $mistral->import_learned_capabilities( { 'mistral-small-latest' => { image_input => 0 } } );
  is claims($mistral), 0, 'an imported fact is authoritative like a probed one (static yes + learned no)';

  my $closed = My::ClosedRouter->new( api_key => 'k', model => 'openai/gpt-4o', _async_http => $forbidden );
  $closed->import_learned_capabilities($learned);
  is claims($closed), 0, 'an imported yes cannot open a wire layer 2 closes';
};

subtest "models => 'all' needs a catalogue document" => sub {
  for my $case (
    [ 'Langertha::Engine::Mistral', url => "$base/mistral", api_key => 'k' ],
    [ 'Langertha::Engine::LMStudio', url => "$base/lms" ],
  ) {
    my ( $class, @args ) = @$case;
    my $learned = $class->new(@args)->probe_model_capabilities( models => 'all' );
    ok scalar( keys %$learned ) >= 2, "$class: every model of the document is learned";
  }
  for my $e (
    Langertha::Engine::Ollama->new( url => 'http://h', model => 'llava', _async_http => $forbidden ),
    Langertha::Engine::LlamaCpp->new( url => 'http://h/v1', _async_http => $forbidden ),
  ) {
    like error_of( sub { $e->probe_model_capabilities( models => 'all' ) } ),
      qr/\A\Q@{[ ref $e ]}\E: probe_model_capabilities_f models => 'all' needs a catalogue document; model_metadata_format '\w+' does not name its models/,
      ref($e) . ': croaks before any request';
  }
  my $o = 'Langertha::ModelProbe';
  is_deeply { map { $_ => $o->is_catalogue($_) } qw( openrouter mistral lmstudio tsystems ollama llamacpp ) },
    { openrouter => 1, mistral => 1, lmstudio => 1, tsystems => 1, ollama => 0, llamacpp => 0 },
    'is_catalogue per format';
  my $e = Langertha::Engine::OpenAI->new( api_key => 'k', _async_http => $forbidden );
  is_deeply $e->probe_model_capabilities( models => 'all' ), {}, 'an engine without a probe still resolves to {}';
};

subtest 'import_learned_capabilities validates like a probe' => sub {
  my $e = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'a/b', _async_http => $forbidden );
  for my $bad ( undef, 'a/b', [ 'a/b' ] ) {
    like error_of( sub { $e->import_learned_capabilities($bad) } ),
      qr/\ALangertha::Engine::OpenRouter: import_learned_capabilities needs a HashRef/,
      'a non-HashRef croaks (' . ( defined $bad ? ref $bad || $bad : 'undef' ) . ')';
  }
  my $merged = $e->import_learned_capabilities( {
    ''    => { image_input => 1 },                             # empty id
    'x/y' => [ 'image_input' ],                                # facts not a HashRef
    'a/b' => { image_input => 'yes', tools_native => 0 },      # not probe-learnable: ignored
    'c/d' => { image_input => undef },                         # undef is no fact
    'e/f' => { image_input => {} },                            # an unblessed ref is no fact
    'g/h' => { image_input => JSON::MaybeXS::false() },        # a JSON boolean works
    'i/j' => { image_input => JSON::MaybeXS::true() },
  } );
  is_deeply $merged, {
    'a/b' => { image_input => 1 }, 'g/h' => { image_input => 0 }, 'i/j' => { image_input => 1 },
  }, 'only plain-string ids, allowlisted capabilities and scalar values, normalized to 0|1';
  is_deeply $e->learned_model_capabilities, $merged, 'the store holds exactly the merged facts';
  is claims($e), 1, 'the imported fact applies';
  ok $e->supports('tools_native'),
    'a capability a probe may not learn (tools_native => 0) does not clear that flag';

  $e->import_learned_capabilities( { 'a/b' => { image_input => 0 } } );
  is claims($e), 0, 'a later import for the same model replaces the fact';
  is_deeply $e->import_learned_capabilities( {} ), {}, 'an empty map merges nothing';
  is $e->learned_model_capabilities->{'g/h'}{image_input}, 0, 'and keeps what was there';

  my $src = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'a/b', _async_http => $forbidden );
  my $clone = $src->meta->clone_object($src);
  $clone->import_learned_capabilities( { 'a/b' => { image_input => 1 } } );
  is claims($clone), 1, 'the clone imported';
  is claims($src), 0, 'an import on a clone does not write into its source';
};

subtest 'ModelProbe door' => sub {
  is_deeply [ Langertha::ModelProbe->probed_capabilities ], ['image_input'], 'only image_input is learned';
  like error_of( sub { Langertha::ModelProbe->extract( 'nope', {}, [] ) } ),
    qr/unknown model_metadata_format 'nope'/, 'unknown format croaks';
  my $probe = 'Langertha::ModelProbe';
  is_deeply( $probe->extract( openrouter => [], [] ), {}, 'unexpected shape: no facts' );
  is( $probe->server_root_url('http://h:11434/v1'),  'http://h:11434',  'strips /v1' );
  is( $probe->server_root_url('http://h:11434/v1/'), 'http://h:11434',  'strips /v1/' );
  is( $probe->server_root_url('http://h:1234/x/v1'), 'http://h:1234/x', 'keeps a path prefix' );
  my $mistral = Langertha::ModelProbe->extract( mistral => { data => [
    { id => 'other',  aliases => ['shared'], capabilities => { vision => JSON::MaybeXS::false() } },
    { id => 'shared', capabilities => { vision => JSON::MaybeXS::true() } },
  ] }, [] );
  is $mistral->{shared}{image_input}, 1, "an entry's own id wins over another entry's alias";
};

done_testing;
