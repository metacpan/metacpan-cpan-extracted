#!/usr/bin/env perl
# ABSTRACT: Provider manifest Builder: engine -> manifest, offline

use strict;
use warnings;

use Test2::Bundle::More;
use Module::Runtime qw( use_module );

use Langertha::Manifest::Builder;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Anthropic;
use Langertha::Engine::AKIAnthropic;
use Langertha::Engine::MiniMaxAnthropic;
use Langertha::Engine::MoonshotAnthropic;
use Langertha::Engine::LMStudioAnthropic;
use Langertha::Engine::vLLM;
use Langertha::Engine::Ollama;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::Groq;
use Langertha::Engine::Gemini;
use Langertha::Engine::Whisper;
use Langertha::Engine::NousResearch;

# The Builder is how Knarr and Skeid publish what they expose. What matters:
# the manifest tells the truth about the engine (dialect from the engine
# family and its wire variant, capabilities from engine_capabilities -- the
# same registry chat_f's rewrites read -- limited to what describes a chat
# call to the model), it never carries a secret, and building it neither does
# I/O nor disturbs the caller's engine.

delete @ENV{ grep { /\ALANGERTHA_/ } keys %ENV };

my $SENTINEL = 'sk-SENTINEL-must-never-appear';
my %ALLOWED  = map { $_ => 1 } Langertha::Manifest::Builder->model_capabilities;

# engine_capabilities for one model, restricted to the published allowlist:
# what a Builder-made model entry must claim, no more, no less.
sub expected_caps {
  my ($engine) = @_;
  my $caps = $engine->engine_capabilities;
  return { map { $_ => 1 } grep { $caps->{$_} && $ALLOWED{$_} } keys %$caps };
}

sub caps_of {
  my ( $manifest, $i ) = @_;
  my $caps = $manifest->models->[ $i // 0 ]->capabilities;
  return { map { $_ => 1 } grep { $caps->{$_} } keys %$caps };
}

subtest 'OpenAI' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => $SENTINEL );
  my $m = Langertha::Manifest::Builder->from_engine($engine);
  isa_ok $m, 'Langertha::Manifest';
  is $m->provider_id, 'openai', 'provider_id from class';
  is $m->issuer, 'https://api.openai.com', 'issuer is the url origin';
  my $ep = $m->endpoint('chat');
  is $ep->dialect, 'openai-chat', 'OpenAIBase family -> openai-chat';
  is $ep->base_url, 'https://api.openai.com/v1', 'base_url is the engine url';
  is $ep->auth_ref, 'api', 'required key -> auth_ref';
  is $m->auth_entry('api')->type, 'api_key', 'auth type api_key';
  is $m->models->[0]->id, $engine->chat_model, 'default model is the configured model';
  is_deeply caps_of($m), expected_caps($engine), 'capabilities are the model-scoped registry flags';
  ok $m->models->[0]->supports($_), "supports $_" for qw( chat streaming tools_native tool_choice_named );
  # The engine also embeds, transcribes and generates images -- other
  # operations, not facts about the chat model gpt-5.6.
  ok $engine->supports($_), "engine itself supports $_" for qw( embedding transcription image_generation );
  ok !$m->models->[0]->supports($_), "model entry does not claim $_"
    for qw( embedding transcription image_generation );
  unlike $m->to_json, qr/\Q$SENTINEL\E/, 'the api_key never reaches the manifest';
};

subtest 'Groq gpt-oss: transcription is not a model claim' => sub {
  my $engine = Langertha::Engine::Groq->new( api_key => $SENTINEL, model => 'openai/gpt-oss-120b' );
  ok $engine->supports('transcription'), 'the Groq engine does transcribe';
  my $m = Langertha::Manifest::Builder->from_engine($engine);
  ok !$m->models->[0]->supports('transcription'), 'gpt-oss-120b does not claim transcription';
  ok $m->models->[0]->supports('tools_native'), 'but claims tools';
};

subtest 'OpenAIResponses is the responses dialect' => sub {
  my $m = Langertha::Manifest::Builder->from_engine(
    Langertha::Engine::OpenAIResponses->new( api_key => $SENTINEL ) );
  is $m->endpoint('chat')->dialect, 'responses', 'most specific class wins over OpenAIBase';
  ok !$m->models->[0]->supports('embedding'), 'no embedding claim on a responses model';
};

subtest 'Anthropic, with per-model capabilities' => sub {
  my $engine = Langertha::Engine::Anthropic->new( api_key => $SENTINEL );
  my $m = Langertha::Manifest::Builder->from_engine( $engine,
    models => [ 'claude-sonnet-4-6', 'claude-sonnet-5' ] );
  is $m->endpoint('chat')->dialect, 'anthropic', 'first-party -> anthropic';
  is $m->endpoint('chat')->base_url, 'https://api.anthropic.com', 'base_url is the engine url';
  is $m->endpoint('chat')->auth_ref, 'api', 'required key';
  # Anthropic's model_capability_corrections clear temperature on sonnet-5
  # (ADR 0019 layer 3): the manifest must reflect the model, not the default.
  my ( $old, $new ) = @{ $m->models };
  is $old->id, 'claude-sonnet-4-6', 'first model';
  ok $old->supports('temperature'), 'sonnet-4-6 accepts temperature';
  ok !$new->supports('temperature'), 'sonnet-5 does not (model-scoped correction applied)';
  my $probe = Langertha::Engine::Anthropic->new( api_key => 'x', chat_model => 'claude-sonnet-5' );
  is_deeply caps_of( $m, 1 ), expected_caps($probe), 'equals the registry for that model';
  unlike $m->to_json, qr/\Q$SENTINEL\E/, 'no secret';
};

subtest 'the /anthropic shims are anthropic-compat' => sub {
  # Same Messages envelope, different wire variant: the shims emulate
  # structured output with a synthetic tool + forced choice instead of
  # first-party output_config.format. A client adapter must know which.
  for my $class (qw( AKIAnthropic MiniMaxAnthropic MoonshotAnthropic LMStudioAnthropic )) {
    my $engine = "Langertha::Engine::$class"->new( api_key => $SENTINEL, model => 'm' );
    is( Langertha::Manifest::Builder->dialect_for_engine($engine), 'anthropic-compat',
      "$class -> anthropic-compat" );
  }
  is( Langertha::Manifest::Builder->dialect_for_engine(
    Langertha::Engine::Anthropic->new( api_key => 'x' ) ), 'anthropic', 'Anthropic stays anthropic' );
  ok( Langertha::Manifest::Endpoint->new( id => 'c', dialect => 'anthropic-compat',
    base_url => 'https://x.example' )->is_known_dialect, 'anthropic-compat is a known dialect' );
};

subtest 'vLLM with a url and no key' => sub {
  my $engine = Langertha::Engine::vLLM->new( url => 'http://gpu01.lan:8000/v1', model => 'qwen3' );
  my $m = Langertha::Manifest::Builder->from_engine($engine);
  is $m->provider_id, 'vllm', 'vLLM -> vllm';
  is $m->issuer, 'http://gpu01.lan:8000', 'issuer keeps a non-default port';
  my $ep = $m->endpoint('chat');
  is $ep->dialect, 'openai-chat', 'vLLM is openai-chat';
  is $ep->base_url, 'http://gpu01.lan:8000/v1', 'base_url';
  is $ep->auth_ref, undef, 'optional key, none configured -> no auth';
  is_deeply $m->auth, [], 'no auth entries';
  is $m->models->[0]->id, 'qwen3', 'model';
  # Client-side (Prometheus scrape) and server-management (prefix-cache
  # knobs) features are not claims about the model.
  ok $engine->supports($_), "engine supports $_" for qw( runtime_metrics prefix_caching );
  ok !$m->models->[0]->supports($_), "model entry does not claim $_"
    for qw( runtime_metrics prefix_caching embedding );
  is_deeply caps_of($m), expected_caps($engine), 'capabilities are the model-scoped flags';
};

subtest 'vLLM placeholder model id is not published' => sub {
  my $engine = Langertha::Engine::vLLM->new( url => 'http://gpu01.lan:8000/v1' );
  my @warnings;
  my $m = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    Langertha::Manifest::Builder->from_engine($engine);
  };
  is_deeply $m->models, [], 'the placeholder "default" is skipped';
  is scalar @warnings, 1, 'one warning for the model-less endpoint';
  like $warnings[0], qr/placeholder model 'default'.*published without models.*pass models =>/,
    'the warning says what happened and what to pass';
  is scalar @{ $m->endpoints }, 1, 'the endpoint is still published';
  my $with = do {
    local $SIG{__WARN__} = sub { fail "unexpected warning: @_" };
    Langertha::Manifest::Builder->from_engine( $engine, models => ['qwen3'] );
  };
  is $with->models->[0]->id, 'qwen3', 'models => publishes explicit ids';
};

subtest 'vLLM with a configured key announces api_key, never the key' => sub {
  my $m = Langertha::Manifest::Builder->from_engine(
    Langertha::Engine::vLLM->new( url => 'http://gpu01.lan:8000/v1', model => 'q', api_key => $SENTINEL ) );
  is $m->endpoint('chat')->auth_ref, 'api', 'optional key configured -> auth';
  unlike $m->to_json, qr/\Q$SENTINEL\E/, 'no secret';
};

subtest 'Ollama native' => sub {
  my $engine = Langertha::Engine::Ollama->new( url => 'http://localhost:11434' );
  my $m = Langertha::Manifest::Builder->from_engine( $engine, models => [ 'llama3.3', 'qwen3:8b' ] );
  is $m->endpoint('chat')->dialect, 'ollama', 'Ollama -> ollama';
  is $m->endpoint('chat')->auth_ref, undef, 'local Ollama needs no auth';
  is $m->issuer, 'http://localhost:11434', 'issuer';
  is scalar @{ $m->models }, 2, 'two models';
  # num_ctx (context_size) and keep_alive are server-side allocation and
  # residency of the Ollama host, not facts about the model.
  ok $engine->supports($_), "engine supports $_" for qw( context_size keep_alive );
  ok !$m->models->[1]->supports($_), "no $_ claim" for qw( context_size keep_alive embedding );
};

subtest 'model-less engines work when models are given, untouched' => sub {
  # OpenRouter / OllamaOpenAI croak in default_model: the Builder must not
  # need the engine's own model when the caller lists the models.
  for my $engine (
    Langertha::Engine::OllamaOpenAI->new( url => 'http://localhost:11434/v1' ),
    Langertha::Engine::OpenRouter->new( api_key => $SENTINEL ),
  ) {
    my $class = ref $engine;
    my $m = eval { Langertha::Manifest::Builder->from_engine( $engine, models => [ 'llama3', 'qwen3' ] ) };
    ok $m, "$class with models => builds" or diag $@;
    is scalar @{ $m->models }, 2, "$class: two model entries";
    ok !$engine->has_model,      "$class: model slot not vivified";
    ok !$engine->has_chat_model, "$class: chat_model slot not vivified";
    ok !$engine->has_api_key,    "$class: api_key slot not vivified" unless $class =~ /OpenRouter/;
  }
  ok !eval { Langertha::Manifest::Builder->from_engine(
    Langertha::Engine::OllamaOpenAI->new( url => 'http://localhost:11434/v1' ) ); 1 },
    'without models it croaks';
  like $@, qr/cannot determine a model .* pass models =>/, 'and says what to pass';
};

subtest 'overrides and auth=none' => sub {
  my $m = Langertha::Manifest::Builder->from_engine(
    Langertha::Engine::OpenAI->new( api_key => $SENTINEL ),
    provider_id => 'my-knarr',
    issuer      => 'https://knarr.example',
    base_url    => 'https://knarr.example/v1',
    endpoint_id => 'openai',
    auth        => 'none',
  );
  is $m->provider_id, 'my-knarr', 'provider_id override';
  is $m->issuer, 'https://knarr.example', 'issuer override';
  is $m->endpoint('openai')->base_url, 'https://knarr.example/v1', 'public base_url, not the upstream one';
  is $m->endpoint('openai')->auth_ref, undef, 'auth none';
  unlike $m->to_json, qr/api\.openai\.com/, 'upstream url does not leak when overridden';
};

subtest 'multi-endpoint build (Knarr shape)' => sub {
  my $b = Langertha::Manifest::Builder->new( provider_id => 'knarr', issuer => 'https://knarr.example' );
  $b->add_engine( Langertha::Engine::OpenAI->new( api_key => $SENTINEL ),
    endpoint_id => 'openai', base_url => 'https://knarr.example/v1', models => ['m1'] );
  $b->add_engine( Langertha::Engine::Anthropic->new( api_key => $SENTINEL ),
    endpoint_id => 'anthropic', base_url => 'https://knarr.example', models => ['m1'] );
  $b->add_endpoint( id => 'ollama', dialect => 'ollama', base_url => 'https://knarr.example' );
  $b->add_model( id => 'm1', endpoint_ref => 'ollama', capabilities => { chat => 1 } );
  my $m = $b->manifest;
  is scalar @{ $m->endpoints }, 3, 'three endpoints';
  is scalar @{ $m->auth }, 1, 'one shared auth entry';
  is scalar @{ $m->models }, 3, 'the same model id on three endpoints';
  is $m->endpoint('anthropic')->auth_ref, 'api', 'second engine reuses the auth entry';
  unlike $m->to_json, qr/\Q$SENTINEL\E/, 'no secret';
  ok !eval { $b->add_engine( Langertha::Engine::OpenAI->new( api_key => 'x' ), endpoint_id => 'openai' ); 1 },
    'duplicate endpoint id croaks';
  ok !eval { $b->add_model( id => 'm1', endpoint_ref => 'ollama' ); 1 },
    'duplicate (model, endpoint) croaks at add time';
  ok !eval { $b->add_auth( id => 'api', type => 'api_key' ); 1 }, 'duplicate auth id croaks';
};

subtest 'add_engine is atomic' => sub {
  my $b = Langertha::Manifest::Builder->new( provider_id => 'p', issuer => 'https://p.example' );
  $b->add_endpoint( id => 'chat', dialect => 'openai-chat', base_url => 'https://p.example/v1' );
  ok !eval { $b->add_engine( Langertha::Engine::OpenAI->new( api_key => $SENTINEL ), models => ['m'] ); 1 },
    'duplicate endpoint id croaks';
  like $@, qr/duplicate endpoint id 'chat'/, 'message';
  my $m = $b->manifest;
  is_deeply $m->auth, [], 'no half-added auth entry';
  is_deeply $m->models, [], 'no half-added model entry';
  ok !eval { $b->add_engine( Langertha::Engine::OpenAI->new( api_key => $SENTINEL ),
    endpoint_id => 'other', models => [ 'm', 'm' ] ); 1 }, 'duplicate model in one call croaks';
  is scalar @{ $b->manifest->endpoints }, 1, 'and adds no endpoint';
};

subtest 'Gemini dialect and model-aware capabilities' => sub {
  my $m = Langertha::Manifest::Builder->from_engine(
    Langertha::Engine::Gemini->new( api_key => $SENTINEL ), models => [ 'gemini-2.5-pro', 'gemini-3-pro' ] );
  is $m->endpoint('chat')->dialect, 'gemini', 'gemini';
  ok $m->models->[0]->supports('thinking_budget'), 'thinking_budget claimed for 2.5';
  ok !$m->models->[1]->supports('thinking_budget'), 'and not for 3';
  ok !$m->models->[0]->supports('cached_content'), 'cache-resource lifecycle is not a model claim';
};

subtest 'transcription-only engine is not a chat engine' => sub {
  my $whisper = Langertha::Engine::Whisper->new( url => 'http://localhost:8000/v1' );
  ok !eval { Langertha::Manifest::Builder->from_engine($whisper); 1 }, 'Whisper croaks';
  like $@, qr/needs a chat engine/, 'message says why';
  ok !eval { Langertha::Manifest::Builder->from_engine( $whisper, dialect => 'openai-chat' ); 1 },
    'a dialect override does not make it one';
  like $@, qr/needs a chat engine/, 'same clear message, not a missing-method error';
};

# karr k251 (step (e) of the k238 design): the Builder probes per model on a
# clone_object copy, which copies every slot that is already set -- including
# a lazy tool_wire_format built for the source engine's chat_model. Once the
# tag depends on the model, a stale copy would publish one model's tool flags
# for another. The probe drops a built tag so it is resolved again for the
# probed model; a tag the caller passed to the constructor is kept.
{
  package Test::ModelTagNous;
  use Moose;
  extends 'Langertha::Engine::NousResearch';
  sub _build_tool_wire_format { $_[0]->chat_model =~ /hermes/i ? 'hermes' : 'openai' }
  __PACKAGE__->meta->make_immutable;
}

subtest 'probe resolves a model-aware tool_wire_format per model' => sub {
  my $engine = Test::ModelTagNous->new( api_key => $SENTINEL, model => 'Hermes-4-70B' );
  is $engine->tool_wire_format, 'hermes', 'the tag is built on the source engine first';
  my $m = Langertha::Manifest::Builder->from_engine( $engine,
    models => [ 'Hermes-4-70B', 'anthropic/claude-sonnet-4.6' ] );
  my ( $hermes, $claude ) = map { caps_of( $m, $_ ) } 0, 1;
  ok $hermes->{tools_hermes} && !$hermes->{tools_native}, 'Hermes slug: hermes tool flags';
  ok $claude->{tools_native} && !$claude->{tools_hermes}, 'claude slug: native tool flags, not the stale tag';
  ok $claude->{tool_choice_named}, 'claude slug: a named tool_choice';
  is $engine->tool_wire_format, 'hermes', 'the caller engine keeps its tag';

  my $pinned = Test::ModelTagNous->new( api_key => $SENTINEL, model => 'Hermes-4-70B',
    tool_wire_format => 'openai' );
  my $mp = Langertha::Manifest::Builder->from_engine( $pinned,
    models => [ 'Hermes-4-70B', 'anthropic/claude-sonnet-4.6' ] );
  for my $i ( 0, 1 ) {
    my $caps = caps_of( $mp, $i );
    ok $caps->{tools_native} && !$caps->{tools_hermes}, "model $i: the constructor tag is kept";
  }
};

subtest 'NousResearch publishes different tool flags per model (k238, no override)' => sub {
  # The payoff of the model-aware builder (ADR 0033) on the REAL engine, not a
  # test subclass: one NousResearch instance, probed for two models, must
  # publish disagreeing tool-transport flags -- the Hermes slug on the hermes
  # wire, the Claude slug on native OpenAI tools. This is the fact-4 manifest
  # hazard payoff: it only works because _capability_clone resets the derived
  # tag so each probe resolves it for its own chat_model.
  my $engine = Langertha::Engine::NousResearch->new( api_key => $SENTINEL, model => 'Hermes-4-70B' );
  is $engine->tool_wire_format, 'hermes', 'the source engine (Hermes-4-70B) is on the hermes wire';
  my $m = Langertha::Manifest::Builder->from_engine( $engine,
    models => [ 'Hermes-4-70B', 'anthropic/claude-sonnet-4.6' ] );
  my ( $hermes, $claude ) = map { caps_of( $m, $_ ) } 0, 1;
  ok  $hermes->{tools_hermes}, 'Hermes-4-70B: tools_hermes';
  ok !$hermes->{tools_native}, 'Hermes-4-70B: not tools_native';
  ok !$hermes->{tool_choice_named}, 'Hermes-4-70B: no named tool_choice (the prompt cannot force one)';
  ok  $claude->{tools_native}, 'claude slug: tools_native, not the stale hermes tag';
  ok !$claude->{tools_hermes}, 'claude slug: not tools_hermes';
  ok  $claude->{tool_choice_named}, 'claude slug: a named tool_choice';
  is $engine->tool_wire_format, 'hermes', 'the caller engine keeps its own tag';
  unlike $m->to_json, qr/\Q$SENTINEL\E/, 'no secret';
};

subtest 'image_input is published per model (k266)' => sub {
  # knarr/skeid manifests answer "does this model see images" from the model
  # entry; the flag is model-scoped (ADR 0019 k266 Update), so two models of
  # one engine must disagree, and a no-claim engine publishes no claim.
  ok $ALLOWED{image_input}, 'image_input is on the published allowlist';
  my $openai = Langertha::Engine::OpenAI->new( api_key => $SENTINEL );
  my $m = Langertha::Manifest::Builder->from_engine( $openai,
    models => [ 'gpt-4o', 'gpt-3.5-turbo' ] );
  ok  $m->models->[0]->supports('image_input'), 'gpt-4o entry claims image_input';
  ok !$m->models->[1]->supports('image_input'), 'gpt-3.5-turbo entry does not';

  my $ollama = Langertha::Engine::Ollama->new( url => 'http://h.example:11434', model => 'llava' );
  my $mo = Langertha::Manifest::Builder->from_engine($ollama);
  ok !$mo->models->[0]->supports('image_input'), 'self-hosted Ollama publishes no claim';
};

subtest 'every engine capability is classified' => sub {
  # Guard: a flag engine_capabilities can report is either published on a
  # model (Builder->model_capabilities) or deliberately engine-level /
  # client-side (this list). A new %ROLE_TO_CAPS flag fails here until it is
  # classified -- it can neither leak onto model entries nor vanish silently.
  my %NOT_MODEL_SCOPED = map { $_ => 1 } qw(
    embedding transcription image_generation
    runtime_metrics prefix_caching keep_alive cached_content context_size
  );
  ok !( grep { $NOT_MODEL_SCOPED{$_} } keys %ALLOWED ), 'the two lists are disjoint';
  my %seen;
  for my $row (
    [ OpenAI => 'm' ], [ OpenAIResponses => 'm' ], [ Anthropic => 'm' ], [ AKIAnthropic => 'm' ],
    [ Gemini => 'gemini-2.5-pro' ], [ Ollama => 'm' ], [ OllamaOpenAI => 'm' ], [ vLLM => 'm' ],
    [ SGLang => 'm' ], [ LlamaCpp => 'm' ], [ Groq => 'm' ], [ Cerebras => 'm' ], [ Mistral => 'm' ],
    [ Perplexity => 'm' ], [ NousResearch => 'm' ], [ AKI => 'm' ], [ LMStudio => 'm' ],
    [ DeepSeek => 'm' ], [ Moonshot => 'm' ], [ OpenRouter => 'm' ], [ VLLMHook => 'm' ],
  ) {
    my ( $name, $model ) = @$row;
    my $engine = use_module("Langertha::Engine::$name")
      ->new( api_key => 'k', url => 'http://h.example:1/v1', model => $model );
    $seen{$_}++ for grep { $engine->engine_capabilities->{$_} } keys %{ $engine->engine_capabilities };
  }
  for my $cap ( sort keys %seen ) {
    ok $ALLOWED{$cap} || $NOT_MODEL_SCOPED{$cap}, "capability '$cap' is classified";
  }
};

# k369: engine_class_for_dialect is the inverse of dialect_for_engine; the
# round trip over the whole dialect vocabulary stops the dialect list and the
# engine classes drifting apart.
subtest 'engine_class_for_dialect' => sub {
  my $builder = 'Langertha::Manifest::Builder';
  my %expect = (
    'openai-chat'      => 'Langertha::Engine::OpenAI',
    'responses'        => 'Langertha::Engine::OpenAIResponses',
    'perplexity-agent' => 'Langertha::Engine::Perplexity',
    'anthropic'        => 'Langertha::Engine::Anthropic',
    'anthropic-compat' => 'Langertha::Engine::AnthropicBase',
    'gemini'           => 'Langertha::Engine::Gemini',
    'ollama'           => 'Langertha::Engine::Ollama',
    'aki'              => 'Langertha::Engine::AKI',
    'lmstudio'         => 'Langertha::Engine::LMStudio',
  );
  is $builder->engine_class_for_dialect($_), $expect{$_}, "$_ => $expect{$_}" for sort keys %expect;
  is $builder->engine_class_for_dialect('no-such-dialect'), undef, 'unknown dialect => undef';
  is $builder->engine_class_for_dialect(undef), undef, 'undef dialect => undef';

  require Langertha::Manifest::Endpoint;
  for my $dialect ( Langertha::Manifest::Endpoint->known_dialects ) {
    my $engine_class = $builder->engine_class_for_dialect($dialect);
    ok defined $engine_class, "vocabulary dialect $dialect has an engine class" or next;
    my $engine = $engine_class->new( url => 'http://127.0.0.1:1', api_key => 'k', model => 'm' );
    is $builder->dialect_for_engine($engine), $dialect, "round trip: $dialect";
  }
};

done_testing;
