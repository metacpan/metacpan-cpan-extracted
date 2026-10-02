use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

BEGIN {
  package LangerthaX::Engine::TestKnarr;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub simple_chat { return 'ok' }
  $INC{'LangerthaX/Engine/TestKnarr.pm'} = __FILE__;

  # Offline gateway stand-in for auto_discover: list_models without a network.
  package LangerthaX::Engine::TestKnarrGateway;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub chat_model { $_[0]{model} }
  sub list_models { [ 'vendor-a/model-one', 'vendor-b/model-two' ] }
  $INC{'LangerthaX/Engine/TestKnarrGateway.pm'} = __FILE__;

  # Offline engine that answers chat_f: the upstream reports `answered_as`
  # as the model that answered (undef = the upstream names none); chat_model
  # is the configured model, else `engine_default` (undef = none known).
  package LangerthaX::Engine::TestKnarrAnswering;
  use Future;
  use Langertha::Response;
  our ($answered_as, $engine_default);
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub chat_model { $_[0]{model} // $engine_default }
  sub chat_f {
    my ($self) = @_;
    return Future->done( Langertha::Response->new(
      content => 'answer', raw => {},
      ( defined $answered_as ? ( model => $answered_as ) : () ),
    ) );
  }
  $INC{'LangerthaX/Engine/TestKnarrAnswering.pm'} = __FILE__;

  # Offline gateway whose model list depends on its url, so each gateway
  # instance discovers something the other one does not.
  package LangerthaX::Engine::TestKnarrGatewayByUrl;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub chat_model { $_[0]{model} }
  sub list_models { my ($host) = $_[0]{url} =~ m{//([^/]+)}; [ "$host/only-here" ] }
  $INC{'LangerthaX/Engine/TestKnarrGatewayByUrl.pm'} = __FILE__;
}
use JSON::PP ();

use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Request;
use Langertha::Knarr::Session;

# Test: resolve configured model
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  local-test:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
    model: llama3.2
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my ($engine, $model) = $router->resolve('local-test');
  ok $engine, 'engine resolved';
  isa_ok $engine, 'Langertha::Engine::OllamaOpenAI';
  is $model, 'llama3.2', 'correct model name';
}

# Test: resolve with default engine
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models: {}
default:
  engine: OllamaOpenAI
  url: http://test.invalid:11434/v1
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my ($engine, $model) = $router->resolve('any-model');
  ok $engine, 'default engine resolved';
  isa_ok $engine, 'Langertha::Engine::OllamaOpenAI';
  is $model, 'any-model', 'model name passed through';
}

# Test: engine caching
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
    model: test
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my ($engine1) = $router->resolve('test');
  my ($engine2) = $router->resolve('test');
  is "$engine1", "$engine2", 'same engine instance returned (cached)';
}

# Test: unknown model without default
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  known:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  eval { $router->resolve('unknown') };
  like $@, qr/not configured/, 'unknown model without default croaks';
}

# Test: list_models
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  model-a:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
    model: llama3.2
  model-b:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
    model: qwen2.5
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my $models = $router->list_models;
  is scalar @$models, 2, 'two models listed';
  is $models->[0]{source}, 'configured', 'source is configured';
}

# Test: no model specified
{
  my $config = Langertha::Knarr::Config->new;
  my $router = Langertha::Knarr::Router->new(config => $config);

  eval { $router->resolve(undef) };
  like $@, qr/No model specified/, 'undef model croaks';

  eval { $router->resolve('') };
  like $@, qr/No model specified/, 'empty model croaks';
}

# Test: resolve custom LangerthaX engine
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  custom:
    engine: TestKnarr
    model: custom-model
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my ($engine, $model) = $router->resolve('custom');
  ok $engine, 'custom engine resolved';
  isa_ok $engine, 'LangerthaX::Engine::TestKnarr';
  is $model, 'custom-model', 'custom model resolved';
}

# k20: the engine cache must be keyed per model. Two models on one
# engine/url/key must not share the first model's instance: chat_model is
# read-only, so a shared instance sends the first model upstream while
# Handler::Router relabels the answer with the requested one, and every
# model-scoped decision in core (capability corrections, exclusions,
# Reasoning::Profile) is evaluated for the wrong model.
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  model-a:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
    model: llama3.2
  model-b:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
    model: qwen2.5
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my ($engine_a, $model_a) = $router->resolve('model-a');
  my ($engine_b, $model_b) = $router->resolve('model-b');
  is $model_a, 'llama3.2', 'model-a resolves to llama3.2';
  is $model_b, 'qwen2.5',  'model-b resolves to qwen2.5';
  isnt "$engine_a", "$engine_b", 'two models on one engine/url get two instances';
  is $engine_a->chat_model, 'llama3.2', 'model-a engine carries its own chat_model';
  is $engine_b->chat_model, 'qwen2.5',  'model-b engine carries its own chat_model';

  my %upstream;
  for my $pair ([a => $engine_a], [b => $engine_b]) {
    my $http = $pair->[1]->chat({ role => 'user', content => 'hi' });
    $upstream{$pair->[0]} = JSON::PP::decode_json($http->content)->{model};
  }
  is $upstream{a}, 'llama3.2', 'upstream request for model-a names llama3.2';
  is $upstream{b}, 'qwen2.5',  'upstream request for model-b names qwen2.5';

  my ($engine_a2) = $router->resolve('model-a');
  is "$engine_a2", "$engine_a", 'same model still reuses its cached instance';
}

# k20: default engine — every unconfigured model name gets its own instance.
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models: {}
default:
  engine: OllamaOpenAI
  url: http://test.invalid:11434/v1
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my ($engine_x) = $router->resolve('model-x');
  my ($engine_y) = $router->resolve('model-y');
  is $engine_x->chat_model, 'model-x', 'default engine for model-x uses model-x';
  is $engine_y->chat_model, 'model-y', 'default engine for model-y uses model-y';
}

# k20: auto_discover on a gateway — discovered slugs must not collapse onto
# the configured model's instance.
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
auto_discover: 1
models:
  gw:
    engine: TestKnarrGateway
    url: http://test.invalid/v1
    model: vendor-a/model-one
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my ($engine_gw)  = $router->resolve('gw');
  my ($engine_one, $model_one) = $router->resolve('vendor-a/model-one');
  my ($engine_two, $model_two) = $router->resolve('vendor-b/model-two');
  is $model_two, 'vendor-b/model-two', 'discovered slug resolves to itself';
  is $engine_gw->chat_model,  'vendor-a/model-one', 'configured gateway model keeps its chat_model';
  is $engine_two->chat_model, 'vendor-b/model-two', 'discovered slug gets an engine with its own chat_model';
  isnt "$engine_two", "$engine_gw", 'discovered slug does not reuse the configured instance';
}

# k22: a model config without `model:` builds the engine without a model, so
# the provider default answers. Relabeling that answer with the alias tells
# the client a model answered that did not exist upstream; the client must
# see the model that actually answered. A config with `model:` keeps the k20
# relabel to the configured model.
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  alias-only:
    engine: TestKnarrAnswering
    url: http://test.invalid/v1
  pinned:
    engine: TestKnarrAnswering
    url: http://test.invalid/v1
    model: pinned-upstream
YAML
  close $fh;

  my $config  = Langertha::Knarr::Config->new(file => $file);
  my $router  = Langertha::Knarr::Router->new(config => $config);
  my $handler = Langertha::Knarr::Handler::Router->new(router => $router);
  my $session = Langertha::Knarr::Session->new(id => 's');
  my $answer_model = sub {
    my ($name) = @_;
    my $req = Langertha::Knarr::Request->new(
      protocol => 'openai', model => $name,
      messages => [ { role => 'user', content => 'hi' } ],
    );
    return $handler->handle_chat_f($session, $req)->get->model;
  };

  local $LangerthaX::Engine::TestKnarrAnswering::answered_as    = 'provider-default-7b';
  local $LangerthaX::Engine::TestKnarrAnswering::engine_default = 'engine-default';
  is $answer_model->('alias-only'), 'provider-default-7b',
    'alias-only config reports the model the upstream says answered, not the alias';
  is $answer_model->('pinned'), 'pinned-upstream',
    'config with model: keeps the relabel to the configured model';

  $LangerthaX::Engine::TestKnarrAnswering::answered_as = undef;
  is $answer_model->('alias-only'), 'engine-default',
    'alias-only config without an upstream model reports the engine chat_model';

  $LangerthaX::Engine::TestKnarrAnswering::engine_default = undef;
  is $answer_model->('alias-only'), undef,
    'alias-only config with no known model is not relabeled with the alias';
}

# k23: discovery runs once per endpoint (engine, url, api key variable), not
# once per engine class. Two gateways of the same class on different urls
# serve different models; deduping by class hid the second gateway's models.
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
auto_discover: 1
models:
  gw-a:
    engine: TestKnarrGatewayByUrl
    url: http://gw-a.invalid/v1
    model: seed-a
  gw-b:
    engine: TestKnarrGatewayByUrl
    url: http://gw-b.invalid/v1
    model: seed-b
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $router = Langertha::Knarr::Router->new(config => $config);

  my %discovered = map { $_->{id} => 1 }
    grep { $_->{source} eq 'discovered' } @{ $router->list_models };
  ok $discovered{'gw-a.invalid/only-here'}, 'first gateway of the class is discovered';
  ok $discovered{'gw-b.invalid/only-here'}, 'second gateway of the same class on another url is discovered too';

  my ($engine_b) = $router->resolve('gw-b.invalid/only-here');
  is $engine_b->{url}, 'http://gw-b.invalid/v1', 'discovered model routes to the gateway that listed it';
}

done_testing;
