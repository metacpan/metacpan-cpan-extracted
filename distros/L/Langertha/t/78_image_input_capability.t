#!/usr/bin/env perl
# ABSTRACT: image_input is model-scoped: the model sees the image, not merely the wire (k266)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny qw( path );
use Module::Runtime qw( use_module );

use Langertha::Content::Image;

# karr k266 (ADR 0019 k266 Update): knarr's /api/show "vision" and the
# skeid/knarr manifests need to know whether a MODEL sees an image. A flag that
# only said "the wire accepts an image part" would be true on nearly every
# engine and useless; a wrong yes sends images to a text-only model that
# ignores them, a wrong no hides vision. So image_input is resolved per
# chat_model: all-vision families keep it minus text-only exceptions, other
# cloud engines allowlist their vision models, and engines whose model the
# client cannot know (gateways, self-hosted, shims) make no claim. The flag is
# advisory and must never block an image from being sent.

delete @ENV{ grep { /\ALANGERTHA_/ } keys %ENV };

sub engine {
  my ( $name, %args ) = @_;
  return use_module("Langertha::Engine::$name")
    ->new( api_key => 'k', url => 'http://h.example:1/v1', %args );
}

sub claims {
  my ( $name, @model ) = @_;
  return engine( $name, @model ? ( model => $model[0] ) : () )->supports('image_input') ? 1 : 0;
}

# ---------------------------------------------------------------------------
# 1. Every chat engine's default model, per the advisor table (2026-09-25).
#    Engines without a default model are probed with a neutral id.
# ---------------------------------------------------------------------------
my %DEFAULT = (
  # all-vision families
  OpenAI            => 1,  # gpt-5.6-terra
  OpenAIResponses   => 1,  # inherits OpenAI's table
  Anthropic         => 1,  # claude-sonnet-5
  Gemini            => 1,  # gemini-3-flash-preview
  Hetzner           => 1,  # Qwen/Qwen3.6-35B-A3B-FP8
  # allowlisted cloud engines, default model is a vision model
  DeepSeek          => 1,  # deepseek-flash (V4.1)
  Mistral           => 1,  # mistral-small-latest (Small 4)
  XAI               => 1,  # grok-4.7
  MiniMax           => 1,  # MiniMax-M3
  MiniMaxAnthropic  => 1,  # MiniMax-M3
  Moonshot          => 1,  # kimi-k3
  MoonshotAnthropic => 1,  # kimi-k3 (same rows as Moonshot since k359)
  # allowlisted, default is a preset -> no claim
  Perplexity        => 0,  # sonar
  # allowlisted cloud engines, default model is text-only (Groq has none)
  Cerebras          => 0,  # gpt-oss-120b
  Scaleway          => 0,  # llama-3.3-70b-instruct
  TSystems          => 0,  # gpt-oss-120b
  Groq              => 0,  # probed with a neutral id
  # cloud, no claim
  AKIOpenAI         => 0,  # gpt-oss-120b; qwen3.6/qwen3.8/gemma4 allowlisted (k271/k272)
  NousResearch      => 0,
  # shims
  AKIAnthropic      => 0,
  LMStudioAnthropic => 0,
  # gateways
  OpenRouter        => 0,
  HuggingFace       => 0,
  Replicate         => 0,
  # self-hosted
  vLLM              => 0,
  VLLMHook          => 0,
  SGLang            => 0,
  LlamaCpp          => 0,
  LMStudio          => 0,
  LMStudioOpenAI    => 0,
  Ollama            => 0,
  OllamaOpenAI      => 0,
  # native wire unverified: the role is not composed at all
  AKI               => 0,
);
my %NO_DEFAULT_MODEL = map { $_ => 1 } qw( Groq OpenRouter HuggingFace Replicate VLLMHook OllamaOpenAI );

for my $name ( sort keys %DEFAULT ) {
  my @model = $NO_DEFAULT_MODEL{$name} ? ('some-model') : ();
  is claims( $name, @model ), $DEFAULT{$name},
    "$name default: image_input " . ( $DEFAULT{$name} ? 'claimed' : 'not claimed' );
}

# Guard: a new chat engine must take a position here. OpenAIBase composes
# Role::ImageInput, so a new subclass would otherwise inherit a silent claim.
{
  my @unlisted;
  my @files = path('lib/Langertha/Engine')->children(qr/\.pm\z/);
  for my $file ( sort { $a cmp $b } @files ) {
    ( my $name = $file->basename ) =~ s/\.pm\z//;
    next if $name =~ /Base\z/ || $name eq 'Remote';
    my $class = use_module("Langertha::Engine::$name");
    next unless $class->does('Langertha::Role::Chat');
    push @unlisted, $name unless exists $DEFAULT{$name};
  }
  is_deeply \@unlisted, [], 'every chat engine has a decided image_input default';
}

# ---------------------------------------------------------------------------
# 2. The role marks the wire; the flag marks the model. Engines whose wire
#    carries images since k267 compose the role even where they do not claim.
# ---------------------------------------------------------------------------
for my $name (qw( OpenAIResponses Perplexity Ollama LMStudio vLLM OpenRouter AKIAnthropic )) {
  ok engine( $name, model => 'm' )->does('Langertha::Role::ImageInput'),
    "$name composes Role::ImageInput (wire carries images)";
}
ok !engine( 'AKI', model => 'm' )->does('Langertha::Role::ImageInput'),
  'AKI native does not compose Role::ImageInput (wire unverified)';

# ---------------------------------------------------------------------------
# 3. Model patterns, both directions, inside one engine.
# ---------------------------------------------------------------------------
my @ROWS = (
  # engine            model                          claim
  [ OpenAI          => 'gpt-4o'                      => 1 ],
  [ OpenAI          => 'gpt-4-turbo'                 => 1 ],
  [ OpenAI          => 'o3'                          => 1 ],
  [ OpenAI          => 'gpt-future-9'                => 1 ],  # family default
  [ OpenAI          => 'gpt-3.5-turbo'               => 0 ],
  [ OpenAI          => 'gpt-4'                       => 0 ],
  [ OpenAI          => 'gpt-4-0613'                  => 0 ],
  [ OpenAI          => 'gpt-4-1106-preview'          => 0 ],
  [ OpenAI          => 'o1-mini'                     => 0 ],
  [ OpenAI          => 'o3-mini'                     => 0 ],
  [ OpenAI          => 'gpt-4o-audio-preview'        => 0 ],
  [ OpenAI          => 'text-embedding-3-large'      => 0 ],
  [ OpenAI          => 'gpt-4-0314'                  => 0 ],
  [ OpenAI          => 'gpt-4-32k-0613'              => 0 ],
  [ OpenAI          => 'o1-preview'                  => 0 ],
  [ OpenAI          => 'gpt-image-1'                 => 0 ],
  [ OpenAI          => 'gpt-realtime'                => 0 ],
  [ OpenAI          => 'gpt-audio'                   => 0 ],
  [ OpenAI          => 'gpt-4o-mini-transcribe'      => 0 ],
  [ OpenAI          => 'tts-1-hd'                    => 0 ],
  [ OpenAI          => 'gpt-4-turbo-2024-04-09'      => 1 ],
  [ OpenAI          => 'gpt-4.1'                     => 1 ],
  [ OpenAIResponses => 'gpt-5.5-pro'                 => 1 ],
  [ OpenAIResponses => 'gpt-3.5-turbo'               => 0 ],
  [ Anthropic       => 'claude-3-haiku-20240307'     => 1 ],
  [ Anthropic       => 'claude-opus-5'               => 1 ],
  [ Anthropic       => 'claude-2.1'                  => 0 ],
  [ Anthropic       => 'claude-instant-1.2'          => 0 ],
  [ Gemini          => 'gemini-2.5-pro'              => 1 ],
  [ Gemini          => 'gemini-1.5-flash'            => 1 ],
  [ Gemini          => 'gemini-1.0-pro'              => 0 ],
  [ Gemini          => 'gemini-2.5-flash-preview-tts'=> 0 ],
  [ Gemini          => 'text-embedding-004'          => 0 ],
  [ Gemini          => 'gemma-3-27b-it'              => 1 ],  # Gemma 3+ multimodal
  [ Gemini          => 'gemma-4-31b-it'              => 1 ],
  [ Gemini          => 'gemma-2-9b-it'               => 0 ],
  [ Gemini          => 'gemma-3-1b-it'               => 0 ],
  [ Gemini          => 'gemini-2.5-flash-native-audio-dialog' => 0 ],
  [ Gemini          => 'gemini-live-2.5-flash'       => 0 ],
  [ Gemini          => 'lyria-realtime-exp'          => 0 ],
  [ Hetzner         => 'Qwen3.8-27B'                 => 1 ],
  [ DeepSeek        => 'deepseek-v4-pro'             => 0 ],
  [ DeepSeek        => 'deepseek-chat'               => 0 ],
  [ DeepSeek        => 'deepseek-v4-flash'           => 1 ],  # legacy id, served by V4.1-Flash (k280)
  [ DeepSeek        => 'deepseek-v4-flash-vision-exp'=> 1 ],  # legacy id (k280)
  [ DeepSeek        => 'deepseek-v4-flash-x'         => 0 ],  # anchored alias rows
  [ DeepSeek        => 'deepseek-v4-pro-0813'        => 0 ],  # V4-Pro, no vision
  [ Mistral         => 'pixtral-large-latest'        => 1 ],
  [ Mistral         => 'codestral-latest'            => 0 ],
  [ Mistral         => 'mistral-medium-latest'       => 1 ],
  [ Mistral         => 'mistral-large-latest'        => 1 ],
  [ Mistral         => 'mistral-small-2503'          => 1 ],
  [ Mistral         => 'mistral-small-2603'          => 1 ],
  [ Mistral         => 'mistral-medium-2508'         => 1 ],
  [ Mistral         => 'mistral-large-2512'          => 1 ],
  [ Mistral         => 'ministral-8b-2512'           => 1 ],
  [ Mistral         => 'mistral-small-2501'          => 0 ],
  [ Mistral         => 'mistral-small-2409'          => 0 ],
  [ Mistral         => 'mistral-large-2411'          => 0 ],
  [ Mistral         => 'mistral-large-2407'          => 0 ],
  [ Mistral         => 'ministral-8b-2410'           => 0 ],
  [ Mistral         => 'open-mistral-nemo'           => 0 ],
  [ Mistral         => 'mistral-medium-3-5'          => 1 ],  # Medium 3.5 card alias (k280)
  [ Mistral         => 'mistral-medium-3'            => 1 ],  # Medium 3.5 card alias (k280)
  [ Mistral         => 'mistral-medium-3-6'          => 0 ],  # anchored, unconfirmed
  [ Mistral         => 'ministral-3b-latest'         => 1 ],  # Ministral 3 alias (k280)
  [ Mistral         => 'ministral-14b-latest'        => 1 ],
  [ Mistral         => 'ministral-8b-latest-x'       => 0 ],  # anchored
  [ XAI             => 'grok-4.7-fast'               => 1 ],
  [ XAI             => 'grok-3'                      => 0 ],
  [ XAI             => 'grok-4.3'                    => 1 ],  # every grok-4.x lists image input (k280)
  [ XAI             => 'grok-4.3-latest'             => 1 ],
  [ XAI             => 'grok-4.5'                    => 1 ],
  [ XAI             => 'grok-4.6'                    => 1 ],
  [ XAI             => 'grok-4.75'                   => 1 ],  # family-wide since k280
  [ XAI             => 'grok-4.20-reasoning'         => 1 ],
  [ XAI             => 'grok-4.20-multi-agent'       => 1 ],
  [ XAI             => 'grok-4-0709'                 => 1 ],  # retired, redirects to grok-4.3
  [ XAI             => 'grok-4-1-fast-reasoning'     => 1 ],
  [ XAI             => 'grok-4'                      => 1 ],
  [ XAI             => 'grok-40'                     => 0 ],  # multi-digit guard on the major
  [ XAI             => 'grok-build-0.1'              => 1 ],
  [ XAI             => 'grok-code-fast-1'            => 1 ],
  [ XAI             => 'grok-code-fast'              => 1 ],
  [ XAI             => 'grok-3-mini'                 => 0 ],
  [ MiniMax         => 'MiniMax-M2.7'                => 0 ],
  [ MiniMaxAnthropic=> 'MiniMax-M2.5'                => 0 ],
  [ Moonshot        => 'kimi-k2.6'                   => 1 ],
  [ Moonshot        => 'kimi-k2.7-code'              => 1 ],
  [ Moonshot        => 'kimi-k2.7-code-highspeed'    => 1 ],
  [ Moonshot        => 'kimi-k2.5'                   => 0 ],
  [ Moonshot        => 'kimi-k30'                    => 0 ],  # multi-digit guard
  # k359: the /anthropic face serves the same Kimi models and its Messages
  # schema carries images (tool_result text | image too), so it takes
  # Engine::Moonshot's rows instead of the engine-wide no-claim. It matters
  # beyond reporting: the flag now picks the Anthropic tool-result image form.
  [ MoonshotAnthropic => 'kimi-k3'                   => 1 ],
  [ MoonshotAnthropic => 'kimi-k2.6'                 => 1 ],
  [ MoonshotAnthropic => 'kimi-k2.7-code'            => 1 ],
  [ MoonshotAnthropic => 'kimi-k2.7-code-highspeed'  => 1 ],
  [ MoonshotAnthropic => 'kimi-k2.5'                 => 0 ],
  [ MoonshotAnthropic => 'kimi-k30'                  => 0 ],  # multi-digit guard
  [ Cerebras        => 'qwen-3.8-27b'                => 1 ],
  [ Cerebras        => 'gemma-4-31b'                 => 1 ],
  [ Cerebras        => 'kimi-k2.7-code'              => 1 ],
  [ Cerebras        => 'zai-glm-4.7'                 => 0 ],
  [ Scaleway        => 'pixtral-12b-2409'            => 1 ],
  [ Scaleway        => 'mistral-small-3.2-24b-instruct-2506' => 1 ],
  [ Scaleway        => 'gemma-3-27b-it'              => 1 ],
  [ Scaleway        => 'qwen3.5-35b-a3b'             => 1 ],
  [ Scaleway        => 'holo2-30b-a3b'               => 1 ],
  [ Scaleway        => 'llama-3.3-70b-instruct'      => 0 ],
  [ Scaleway        => 'mistral-small-3.0'           => 0 ],
  [ TSystems        => 'qwen-3.6-35b-fp8'            => 1 ],
  [ TSystems        => 'Qwen3.6-35B-A3B-FP8'         => 1 ],  # case + dash variant
  [ TSystems        => 'Gemma-4-31B'                 => 1 ],
  [ TSystems        => 'glm-5.3-flash'               => 1 ],
  [ TSystems        => 'Mistral-Small-4'             => 1 ],
  [ TSystems        => 'mistral-medium-3'            => 1 ],
  [ TSystems        => 'gpt-5'                       => 1 ],
  [ TSystems        => 'GPT-5-mini'                  => 1 ],
  [ TSystems        => 'gpt-5-codex'                 => 1 ],
  [ TSystems        => 'gpt-5.6-terra'               => 0 ],  # documented text-only (k280)
  [ TSystems        => 'gpt-5.6-luna'                => 0 ],
  [ TSystems        => 'gpt-5.6-sol'                 => 0 ],
  [ TSystems        => 'gpt-5.5'                     => 0 ],
  [ TSystems        => 'gpt-5.4'                     => 0 ],
  [ TSystems        => 'gpt-5.4-mini'                => 0 ],
  [ TSystems        => 'gpt-oss-120b'                => 0 ],
  [ TSystems        => 'claude-sonnet-4.5'           => 1 ],
  [ TSystems        => 'Claude-4.6-Opus'             => 1 ],
  [ TSystems        => 'gemini-3-flash'              => 1 ],
  [ TSystems        => 'gemini-3-pro'                => 1 ],
  [ TSystems        => 'gemini-3-pro-long-context'   => 1 ],
  [ TSystems        => 'gemini-3-pro-image'          => 1 ],
  [ TSystems        => 'gemini-3.1-pro'              => 0 ],  # documented text-only (k280)
  [ TSystems        => 'gemini-3.1-pro-long-context' => 0 ],
  [ TSystems        => 'gemini-3.5-flash'            => 0 ],
  [ TSystems        => 'claude-haiku-4.5'            => 1 ],
  [ TSystems        => 'claude-opus-4.6'             => 1 ],
  [ TSystems        => 'claude-opus-4.8'             => 0 ],  # documented text-only
  [ TSystems        => 'claude-opus-5'               => 0 ],
  [ TSystems        => 'claude-sonnet-5'             => 0 ],
  [ TSystems        => 'GLM-5.2'                     => 0 ],
  [ TSystems        => 'GLM-5.3-Flash-Preview'       => 1 ],
  [ TSystems        => 'Mistral-Small-4-119B-2603'   => 1 ],
  [ TSystems        => 'Qwen3.8-27B-FP8-Preview'     => 1 ],
  [ TSystems        => 'gemma-4-31B-it-FP8'          => 1 ],
  [ TSystems        => 'Llama-3.3-70B-Instruct'      => 0 ],
  [ TSystems        => 'claude-sonnet-4'             => 0 ],
  [ TSystems        => 'qwen-3.65'                   => 0 ],  # multi-digit guard
  [ Groq            => 'qwen/qwen3.8-27b'            => 1 ],
  [ Groq            => 'llama-3.3-70b-versatile'     => 0 ],
  [ AKIOpenAI       => 'qwen3.6-chat-35b'            => 1 ],  # live probe k271
  [ AKIOpenAI       => 'qwen3.6-35b'                 => 1 ],
  [ AKIOpenAI       => 'qwen3.65-35b'                => 0 ],  # multi-digit guard
  [ AKIOpenAI       => 'qwen3.8-27b'                 => 1 ],  # live probe k272
  [ AKIOpenAI       => 'qwen3.85-27b'                => 0 ],  # multi-digit guard
  [ AKIOpenAI       => 'gemma4-chat-26b'             => 1 ],  # live probe k272
  [ AKIOpenAI       => 'gemma4-26b'                  => 1 ],  # family of the probed chat variant
  [ AKIOpenAI       => 'gemma45-26b'                 => 0 ],  # multi-digit guard
  [ AKIOpenAI       => 'apertus-chat-70b'            => 0 ],  # unprobed
  [ AKIOpenAI       => 'mistral4-119b'               => 0 ],  # unprobed
  [ AKIOpenAI       => 'gpt-oss-120b'                => 0 ],
  [ AKIOpenAI       => 'llama3-chat-70b'             => 0 ],
  [ Perplexity      => 'openai/gpt-5.6-luna'         => 1 ],
  [ Perplexity      => 'anthropic/claude-sonnet-5'   => 1 ],
  [ Perplexity      => 'google/gemini-3-flash'       => 1 ],
  [ Perplexity      => 'openai/gpt-oss-120b'         => 0 ],
  [ Perplexity      => 'sonar-pro'                   => 0 ],
  # no-claim engines stay silent even for a well-known vision model
  [ OpenRouter      => 'openai/gpt-4o'               => 0 ],
  [ vLLM            => 'Qwen/Qwen2.5-VL-7B-Instruct' => 0 ],
  [ Ollama          => 'llava'                       => 0 ],
);
for my $row (@ROWS) {
  my ( $name, $model, $want ) = @$row;
  is claims( $name, $model ), $want,
    "$name $model: image_input " . ( $want ? 'claimed' : 'not claimed' );
}

# Same engine, different model => different answer (the flag is model-scoped).
isnt claims( OpenAI => 'gpt-4o' ), claims( OpenAI => 'gpt-3.5-turbo' ),
  'OpenAI: two models disagree';
isnt claims( MiniMax => 'MiniMax-M3' ), claims( MiniMax => 'MiniMax-M2.7' ),
  'MiniMax: two models disagree';

# The catch-all row also holds for an empty model id (ADR 0019 k209 Update).
is claims( DeepSeek => '' ), 0, 'DeepSeek with an empty model makes no claim';

# Groq has no default model: supports() must still answer (no croak) and make
# no claim, as the per-model table cannot run without a model.
{
  my $groq = Langertha::Engine::Groq->new( api_key => 'k' );
  my $claim = eval { $groq->supports('image_input') ? 1 : 0 };
  is $claim, 0, 'Groq without a model: supports(image_input) answers 0, no croak'
    or diag $@;
  ok eval { $groq->supports('streaming'); 1 }, 'Groq without a model: other flags still answer';
}

# ---------------------------------------------------------------------------
# 4. Advisory: no claim never blocks. An image on a no-claim engine/model is
#    serialized and sent exactly as on a claiming one.
# ---------------------------------------------------------------------------
{
  my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
  my $img  = Langertha::Content::Image->from_base64( 'Zm9v', media_type => 'image/png' );
  my $msg  = { role => 'user', content => [ 'what is this?', $img ] };
  my $off  = engine( Scaleway => model => 'llama-3.1-8b-instruct' );
  my $on   = engine( OpenAI   => model => 'gpt-4o' );
  ok !$off->supports('image_input'), 'Scaleway llama-3.1-8b makes no claim';
  my ( $body_off, $body_on ) = map {
    my $e = $_;
    my $req = eval { $e->chat($msg) };
    ok defined $req, ref($e) . ': the request is built' or diag $@;
    $req ? $json->decode( $req->content ) : {};
  } $off, $on;
  is_deeply $body_off->{messages}[-1], $body_on->{messages}[-1],
    'the image part goes on the wire with or without the claim';
  is $body_off->{messages}[-1]{content}[1]{type}, 'image_url', 'the image part is there';
}

done_testing;
