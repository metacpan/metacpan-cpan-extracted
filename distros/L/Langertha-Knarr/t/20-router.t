use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

use Langertha::Knarr::Config;
use Langertha::Knarr::Router;

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

done_testing;
