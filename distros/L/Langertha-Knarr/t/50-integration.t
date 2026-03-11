use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

eval { require Test::Mojo };
my $has_test_mojo = !$@;

SKIP: {
  skip 'Test::Mojo not available', 1 unless $has_test_mojo;

  # Create a minimal config with OllamaOpenAI (no auth needed)
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test-model:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
    model: llama3.2
YAML
  close $fh;

  require Langertha::Knarr;
  my $app = Langertha::Knarr->build_app(config_file => $file);
  my $t = Test::Mojo->new($app);

  # Test: health endpoint
  $t->get_ok('/health')
    ->status_is(200)
    ->json_is('/status' => 'ok')
    ->json_is('/proxy' => 'knarr');

  # Test: GET /v1/models (OpenAI format)
  $t->get_ok('/v1/models')
    ->status_is(200)
    ->json_is('/object' => 'list')
    ->json_has('/data/0/id');

  # Test: GET /api/tags (Ollama format)
  $t->get_ok('/api/tags')
    ->status_is(200)
    ->json_has('/models');

  # Test: GET /api/ps (Ollama format)
  $t->get_ok('/api/ps')
    ->status_is(200)
    ->json_is('/models' => []);

  # Test: POST without JSON body
  $t->post_ok('/v1/chat/completions')
    ->status_is(400)
    ->json_has('/error/message');

  # Test: POST with unknown model (no default engine)
  $t->post_ok('/v1/chat/completions' => json => {
    model    => 'nonexistent-model',
    messages => [{ role => 'user', content => 'test' }],
  })
    ->status_is(404)
    ->json_has('/error');
}

SKIP: {
  skip 'Test::Mojo not available', 1 unless $has_test_mojo;

  # Test: proxy auth
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
proxy_api_key: secret123
YAML
  close $fh;

  require Langertha::Knarr;
  my $app = Langertha::Knarr->build_app(config_file => $file);
  my $t = Test::Mojo->new($app);

  # Health is always accessible
  $t->get_ok('/health')
    ->status_is(200);

  # Models without auth fails
  $t->get_ok('/v1/models')
    ->status_is(401);

  # Models with correct auth works
  $t->get_ok('/v1/models' => { Authorization => 'Bearer secret123' })
    ->status_is(200);

  # Models with x-api-key header
  $t->get_ok('/v1/models' => { 'x-api-key' => 'secret123' })
    ->status_is(200);
}

SKIP: {
  skip 'Test::Mojo not available', 1 unless $has_test_mojo;

  # Test: passthrough fallback — unknown model with passthrough enabled
  # The upstream will fail (invalid URL) but we test that the code path is taken
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  local:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
passthrough:
  anthropic: http://test.invalid:9999
  openai: http://test.invalid:9999
YAML
  close $fh;

  require Langertha::Knarr;
  my $app = Langertha::Knarr->build_app(config_file => $file);
  my $t = Test::Mojo->new($app);

  # Known model without passthrough → still routes normally (would fail at engine level)
  # Unknown model WITH passthrough → attempts passthrough (upstream fails, 502)
  $t->post_ok('/v1/chat/completions' => json => {
    model    => 'gpt-4o',
    messages => [{ role => 'user', content => 'test' }],
  });
  # Should be 502 (upstream unreachable) not 404 (model not found)
  ok $t->tx->res->code != 404, 'passthrough: unknown model does not 404';

  # Anthropic format passthrough
  $t->post_ok('/v1/messages' => json => {
    model      => 'claude-sonnet-4-6',
    messages   => [{ role => 'user', content => 'test' }],
    max_tokens => 100,
  });
  ok $t->tx->res->code != 404, 'anthropic passthrough: does not 404';

  # Ollama has no passthrough — unknown model still 404s
  $t->post_ok('/api/chat' => json => {
    model    => 'nonexistent',
    messages => [{ role => 'user', content => 'test' }],
  })
    ->status_is(404);
}

SKIP: {
  skip 'Test::Mojo not available', 1 unless $has_test_mojo;

  # Test: passthrough disabled — unknown model → 404
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  local:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
YAML
  close $fh;

  require Langertha::Knarr;
  my $app = Langertha::Knarr->build_app(config_file => $file);
  my $t = Test::Mojo->new($app);

  $t->post_ok('/v1/chat/completions' => json => {
    model    => 'gpt-4o',
    messages => [{ role => 'user', content => 'test' }],
  })
    ->status_is(404);
}

SKIP: {
  skip 'Test::Mojo not available', 1 unless $has_test_mojo;

  # Test: dynamic api_key_validator + before_request hook
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh <<'YAML';
models:
  test:
    engine: OllamaOpenAI
    url: http://test.invalid:11434/v1
YAML
  close $fh;

  require Langertha::Knarr;
  my $app = Langertha::Knarr->build_app(
    config_file => $file,
    api_key_validator => sub {
      my ($c, $ctx) = @_;
      return { allow => 1 } if $ctx->{api_key} eq 'allow-key';
      return { allow => 0, status => 403, message => 'forbidden by validator' };
    },
    before_request => sub {
      my ($c, $ctx) = @_;
      return unless $ctx->{type} eq 'embedding';
      return {
        stop    => 1,
        status  => 418,
        message => 'embeddings disabled by policy',
        type    => 'policy_denied',
      };
    },
  );
  my $t = Test::Mojo->new($app);

  # Health still open
  $t->get_ok('/health')
    ->status_is(200);

  # Validator blocks missing/invalid API key
  $t->get_ok('/v1/models')
    ->status_is(403)
    ->json_is('/error/message' => 'forbidden by validator');

  $t->get_ok('/v1/models' => { Authorization => 'Bearer wrong-key' })
    ->status_is(403);

  # Validator allows valid API key
  $t->get_ok('/v1/models' => { Authorization => 'Bearer allow-key' })
    ->status_is(200)
    ->json_is('/object' => 'list');

  # before_request can block specific request types
  $t->post_ok('/v1/embeddings' => { Authorization => 'Bearer allow-key' } => json => {
    model => 'test',
    input => 'hello',
  })
    ->status_is(418)
    ->json_is('/error/message' => 'embeddings disabled by policy');
}

done_testing;
