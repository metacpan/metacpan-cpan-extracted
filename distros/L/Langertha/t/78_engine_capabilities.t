use strict;
use warnings;
use Test::More;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Perplexity;
use Langertha::Engine::Gemini;
use Langertha::Engine::NousResearch;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Whisper;

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
  ok $e->supports('tool_choice_named'),    'supports() helper';
  ok !$e->supports('telepathy'),           'supports() returns false for unknown cap';
}

# Perplexity: inherits ResponseFormat via OpenAIBase, no Tools role.
{
  my $e = Langertha::Engine::Perplexity->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok !$caps->{tools_native},               'perplexity has no native tools yet';
  ok !$caps->{tool_choice_named},          'perplexity has no named tool_choice';
  ok $caps->{response_format_json_schema}, 'perplexity has json_schema';
  ok $caps->{response_format_json_object}, 'perplexity has json_object';
}

# Gemini: composes Tools (so all tool_choice flags are on by default;
# the engine translates the named form into toolConfig internally).
{
  my $e = Langertha::Engine::Gemini->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{tools_native},      'gemini tools_native';
  ok $caps->{tool_choice_named}, 'gemini tool_choice_named (translated to toolConfig)';
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

# NousResearch composes Tools + HermesTools. Both flags should be on.
{
  my $e = Langertha::Engine::NousResearch->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{tools_native},  'nousresearch tools_native (composes Tools)';
  ok $caps->{tools_hermes},  'nousresearch tools_hermes (composes HermesTools)';
}

# Anthropic: tools + streaming, but no ResponseFormat role yet.
{
  my $e = Langertha::Engine::Anthropic->new( api_key => 'x' );
  my $caps = $e->engine_capabilities;
  ok $caps->{tools_native},      'anthropic tools_native';
  ok $caps->{tool_choice_named}, 'anthropic tool_choice_named';
  ok $caps->{streaming},         'anthropic streaming';
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

done_testing;
