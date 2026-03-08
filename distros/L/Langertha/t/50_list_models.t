#!/usr/bin/env perl
# ABSTRACT: Test dynamic model listing, caching, and pagination for all engines

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use Path::Tiny;

# Test response parsing for model listing APIs
# These tests verify that each engine can correctly parse API responses
# without making actual API calls

my $data_dir = path(__FILE__)->parent->child('data');

# Helper to load fixture JSON
sub load_fixture {
  my ($filename) = @_;
  my $file = $data_dir->child($filename);
  return decode_json($file->slurp_utf8);
}

# Helper to create mock HTTP::Response
sub mock_response {
  my ($json_data) = @_;
  require HTTP::Response;
  my $response = HTTP::Response->new(200, 'OK');
  $response->content(encode_json($json_data));
  $response->header('Content-Type' => 'application/json');
  return $response;
}

# Mock user agent that returns fixture data
{
  package MockUA;
  use parent 'LWP::UserAgent';
  sub new {
    my ($class, $responses) = @_;
    my $self = $class->SUPER::new;
    $self->{_mock_responses} = $responses || [];
    return $self;
  }
  sub request {
    my ($self) = @_;
    return shift @{$self->{_mock_responses}};
  }
}

subtest 'OpenAI response parsing' => sub {
  plan tests => 4;

  use_ok('Langertha::Engine::OpenAI');

  my $fixture = load_fixture('openai_models.json');
  my $response = mock_response($fixture);

  my $engine = Langertha::Engine::OpenAI->new(api_key => 'test-key');

  # Test response parsing — returns full response hash for pagination support
  my $data = $engine->list_models_response($response);

  is(ref($data), 'HASH', 'Returns hash with response data');
  is(ref($data->{data}), 'ARRAY', 'Has models array');
  is(scalar(@{$data->{data}}), 5, 'Parsed 5 models from fixture');
};

subtest 'Anthropic response parsing' => sub {
  plan tests => 5;

  use_ok('Langertha::Engine::Anthropic');

  my $fixture = load_fixture('anthropic_models.json');
  my $response = mock_response($fixture);

  my $engine = Langertha::Engine::Anthropic->new(api_key => 'test-key');

  # Test response parsing
  my $data = $engine->list_models_response($response);

  is(ref($data), 'HASH', 'Returns hash with pagination data');
  is(ref($data->{data}), 'ARRAY', 'Has models array');
  is(scalar(@{$data->{data}}), 3, 'Parsed 3 models from fixture');
  is($data->{data}[0]{id}, 'claude-opus-4-6-20250514', 'First model ID correct');
};

subtest 'Gemini response parsing' => sub {
  plan tests => 5;

  use_ok('Langertha::Engine::Gemini');

  my $fixture = load_fixture('gemini_models.json');
  my $response = mock_response($fixture);

  my $engine = Langertha::Engine::Gemini->new(api_key => 'test-key');

  # Test response parsing
  my $data = $engine->list_models_response($response);

  is(ref($data), 'HASH', 'Returns hash with model data');
  is(ref($data->{models}), 'ARRAY', 'Has models array');
  is(scalar(@{$data->{models}}), 3, 'Parsed 3 models from fixture');
  is($data->{models}[0]{name}, 'models/gemini-2.0-flash-exp', 'First model name correct');
};

subtest 'Groq response parsing' => sub {
  plan tests => 4;

  use_ok('Langertha::Engine::Groq');

  my $fixture = load_fixture('groq_models.json');
  my $response = mock_response($fixture);

  my $engine = Langertha::Engine::Groq->new(api_key => 'test-key');

  # Test response parsing
  my $data = $engine->list_models_response($response);

  is(ref($data), 'HASH', 'Returns hash with response data');
  is(ref($data->{data}), 'ARRAY', 'Has models array');
  is(scalar(@{$data->{data}}), 4, 'Parsed 4 models from fixture');
};

subtest 'Mistral response parsing' => sub {
  plan tests => 4;

  use_ok('Langertha::Engine::Mistral');

  my $fixture = load_fixture('mistral_models.json');
  my $response = mock_response($fixture);

  my $engine = Langertha::Engine::Mistral->new(api_key => 'test-key');

  # Test response parsing
  my $data = $engine->list_models_response($response);

  is(ref($data), 'HASH', 'Returns hash with response data');
  is(ref($data->{data}), 'ARRAY', 'Has models array');
  is(scalar(@{$data->{data}}), 3, 'Parsed 3 models from fixture');
};

subtest 'DeepSeek response parsing' => sub {
  plan tests => 4;

  use_ok('Langertha::Engine::DeepSeek');

  my $fixture = load_fixture('deepseek_models.json');
  my $response = mock_response($fixture);

  my $engine = Langertha::Engine::DeepSeek->new(api_key => 'test-key');

  # Test response parsing
  my $data = $engine->list_models_response($response);

  is(ref($data), 'HASH', 'Returns hash with response data');
  is(ref($data->{data}), 'ARRAY', 'Has models array');
  is(scalar(@{$data->{data}}), 2, 'Parsed 2 models from fixture');
};

subtest 'OpenAI list_models_request construction' => sub {
  plan tests => 3;

  my $engine = Langertha::Engine::OpenAI->new(api_key => 'test-key');
  my $request = $engine->list_models_request;

  isa_ok($request, 'Langertha::Request::HTTP');
  is($request->method, 'GET', 'Uses GET method');
  like($request->uri, qr{/v1/models$}, 'URL ends with /v1/models');
};

subtest 'Anthropic list_models_request construction' => sub {
  plan tests => 4;

  my $engine = Langertha::Engine::Anthropic->new(api_key => 'test-key');

  # Without pagination
  my $request = $engine->list_models_request;
  is($request->method, 'GET', 'Uses GET method');
  like($request->uri, qr{/v1/models}, 'URL contains /v1/models');

  # With pagination params
  my $paged_request = $engine->list_models_request(after_id => 'model-123', limit => 50);
  like($paged_request->uri, qr{after_id=model-123}, 'URL contains after_id param');
  like($paged_request->uri, qr{limit=50}, 'URL contains limit param');
};

subtest 'Gemini list_models_request construction' => sub {
  plan tests => 3;

  my $engine = Langertha::Engine::Gemini->new(api_key => 'test-key');
  my $request = $engine->list_models_request;

  is($request->method, 'GET', 'Uses GET method');
  like($request->uri, qr{/v1beta/models}, 'URL contains /v1beta/models');
  like($request->uri, qr{key=test-key}, 'URL contains API key');
};

subtest 'OpenAI list_models with mock user_agent' => sub {
  plan tests => 8;

  my $fixture = load_fixture('openai_models.json');
  my $mock_ua = MockUA->new([mock_response($fixture), mock_response($fixture)]);

  my $engine = Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    user_agent => $mock_ua,
  );

  # First call: fetches from API
  my $model_ids = $engine->list_models;
  is(ref($model_ids), 'ARRAY', 'Returns arrayref of model IDs');
  is(scalar(@$model_ids), 5, 'Got 5 model IDs');
  is($model_ids->[0], 'gpt-4o', 'First model ID is gpt-4o');

  # Second call: should hit cache (no second MockUA response consumed)
  my $cached_ids = $engine->list_models;
  is_deeply($cached_ids, $model_ids, 'Cache returns same data');

  # Full metadata mode
  my $full = $engine->list_models(full => 1);
  is(ref($full), 'ARRAY', 'Full mode returns arrayref');
  is(ref($full->[0]), 'HASH', 'Full mode returns model objects');
  ok(exists $full->[0]{id}, 'Model objects have id field');

  # Clear cache and force re-fetch
  $engine->clear_models_cache;
  my $refreshed = $engine->list_models;
  is(scalar(@$refreshed), 5, 'Got models after cache clear');
};

subtest 'Cache TTL behavior' => sub {
  plan tests => 2;

  my $fixture = load_fixture('openai_models.json');
  my $mock_ua = MockUA->new([mock_response($fixture), mock_response($fixture)]);

  my $engine = Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    user_agent => $mock_ua,
    models_cache_ttl => 3600,
  );

  is($engine->models_cache_ttl, 3600, 'Cache TTL is configurable');

  # Force refresh bypasses cache
  $engine->list_models; # prime cache
  my $refreshed = $engine->list_models(force_refresh => 1);
  is(scalar(@$refreshed), 5, 'force_refresh bypasses cache');
};

subtest 'Anthropic pagination with _fetch_all_models' => sub {
  plan tests => 2;

  # Page 1: has_more = true
  my $page1 = {
    data => [
      { type => 'model', id => 'claude-opus-4-6-20250514', display_name => 'Claude Opus 4.6' },
    ],
    has_more => JSON->true,
    first_id => 'claude-opus-4-6-20250514',
    last_id => 'claude-opus-4-6-20250514',
  };

  # Page 2: has_more = false
  my $page2 = {
    data => [
      { type => 'model', id => 'claude-sonnet-4-5-20250929', display_name => 'Claude Sonnet 4.5' },
      { type => 'model', id => 'claude-haiku-4-5-20251001', display_name => 'Claude Haiku 4.5' },
    ],
    has_more => JSON->false,
    first_id => 'claude-sonnet-4-5-20250929',
    last_id => 'claude-haiku-4-5-20251001',
  };

  my $mock_ua = MockUA->new([mock_response($page1), mock_response($page2)]);

  my $engine = Langertha::Engine::Anthropic->new(
    api_key => 'test-key',
    user_agent => $mock_ua,
  );

  my $model_ids = $engine->list_models;
  is(scalar(@$model_ids), 3, 'Fetched all 3 models across 2 pages');
  is_deeply($model_ids, [
    'claude-opus-4-6-20250514',
    'claude-sonnet-4-5-20250929',
    'claude-haiku-4-5-20251001',
  ], 'Model IDs collected in correct order');
};

subtest 'Gemini model ID prefix stripping' => sub {
  plan tests => 2;

  my $fixture = load_fixture('gemini_models.json');
  my $mock_ua = MockUA->new([mock_response($fixture)]);

  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'test-key',
    user_agent => $mock_ua,
  );

  my $model_ids = $engine->list_models;
  is(scalar(@$model_ids), 3, 'Got 3 model IDs');
  ok(!grep { /^models\// } @$model_ids, 'No model IDs have "models/" prefix');
};

subtest 'Models role cache attributes' => sub {
  plan tests => 4;

  my $engine = Langertha::Engine::OpenAI->new(api_key => 'test-key');

  # Default TTL
  is($engine->models_cache_ttl, 3600, 'Default TTL is 3600 seconds (1 hour)');

  # Cache starts empty
  is_deeply($engine->_models_cache, {}, 'Cache starts empty');

  # Custom TTL
  my $engine2 = Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    models_cache_ttl => 600,
  );
  is($engine2->models_cache_ttl, 600, 'Custom TTL is respected');

  # clear_models_cache works
  $engine->_models_cache({ timestamp => time, models => [], model_ids => [] });
  $engine->clear_models_cache;
  is_deeply($engine->_models_cache, {}, 'clear_models_cache empties cache');
};

subtest 'Anthropic new parameters' => sub {
  plan tests => 6;

  # Without effort/inference_geo
  my $engine = Langertha::Engine::Anthropic->new(api_key => 'test-key');
  ok(!$engine->has_effort, 'effort not set by default');
  ok(!$engine->has_inference_geo, 'inference_geo not set by default');

  # With effort
  my $engine2 = Langertha::Engine::Anthropic->new(
    api_key => 'test-key',
    effort => 'high',
  );
  ok($engine2->has_effort, 'effort is set');
  is($engine2->effort, 'high', 'effort value is correct');

  # With inference_geo
  my $engine3 = Langertha::Engine::Anthropic->new(
    api_key => 'test-key',
    inference_geo => 'eu',
  );
  ok($engine3->has_inference_geo, 'inference_geo is set');
  is($engine3->inference_geo, 'eu', 'inference_geo value is correct');
};

subtest 'list_models URL correctness for all OpenAICompatible engines' => sub {
  my @engines = (
    [ 'Langertha::Engine::OpenAI',       qr{api\.openai\.com/v1/models$} ],
    [ 'Langertha::Engine::Groq',         qr{groq\.com/openai/v1/models$} ],
    [ 'Langertha::Engine::Cerebras',     qr{cerebras\.ai/v1/models$} ],
    [ 'Langertha::Engine::OpenRouter',   qr{openrouter\.ai/api/v1/models$} ],
    [ 'Langertha::Engine::Replicate',    qr{replicate\.com/v1/models$} ],
    [ 'Langertha::Engine::NousResearch', qr{nousresearch\.com/v1/models$} ],
    [ 'Langertha::Engine::AKIOpenAI',    qr{aki\.io/v1/models$} ],
    [ 'Langertha::Engine::DeepSeek',     qr{deepseek\.com/models$} ],
    [ 'Langertha::Engine::Perplexity',   qr{perplexity\.ai/models$} ],
    [ 'Langertha::Engine::Mistral',      qr{mistral\.ai/v1/models$} ],
  );

  plan tests => scalar(@engines) * 2;

  for my $e (@engines) {
    my ($class, $expected) = @$e;
    use_ok($class);
    my $engine = $class->new(api_key => 'test-key');
    my $request = $engine->list_models_request;
    like($request->uri, $expected, "$class: URL correct (".$request->uri.")");
  }
};

subtest 'Mistral list_models_path override' => sub {
  plan tests => 2;

  my $mistral = Langertha::Engine::Mistral->new(api_key => 'test-key');
  is($mistral->list_models_path, '/v1/models', 'Mistral overrides list_models_path to /v1/models');

  my $openai = Langertha::Engine::OpenAI->new(api_key => 'test-key');
  is($openai->list_models_path, '/models', 'OpenAI uses default /models');
};

subtest 'MiniMax static models' => sub {
  plan tests => 5;

  use_ok('Langertha::Engine::MiniMax');

  my $engine = Langertha::Engine::MiniMax->new(api_key => 'test-key');

  # list_models returns static list without HTTP
  my $model_ids = $engine->list_models;
  is(ref($model_ids), 'ARRAY', 'Returns arrayref');
  ok(scalar(@$model_ids) >= 5, 'Has at least 5 models');
  ok((grep { $_ eq 'MiniMax-M2.5' } @$model_ids), 'Contains MiniMax-M2.5');

  # Full mode returns hashrefs
  my $full = $engine->list_models(full => 1);
  is(ref($full->[0]), 'HASH', 'Full mode returns model hashrefs');
};

subtest 'HuggingFace Hub API list_models' => sub {
  plan tests => 7;

  use_ok('Langertha::Engine::HuggingFace');

  my $fixture = load_fixture('huggingface_hub_models.json');
  my $mock_ua = MockUA->new([mock_response($fixture), mock_response($fixture)]);

  my $engine = Langertha::Engine::HuggingFace->new(
    api_key => 'test-key',
    model => 'test/model',
    user_agent => $mock_ua,
  );

  # list_models returns IDs
  my $model_ids = $engine->list_models;
  is(ref($model_ids), 'ARRAY', 'Returns arrayref');
  is(scalar(@$model_ids), 3, 'Got 3 model IDs');
  is($model_ids->[0], 'meta-llama/Llama-3.3-70B-Instruct', 'First model ID correct');

  # Full mode returns full objects with provider data
  my $full = $engine->list_models(full => 1);
  is(ref($full->[0]), 'HASH', 'Full mode returns model hashrefs');
  ok(exists $full->[0]{inferenceProviderMapping}, 'Full models include inference provider data');

  # Request URL points to Hub API
  $engine->clear_models_cache;
  my $request = $engine->list_models_request;
  like($request->uri, qr{huggingface\.co/api/models}, 'URL points to Hub API');
};

subtest 'HuggingFace list_models with search' => sub {
  plan tests => 2;

  my $fixture = load_fixture('huggingface_hub_models.json');
  my $mock_ua = MockUA->new([mock_response($fixture)]);

  my $engine = Langertha::Engine::HuggingFace->new(
    api_key => 'test-key',
    model => 'test/model',
    user_agent => $mock_ua,
  );

  my $request = $engine->list_models_request(search => 'llama');
  like($request->uri, qr{search=llama}, 'Search parameter in URL');
  like($request->uri, qr{inference_provider=all}, 'inference_provider filter in URL');
};

done_testing;
