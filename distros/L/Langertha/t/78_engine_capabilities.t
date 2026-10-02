use strict;
use warnings;
use Test2::Bundle::More;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Perplexity;
use Langertha::Engine::Gemini;
use Langertha::Engine::NousResearch;
use Langertha::Engine::AKI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::MiniMax;
use Langertha::Engine::Whisper;
use Langertha::Engine::Ollama;
use Langertha::Engine::DeepSeek;
use Langertha::Engine::Moonshot;
use Langertha::Engine::HuggingFace;
use Langertha::Engine::Replicate;
use Langertha::Engine::AKIOpenAI;
use Langertha::Engine::TSystems;
use Langertha::Engine::MoonshotAnthropic;

use JSON::MaybeXS;

# OpenAI: composes Tools and ResponseFormat -> all flags on.
{
  my $e = Langertha::Engine::OpenAI->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{tools_native},                'openai tools_native';
  ok $caps->{tool_choice_named},           'openai tool_choice_named';
  ok $caps->{tool_choice_any},             'openai tool_choice_any';
  ok $caps->{response_format_json_schema}, 'openai response_format_json_schema';
  ok $caps->{response_format_json_object}, 'openai response_format_json_object';
  ok $caps->{streaming},                   'openai streaming';
  ok $caps->{reasoning_effort},            'openai reasoning_effort';
  ok $caps->{prompt_cache_key},            'openai prompt_cache_key (routing hint)';
  ok !$caps->{prompt_cache},               'openai has no request-side cache enable (automatic)';
  ok $e->supports('tool_choice_named'),    'supports() helper';
  ok !$e->supports('telepathy'),           'supports() returns false for unknown cap';
}

# Perplexity Agent API (Responses envelope): composes ResponseFormat,
# ReasoningEffort and (since k213) Tools, but NOT PromptCache. Corrections: the
# Agent response_format enum is json_schema-only, so json_object is cleared
# (k139); the Agent schema has no tool_choice / parallel_tool_calls, so those
# flags are cleared (k213).
{
  my $e = Langertha::Engine::Perplexity->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{tools_native},                 'perplexity has native function tools (k213)';
  ok !$caps->{tool_choice_auto},            'perplexity has no tool_choice field (k213)';
  # ADR 0005 rewrite direction 1's only exemplar: no named tool_choice, but
  # json_schema response_format is present, so chat_f reroutes a forced tool.
  ok !$caps->{tool_choice_named},           'perplexity has no named tool_choice (ADR 0005 dir-1 exemplar)';
  ok $caps->{response_format_json_schema},  'perplexity has json_schema';
  ok !$caps->{response_format_json_object}, 'perplexity Agent enum is json_schema-only (no json_object)';
  ok $caps->{reasoning_effort},             'perplexity Agent accepts reasoning_effort (wire reasoning.effort)';
  ok !$caps->{prompt_cache},                'perplexity has no cache enable';
  ok !$caps->{prompt_cache_key},            'perplexity has no prompt_cache_key (caching is automatic)';
}

# MiniMax (OpenAI endpoint): inherits ReasoningEffort via OpenAIBase, but only
# MiniMax-M3 can turn thinking off (karr k209), so the capability is per model:
# kept on M3 (the default), cleared on M2.x.
{
  my $e = Langertha::Engine::MiniMax->new( api_key => 'x', model => 'MiniMax-M2.7' );
  my $caps = $e->engine_capabilities;
  ok !$caps->{reasoning_effort}, 'minimax(openai) M2.7 clears reasoning_effort';
  ok !$e->supports('reasoning_effort'), 'minimax M2.7 supports() reasoning_effort false';
  ok( Langertha::Engine::MiniMax->new( api_key => 'x' )->supports('reasoning_effort'),
    'minimax M3 (default) supports() reasoning_effort (thinking toggle)' );
}

# Gemini: composes Tools (so all tool_choice flags are on by default;
# the engine translates the named form into toolConfig internally).
# Reasoning knob is model-gated: Gemini 3 (default) advertises
# reasoning_effort; Gemini 2.5-* advertises thinking_budget; never both.
{
  # Default model = gemini-3-flash-preview -> Gemini 3 line
  my $e3 = Langertha::Engine::Gemini->new( api_key => 'x' );
  my $c3 = $e3->engine_capabilities;
  ok $c3->{tools_native},      'gemini-3 tools_native';
  ok $c3->{tool_choice_named},  'gemini-3 tool_choice_named (translated to toolConfig)';
  ok $c3->{reasoning_effort},   'gemini-3 advertises reasoning_effort (thinkingLevel)';
  ok !$c3->{thinking_budget},   'gemini-3 does NOT advertise thinking_budget';
  ok !$c3->{prompt_cache},      'gemini-3 has no request-side cache enable';
  ok !$c3->{prompt_cache_key},  'gemini-3 has no prompt_cache_key';
  ok !$c3->{parallel_tool_use}, 'gemini-3 has no parallel_tool_use (no parallel knob in ToolConfig, k241)';

  # Gemini 2.5 model: thinking_budget on, reasoning_effort off
  my $e25 = Langertha::Engine::Gemini->new( api_key => 'x', model => 'gemini-2.5-pro' );
  my $c25 = $e25->engine_capabilities;
  ok $c25->{thinking_budget},   'gemini-2.5 advertises thinking_budget';
  ok !$c25->{reasoning_effort}, 'gemini-2.5 does NOT advertise reasoning_effort (no level vocabulary)';
  ok $e25->supports('thinking_budget'), 'gemini-2.5 supports() thinking_budget true';
  ok !$e25->supports('reasoning_effort'), 'gemini-2.5 supports() reasoning_effort false';
}

# OpenAI: full grab-bag of caps from composed roles.
{
  my $e = Langertha::Engine::OpenAI->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{chat},          'openai chat';
  ok $caps->{embedding},     'openai embedding (composed role)';
  ok $caps->{transcription}, 'openai transcription (composed role)';
  ok $caps->{system_prompt}, 'openai system_prompt';
  ok $caps->{temperature},   'openai temperature';
  ok $caps->{response_size}, 'openai response_size';
}

# The hermes wire (NousResearch, AKI native) composes Tools + HermesTools but
# has no tools / tool_choice body key: the tools ride the system prompt, which
# cannot force a tool (karr k234, ADR 0002 honesty). Role::HermesTools clears
# the native flags; auto is what the prompt says, none withholds the tools
# (k231). With tool_choice_named gone, NousResearch's json_schema flag makes
# the ADR 0005 forced-tool rewrite fire (t/69_chat_f_wire_tools.t).
for my $e (
  Langertha::Engine::NousResearch->new( api_key => 'x' ),
  Langertha::Engine::AKI->new( api_key => 'x' ),
) {
  my $name = lc( ( split /::/, ref $e )[-1] );
  my $caps = $e->engine_capabilities;
  ok $caps->{tools_hermes},       "$name tools_hermes (composes HermesTools)";
  ok $caps->{tool_choice_auto},   "$name tool_choice_auto (the prompt offers the tools)";
  ok $caps->{tool_choice_none},   "$name tool_choice_none (the tools are withheld)";
  ok !$caps->{$_}, "$name no $_ (no native tools wire)"
    for qw( tools_native tool_choice_any tool_choice_named parallel_tool_use );
}
ok( Langertha::Engine::NousResearch->new( api_key => 'x' )->supports('response_format_json_schema'),
  'nousresearch keeps response_format_json_schema (the rewrite target)' );

# Anthropic: tools + streaming, but no ResponseFormat role yet.
{
  my $e = Langertha::Engine::Anthropic->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{tools_native},      'anthropic tools_native';
  ok $caps->{tool_choice_named}, 'anthropic tool_choice_named';
  ok $caps->{streaming},         'anthropic streaming';
  ok $caps->{reasoning_effort},  'anthropic reasoning_effort';
  ok $caps->{prompt_cache},      'anthropic prompt_cache (cache_control enable)';
  ok !$caps->{prompt_cache_key}, 'anthropic has no OpenAI-style prompt_cache_key';
}

# Whisper extends OpenAI but is really a transcription endpoint —
# the chat plumbing is inherited but not part of the wire reality.
# Today we leave the inherited caps; if/when we restrict, this test
# will need to follow.
{
  my $e = Langertha::Engine::Whisper->new( api_key => 'x', url => 'http://x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{transcription}, 'whisper transcription';
}

# Ollama (native /api/chat) composes Role::KeepAlive. The knob is a real wire
# field, so it has to be advertised too — the request-body assertion is what
# keeps the flag honest: a registry entry that no longer matches the wire
# would still satisfy supports() on its own (karr #90).
{
  my $e = Langertha::Engine::Ollama->new(
    url        => 'http://test.url:12345',
    model      => 'model',
    keep_alive => '5m',
  );
  ok $e->supports('keep_alive'), 'ollama advertises keep_alive (composes Role::KeepAlive)';
  ok $e->supports('tools_native'), 'ollama keeps tools_native';
  ok !$e->supports($_), "ollama has no $_ (no such field on /api/chat, k239/k241)"
    for qw( tool_choice_auto tool_choice_any tool_choice_none tool_choice_named parallel_tool_use );
  my $body = JSON::MaybeXS->new->utf8(1)->decode( $e->chat('testprompt')->content );
  is $body->{keep_alive}, '5m', 'ollama puts keep_alive on the wire (flag matches reality)';
}

# OpenAI does not compose the role: no knob, no flag.
{
  my $e = Langertha::Engine::OpenAI->new( api_key => 'x' );
  ok !$e->supports('keep_alive'), 'openai does not advertise keep_alive (role not composed)';
  ok !$e->can('get_keep_alive'),  'openai has no keep-alive surface at all';
}

# parallel_tool_use means the wire documents parallel_tool_calls (k242, ADR
# 0002). None of these chat/completions endpoints does: DeepSeek ignores it,
# Moonshot/Kimi, the HuggingFace router and AKI.IO leave it out of the chat
# schema, Replicate's OpenAPI has no chat/completions path at all. With the flag
# on, a caller's parallel_tool_use=0 goes out and is silently not honored;
# cleared, k241 drops it with a carp and the raw kwarg stays the escape hatch.
for my $e (
  Langertha::Engine::DeepSeek->new( api_key => 'x' ),
  Langertha::Engine::Moonshot->new( api_key => 'x' ),
  Langertha::Engine::HuggingFace->new( api_key => 'x', model => 'org/m' ),
  Langertha::Engine::Replicate->new( api_key => 'x', model => 'owner/m' ),
  Langertha::Engine::AKIOpenAI->new( api_key => 'x' ),
) {
  my $name = lc( ( split /::/, ref $e )[-1] );
  ok !$e->supports('parallel_tool_use'), "$name clears parallel_tool_use (not in its chat schema, k242)";
  ok  $e->supports('tools_native'),      "$name keeps tools_native";
}
# TSystems' LLM Server OpenAPI lists parallel_tool_calls on ChatCompletionRequest.
ok( Langertha::Engine::TSystems->new( api_key => 'x' )->supports('parallel_tool_use'),
  'tsystems keeps parallel_tool_use (documented in its OpenAPI, k242)' );
# MoonshotAnthropic rides the /anthropic shim: the field there is
# tool_choice.disable_parallel_tool_use, not the chat/completions
# parallel_tool_calls k242 audited, so the flag stays as on the other shims.
ok( Langertha::Engine::MoonshotAnthropic->new( api_key => 'x' )->supports('parallel_tool_use'),
  'moonshot anthropic shim keeps parallel_tool_use (different field, outside k242)' );

done_testing;
