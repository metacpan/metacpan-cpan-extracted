#!/usr/bin/env perl
# ABSTRACT: Self-hosted runtime knobs (karr #31) — value object, request-body extension, capabilities, response

# karr #31: the only genuinely per-request knobs on the self-hosted
# OpenAI-compatible engines (vLLM, SGLang, llama.cpp) are prefix-cache
# isolation/reuse controls. They serialize as top-level request-body fields
# via Langertha::Runtime::Knobs (ADR 0004 — no raw extra_body side-channel),
# dispatched by each engine's knob_wire_format. Speculative decoding is a
# server-launch concern on all three engines, NOT a per-request knob.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Runtime::Knobs;
use Langertha::Engine::vLLM;
use Langertha::Engine::SGLang;
use Langertha::Engine::LlamaCpp;
use Langertha::Engine::OpenAI;
use Langertha::Response;
use Langertha::Stream::Chunk;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# Simulate what chat_f does: canonical controls arrive under `controls`.
sub wire {
  my ( $engine, %extra ) = @_;
  return $json->decode(
    $engine->chat_request( $engine->chat_messages('testprompt'), %extra )->content
  );
}

# --- Value object serializers ---------------------------------------------
{
  # vllm: ONLY cache_salt; every other knob is clamped away.
  my $k = Langertha::Runtime::Knobs->new(
    prefix_cache_salt => 'salt-1',
    n_cache_reuse     => 5,
    cache_prompt      => 1,
    priority          => 9,
  );
  is_deeply( { $k->to('vllm') }, { cache_salt => 'salt-1' },
    'to(vllm) emits ONLY cache_salt (other knobs clamped away)' );

  # sglang: its 4 fields; llama.cpp-only knobs are dropped.
  my $s = Langertha::Runtime::Knobs->new(
    prefix_cache_salt            => 'salt-2',
    extra_key                   => 'ek',
    priority                    => 3,
    return_cached_tokens_details => 1,
    n_cache_reuse               => 9,
    id_slot                     => 4,
  );
  is_deeply( { $s->to('sglang') }, {
    cache_salt                   => 'salt-2',
    extra_key                    => 'ek',
    priority                     => 3,
    return_cached_tokens_details => JSON->true,
  }, 'to(sglang) emits its 4 fields, drops llamacpp-only knobs' );

  # llamacpp: its 3 fields; vllm/sglang-only knobs are dropped.
  my $l = Langertha::Runtime::Knobs->new(
    cache_prompt  => 0,
    n_cache_reuse => 2,
    id_slot       => 7,
    priority      => 1,
    extra_key     => 'x',
  );
  is_deeply( { $l->to('llamacpp') }, {
    cache_prompt  => JSON->false,
    n_cache_reuse => 2,
    id_slot       => 7,
  }, 'to(llamacpp) emits its 3 fields, drops vllm/sglang-only knobs' );

  # Empty list when nothing set.
  my $empty = Langertha::Runtime::Knobs->new;
  is_deeply( { $empty->to('vllm') },     {}, 'to(vllm) empty when nothing set' );
  is_deeply( { $empty->to('sglang') },   {}, 'to(sglang) empty when nothing set' );
  is_deeply( { $empty->to('llamacpp') }, {}, 'to(llamacpp) empty when nothing set' );

  # A knob that is set but belongs to no dialect of the target wire -> empty.
  my $only_llama = Langertha::Runtime::Knobs->new( n_cache_reuse => 2 );
  is_deeply( { $only_llama->to('vllm') },   {}, 'to(vllm) empty when only n_cache_reuse set' );
  is_deeply( { $only_llama->to('sglang') }, {}, 'to(sglang) empty when only n_cache_reuse set' );

  # Croak on unknown format.
  my $k2 = Langertha::Runtime::Knobs->new( prefix_cache_salt => 'x' );
  ok( !eval { $k2->to('openai'); 1 }, 'to() dies on unknown format' );
  like( $@, qr/unknown knob wire format 'openai'/, 'to() croaks with the format named' );
}

# --- Request-body extension: attributes -----------------------------------
{
  my $vllm = Langertha::Engine::vLLM->new(
    url               => 'http://localhost:8000/v1',
    prefix_cache_salt => 'tenant-a',
  );
  my $body = wire($vllm);
  is( $body->{cache_salt}, 'tenant-a', 'vLLM: cache_salt lands top-level' );
  ok( !exists $body->{cache_prompt}, 'vLLM: no llamacpp cache_prompt' );
  ok( !exists $body->{n_cache_reuse}, 'vLLM: no llamacpp n_cache_reuse' );
  ok( !exists $body->{extra_key}, 'vLLM: no sglang extra_key' );
  ok( !exists $body->{priority}, 'vLLM: no sglang priority' );
  ok( !exists $body->{return_cached_tokens_details}, 'vLLM: no sglang return_cached_tokens_details' );

  my $sglang = Langertha::Engine::SGLang->new(
    url                         => 'http://localhost:30000/v1',
    prefix_cache_salt           => 'salt',
    extra_key                   => 'ek',
    priority                    => 2,
    return_cached_tokens_details => 1,
  );
  my $sbody = wire($sglang);
  is( $sbody->{cache_salt}, 'salt', 'SGLang: cache_salt lands top-level' );
  is( $sbody->{extra_key}, 'ek', 'SGLang: extra_key lands top-level' );
  is( $sbody->{priority}, 2, 'SGLang: priority lands top-level' );
  is( $sbody->{return_cached_tokens_details}, JSON->true,
    'SGLang: return_cached_tokens_details lands top-level as JSON true' );
  ok( !exists $sbody->{cache_prompt}, 'SGLang: no llamacpp cache_prompt' );
  ok( !exists $sbody->{n_cache_reuse}, 'SGLang: no llamacpp n_cache_reuse' );
  ok( !exists $sbody->{id_slot}, 'SGLang: no llamacpp id_slot' );

  my $llama = Langertha::Engine::LlamaCpp->new(
    url          => 'http://localhost:8080/v1',
    cache_prompt => 1,
    n_cache_reuse => 3,
    id_slot       => 5,
  );
  my $lbody = wire($llama);
  is( $lbody->{cache_prompt}, JSON->true, 'LlamaCpp: cache_prompt lands top-level as JSON true' );
  is( $lbody->{n_cache_reuse}, 3, 'LlamaCpp: n_cache_reuse lands top-level' );
  is( $lbody->{id_slot}, 5, 'LlamaCpp: id_slot lands top-level' );
  ok( !exists $lbody->{cache_salt}, 'LlamaCpp: no vllm/sglang cache_salt' );
  ok( !exists $lbody->{extra_key}, 'LlamaCpp: no sglang extra_key' );
  ok( !exists $lbody->{priority}, 'LlamaCpp: no sglang priority' );
}

# --- Request-body extension: per-request controls beat attributes ----------
{
  my $vllm = Langertha::Engine::vLLM->new(
    url               => 'http://localhost:8000/v1',
    prefix_cache_salt => 'attr-salt',
  );
  my $body = wire( $vllm, controls => { prefix_cache_salt => 'ctrl-salt' } );
  is( $body->{cache_salt}, 'ctrl-salt',
    'vLLM: per-request prefix_cache_salt control beats the attribute' );

  # A per-request control on an engine whose wire does not accept it is
  # consumed without emitting (the "not accidentally correct" behavior).
  my $llama = Langertha::Engine::LlamaCpp->new( url => 'http://localhost:8080/v1' );
  my $lbody = wire( $llama, controls => { prefix_cache_salt => 'x', priority => 1 } );
  ok( !exists $lbody->{cache_salt}, 'LlamaCpp: sglang/vllm-only control consumed, not emitted' );
  ok( !exists $lbody->{priority}, 'LlamaCpp: sglang-only priority consumed, not emitted' );
  ok( !exists $lbody->{controls}, 'controls hash is consumed, not leaked' );
}

# --- Engine without the role emits no knob fields --------------------------
{
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'x', model => 'gpt-4o-mini' );
  my $body = wire($openai);
  ok( !exists $body->{cache_salt}, 'OpenAI: no cache_salt (role not composed)' );
  ok( !exists $body->{cache_prompt}, 'OpenAI: no cache_prompt' );
  ok( !exists $body->{n_cache_reuse}, 'OpenAI: no n_cache_reuse' );
  ok( !exists $body->{id_slot}, 'OpenAI: no id_slot' );
  ok( !exists $body->{priority}, 'OpenAI: no priority' );
  ok( !exists $body->{return_cached_tokens_details}, 'OpenAI: no return_cached_tokens_details' );
  ok( !exists $body->{extra_key}, 'OpenAI: no extra_key' );
}

# --- Capabilities ----------------------------------------------------------
{
  ok( Langertha::Engine::vLLM->new( url => 'http://x/v1' )->supports('prefix_caching'),
    'vLLM supports prefix_caching' );
  ok( Langertha::Engine::SGLang->new( url => 'http://x/v1' )->supports('prefix_caching'),
    'SGLang supports prefix_caching' );
  ok( Langertha::Engine::LlamaCpp->new( url => 'http://x/v1' )->supports('prefix_caching'),
    'LlamaCpp supports prefix_caching' );
  ok( !Langertha::Engine::OpenAI->new( api_key => 'x' )->supports('prefix_caching'),
    'OpenAI does not support prefix_caching' );
}

# --- Response: cached_tokens ----------------------------------------------
{
  my $r = Langertha::Response->new( content => 'hi', cached_tokens => 42 );
  ok( $r->has_cached_tokens, 'cached_tokens predicate true when set' );
  is( $r->cached_tokens, 42, 'cached_tokens value' );

  my $plain = Langertha::Response->new( content => 'hi' );
  ok( !$plain->has_cached_tokens, 'cached_tokens predicate false when unset' );
  is( $plain->cached_tokens, undef, 'cached_tokens undef when unset' );

  # clone_with carries every attribute with a predicate automatically.
  my $cloned = $r->clone_with( content => 'bye' );
  is( $cloned->content, 'bye', 'clone_with overrides content' );
  ok( $cloned->has_cached_tokens, 'clone_with carries cached_tokens' );
  is( $cloned->cached_tokens, 42, 'clone_with preserves cached_tokens value' );

  # to_hash / TO_JSON include it when present.
  is( $r->to_hash->{cached_tokens}, 42, 'to_hash includes cached_tokens' );
  ok( !exists $plain->to_hash->{cached_tokens}, 'to_hash omits cached_tokens when unset' );
}

# --- chat_response populates cached_tokens from usage ----------------------
{
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'x', model => 'gpt-4o-mini' );

  my $http = HTTP::Response->new(200, 'OK');
  $http->content( $json->encode({
    id      => 'chatcmpl-1',
    model   => 'gpt-4o-mini',
    choices => [{
      message       => { role => 'assistant', content => 'hi' },
      finish_reason => 'stop',
    }],
    usage => {
      prompt_tokens     => 100,
      completion_tokens => 50,
      total_tokens      => 150,
      prompt_tokens_details => { cached_tokens => 7 },
    },
  }));
  $http->header('Content-Type' => 'application/json');

  my $resp = $openai->chat_response($http);
  ok( $resp->has_cached_tokens, 'chat_response populates cached_tokens' );
  is( $resp->cached_tokens, 7, 'cached_tokens read from usage.prompt_tokens_details.cached_tokens' );

  # No detail block -> no cached_tokens.
  my $http2 = HTTP::Response->new(200, 'OK');
  $http2->content( $json->encode({
    id      => 'chatcmpl-2',
    model   => 'gpt-4o-mini',
    choices => [{
      message       => { role => 'assistant', content => 'hi' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15 },
  }));
  $http2->header('Content-Type' => 'application/json');

  my $resp2 = $openai->chat_response($http2);
  ok( !$resp2->has_cached_tokens, 'no cached_tokens when detail block absent' );
}

# --- streaming: parse_stream_chunk surfaces cached_tokens (karr #61) ------
# The non-streaming lift (above) was the only one karr #31 shipped; the
# streaming path carries usage on the final chunk but must surface
# cached_tokens on the chunk itself too, so stream consumers reading the
# final chunk get the prefix-cache read-back.
{
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'x', model => 'gpt-4o-mini' );

  my $chunk = $openai->parse_stream_chunk({
    choices => [{ delta => { content => '' }, finish_reason => 'stop' }],
    model   => 'gpt-4o-mini',
    usage   => {
      prompt_tokens     => 100,
      completion_tokens => 50,
      total_tokens      => 150,
      prompt_tokens_details => { cached_tokens => 42 },
    },
  });
  isa_ok( $chunk, ['Langertha::Stream::Chunk'], 'final SSE payload parsed into a chunk' );
  ok( $chunk->has_cached_tokens, 'stream chunk surfaces cached_tokens' );
  is( $chunk->cached_tokens, 42,
    'cached_tokens read from usage.prompt_tokens_details.cached_tokens' );
  ok( $chunk->has_usage, 'usage still surfaced on the final chunk' );

  # No detail block -> no cached_tokens, predicate false.
  my $plain = $openai->parse_stream_chunk({
    choices => [{ delta => { content => 'hi' }, finish_reason => 'stop' }],
    usage   => { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15 },
  });
  ok( !$plain->has_cached_tokens, 'no cached_tokens when detail block absent' );
  is( $plain->cached_tokens, undef, 'cached_tokens undef when detail block absent' );

  # cached_tokens => 0 is a real count — the lift must be defined-checked.
  my $zero = $openai->parse_stream_chunk({
    choices => [{ delta => { content => 'hi' }, finish_reason => 'stop' }],
    usage   => { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15,
                 prompt_tokens_details => { cached_tokens => 0 } },
  });
  ok( $zero->has_cached_tokens, 'cached_tokens => 0 surfaces (defined check, not truthy)' );
  is( $zero->cached_tokens, 0, 'cached_tokens value 0' );
}

# --- Response assembled from a streamed final chunk lifts cached_tokens ---
# The Chat role's streaming methods aggregate into chunks (no final Response
# object); consumers build one from the final chunk and forward its usage.
# That forwarding must carry cached_tokens via Response::BUILDARGS (karr #61).
{
  my $resp = Langertha::Response->new(
    content => 'hi',
    usage   => {
      prompt_tokens     => 100,
      completion_tokens => 50,
      total_tokens      => 150,
      prompt_tokens_details => { cached_tokens => 7 },
    },
  );
  ok( $resp->has_cached_tokens,
    'Response built from streamed final-chunk usage carries cached_tokens' );
  is( $resp->cached_tokens, 7, 'cached_tokens lifted from usage in BUILDARGS' );

  # An explicit cached_tokens parameter always wins over the usage lift.
  my $explicit = Langertha::Response->new(
    content       => 'hi',
    cached_tokens => 9,
    usage         => { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15,
                       prompt_tokens_details => { cached_tokens => 7 } },
  );
  is( $explicit->cached_tokens, 9, 'explicit cached_tokens param wins over usage lift' );

  # No detail block -> no cached_tokens, and the caller's usage hash is
  # not polluted by autovivification.
  my $usage_hash = { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15 };
  my $plain = Langertha::Response->new( content => 'hi', usage => $usage_hash );
  ok( !$plain->has_cached_tokens, 'Response without detail block has no cached_tokens' );
  ok( !exists $usage_hash->{prompt_tokens_details},
    'BUILDARGS lift does not autovivify prompt_tokens_details into the usage hash' );
}

done_testing;
