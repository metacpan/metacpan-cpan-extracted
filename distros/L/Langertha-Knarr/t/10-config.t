use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );
use YAML::PP;

use Langertha ();
use Langertha::Knarr::Config;

# Test: empty config (no file)
{
  my $config = Langertha::Knarr::Config->new;
  is_deeply $config->models, {}, 'empty config has no models';
  is_deeply $config->listen, ['127.0.0.1:8080', '127.0.0.1:11434'], 'default listen addresses';
  is $config->default_engine, undef, 'no default engine';
  ok !$config->auto_discover, 'auto_discover disabled by default';
}

# Test: config from YAML file
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
listen: "127.0.0.1:9090"
models:
  test-model:
    engine: OpenAI
    model: gpt-4o-mini
  local:
    engine: OllamaOpenAI
    url: http://localhost:11434/v1
    model: llama3.2
default:
  engine: OpenAI
auto_discover: true
proxy_api_key: secret123
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  is_deeply $config->listen, ['127.0.0.1:9090'], 'custom listen address (single → array)';
  is scalar keys %{$config->models}, 2, 'two models configured';
  is $config->models->{'test-model'}{engine}, 'OpenAI', 'correct engine';
  is $config->models->{local}{url}, 'http://localhost:11434/v1', 'url passed through';
  is $config->default_engine->{engine}, 'OpenAI', 'default engine set';
  ok $config->auto_discover, 'auto_discover enabled';
  ok $config->has_proxy_api_key, 'proxy_api_key present';
  is $config->proxy_api_key, 'secret123', 'proxy_api_key value';
}

# Test: validation
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  broken:
    model: something
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my @errors = $config->validate;
  ok scalar @errors > 0, 'validation catches missing engine';
  like $errors[0], qr/missing 'engine'/, 'correct error message';
}

# Test: validation passes on good config
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OpenAI
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my @errors = $config->validate;
  is scalar @errors, 0, 'valid config passes validation';
}

# Test: engine_definitions
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  fast:
    engine: Groq
    model: llama-3.3-70b-versatile
  smart:
    engine: OpenAI
    model: gpt-4o
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  my $defs = $config->engine_definitions;
  is $defs->{fast}{engine}, 'Groq', 'engine definition extracted';
  is $defs->{fast}{name}, 'fast', 'name added to definition';
}

# Test: scan_env
{
  local $ENV{LANGERTHA_OPENAI_API_KEY} = 'test-key-123';
  local $ENV{LANGERTHA_ANTHROPIC_API_KEY} = 'test-key-456';

  my $found = Langertha::Knarr::Config->scan_env;
  ok $found->{OpenAI}, 'found OpenAI from env';
  ok $found->{Anthropic}, 'found Anthropic from env';
  is $found->{OpenAI}{engine}, 'OpenAI', 'correct engine name';
}

# Test: scan_env with .env file
{
  my ($fh, $file) = tempfile(SUFFIX => '.env', UNLINK => 1);
  print $fh "LANGERTHA_GROQ_API_KEY=groq-test-key\n";
  print $fh "# comment line\n";
  print $fh "export LANGERTHA_MISTRAL_API_KEY=mistral-test-key\n";
  close $fh;

  local $ENV{LANGERTHA_OPENAI_API_KEY};
  delete $ENV{LANGERTHA_OPENAI_API_KEY};
  local $ENV{LANGERTHA_ANTHROPIC_API_KEY};
  delete $ENV{LANGERTHA_ANTHROPIC_API_KEY};
  local $ENV{LANGERTHA_GROQ_API_KEY};
  delete $ENV{LANGERTHA_GROQ_API_KEY};
  local $ENV{LANGERTHA_MISTRAL_API_KEY};
  delete $ENV{LANGERTHA_MISTRAL_API_KEY};

  my $found = Langertha::Knarr::Config->scan_env(env_files => [$file]);
  ok $found->{Groq}, 'found Groq from .env file';
  ok $found->{Mistral}, 'found Mistral from .env file (with export)';
}

# Test: generate_config
{
  my $engines = {
    OpenAI    => { engine => 'OpenAI', api_key_env => 'OPENAI_API_KEY' },
    Anthropic => { engine => 'Anthropic', api_key_env => 'ANTHROPIC_API_KEY' },
  };
  my $yaml = Langertha::Knarr::Config->generate_config(engines => $engines);
  like $yaml, qr/engine: OpenAI/, 'generated config has OpenAI';
  like $yaml, qr/engine: Anthropic/, 'generated config has Anthropic';
  like $yaml, qr/auto_discover: true/, 'auto_discover enabled';
  like $yaml, qr/listen:/, 'has listen directive';
}

# Test: Langfuse config
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OpenAI
langfuse:
  url: http://localhost:3000
  public_key: pk-lf-test
  secret_key: sk-lf-test
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  is $config->langfuse->{url}, 'http://localhost:3000', 'langfuse url';
  is $config->langfuse->{public_key}, 'pk-lf-test', 'langfuse public key';
}

# Test: ENV variable interpolation in YAML
{
  local $ENV{MY_TEST_API_KEY} = 'sk-secret-123';
  local $ENV{MY_TEST_URL} = 'http://my-server:8080';

  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test-model:
    engine: OpenAI
    api_key: ${MY_TEST_API_KEY}
    url: ${MY_TEST_URL}
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  is $config->models->{'test-model'}{api_key}, 'sk-secret-123', 'ENV interpolation in api_key';
  is $config->models->{'test-model'}{url}, 'http://my-server:8080', 'ENV interpolation in url';
}

# Test: ENV interpolation with undefined var
{
  local $ENV{DEFINED_VAR} = 'hello';
  # Make sure UNDEFINED_VAR is not set
  local $ENV{UNDEFINED_VAR};
  delete $ENV{UNDEFINED_VAR};

  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OpenAI
    api_key: ${DEFINED_VAR}
    url: ${UNDEFINED_VAR}
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  is $config->models->{test}{api_key}, 'hello', 'defined var interpolated';
  is $config->models->{test}{url}, '', 'undefined var becomes empty string';
}

# Test: from_env (zero-config mode)
{
  local $ENV{LANGERTHA_OPENAI_API_KEY} = 'test-key-123';
  local $ENV{LANGERTHA_ANTHROPIC_API_KEY} = 'test-key-456';

  my $config = Langertha::Knarr::Config->from_env;
  ok scalar keys %{$config->models} >= 2, 'from_env found engines';
  ok $config->models->{openai}, 'from_env has openai model';
  ok $config->models->{anthropic}, 'from_env has anthropic model';
  is $config->models->{openai}{engine}, 'OpenAI', 'correct engine';
  ok $config->default_engine, 'default engine set when OpenAI found';
  ok $config->auto_discover, 'auto_discover enabled in from_env';
}

# Test: listen array in config
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
listen:
  - "127.0.0.1:8080"
  - "127.0.0.1:11434"
  - "127.0.0.1:8000"
models:
  test:
    engine: OpenAI
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  is scalar @{$config->listen}, 3, 'three listen addresses';
  is $config->listen->[0], '127.0.0.1:8080', 'first address';
  is $config->listen->[1], '127.0.0.1:11434', 'second address (ollama port)';
  is $config->listen->[2], '127.0.0.1:8000', 'third address (vllm port)';
}

# Test: passthrough disabled by default
{
  my $config = Langertha::Knarr::Config->new;
  is_deeply $config->passthrough, {}, 'passthrough disabled by default';
  is $config->passthrough_url_for('anthropic'), undef, 'no anthropic passthrough';
}

# Test: passthrough: true enables all with defaults
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OpenAI
passthrough: true
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  is $config->passthrough_url_for('anthropic'), 'https://api.anthropic.com', 'anthropic passthrough default URL';
  is $config->passthrough_url_for('openai'), 'https://api.openai.com', 'openai passthrough default URL';
  is $config->passthrough_url_for('ollama'), undef, 'no ollama passthrough';
}

# Test: passthrough with custom URLs
{
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OpenAI
passthrough:
  anthropic: https://my-anthropic-proxy.internal
  openai: true
YAML
  close $fh;

  my $config = Langertha::Knarr::Config->new(file => $file);
  is $config->passthrough_url_for('anthropic'), 'https://my-anthropic-proxy.internal', 'custom anthropic URL';
  is $config->passthrough_url_for('openai'), 'https://api.openai.com', 'openai default URL via true';
}

# Test: from_env enables passthrough
{
  local $ENV{LANGERTHA_OPENAI_API_KEY} = 'test-key';
  my $config = Langertha::Knarr::Config->from_env;
  ok $config->passthrough_url_for('anthropic'), 'from_env enables anthropic passthrough';
  ok $config->passthrough_url_for('openai'), 'from_env enables openai passthrough';
}

# Test: engine catalog / default models are derived from Langertha, not hardcoded.
#
# Runs against the *installed* Langertha, whatever version that is. Engines
# whose class is not installed are skipped, so this stays green on an older
# Langertha than the one in development.
{
  my $catalog = Langertha::Knarr::Config->engine_catalog;
  ok scalar @$catalog >= 12, 'engine catalog is populated';

  # These Langertha engine classes deliberately croak instead of naming a
  # default model. Config.pm carries its own fallback for the first two.
  # If one of them ever grows a real default_model this goes red -- which is
  # the signal to drop the corresponding %DEFAULT_MODEL_FALLBACK entry.
  my %names_no_default = map { $_ => 1 } qw( Groq OpenRouter HuggingFace Replicate );
  my %has_fallback     = map { $_ => 1 } qw( Groq OpenRouter );

  # engine => the model name Langertha itself declares; only engines whose
  # class names none fall back to whatever Knarr supplies.
  my %expected;
  my $installed = 0;

  for my $def (@$catalog) {
    my $engine = $def->{engine};
    my $class = eval { Langertha->resolve_engine_class($engine) };
    unless (defined $class) {
      note "$engine: no engine class in Langertha $Langertha::VERSION, skipped";
      next;
    }
    $installed++;

    my $declared = eval { $class->default_model };
    $declared = undef unless defined $declared && length $declared;
    my $got = Langertha::Knarr::Config->default_model_for($engine);

    if ($names_no_default{$engine}) {
      is $declared, undef, "$engine: $class names no default model";
      if ($has_fallback{$engine}) {
        ok defined $got, "$engine: Knarr fallback default model supplied";
      } else {
        is $got, undef, "$engine: no default model available";
      }
    } else {
      ok defined $declared, "$engine: $class declares a default model";
      is $got, $declared, "$engine: default_model_for matches ${class}->default_model";
    }
    $expected{$engine} = defined $declared ? $declared : $got;
  }

  ok $installed >= 8, "checked $installed installed engine classes";

  # End-to-end: both config producers must emit exactly those models. This is
  # what goes red if anyone reintroduces a hardcoded model table in from_env
  # or generate_config.
  my @keys = map { $_->{vars}[0] } @$catalog;
  local @ENV{@keys};
  $ENV{$_} = 'test-key' for @keys;

  my $config = Langertha::Knarr::Config->from_env;
  my $found  = Langertha::Knarr::Config->scan_env;
  my $yaml   = Langertha::Knarr::Config->generate_config(engines => $found);
  my $parsed = YAML::PP->new->load_string($yaml);

  is scalar(keys %$found), scalar(@$catalog), 'scan_env finds every catalogued engine';

  for my $def (@$catalog) {
    my $engine = $def->{engine};
    next unless exists $expected{$engine};

    my $entry = $config->models->{lc $engine};
    ok $entry, "from_env configured $engine";
    is $entry->{model}, $expected{$engine}, "from_env model for $engine from engine class";
    is $entry->{api_key_env}, $def->{vars}[0], "from_env api_key_env for $engine";

    my $name = lc $engine;
    $name .= '-default' if $name eq 'openai' || $name eq 'anthropic';
    is $parsed->{models}{$name}{model}, $expected{$engine},
      "generate_config model for $engine from engine class";
  }
}

# Test: unknown engines resolve to no default model instead of dying
{
  is(Langertha::Knarr::Config->default_model_for('NoSuchEngineHere'), undef,
    'unknown engine has no default model');
  is(Langertha::Knarr::Config->default_model_for(undef), undef,
    'undef engine has no default model');
  is(Langertha::Knarr::Config->default_model_for(''), undef,
    'empty engine name has no default model');
}

done_testing;
