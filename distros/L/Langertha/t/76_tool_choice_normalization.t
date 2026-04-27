use strict;
use warnings;
use Test::More;

use Langertha::ToolChoice;

# --- String shorthands ---
for my $s (qw( auto none required any )) {
  my $tc = Langertha::ToolChoice->from_hash($s);
  ok $tc, "from_hash('$s') returns object";
}

# 'required' and 'any' are aliases for the same canonical type
is(Langertha::ToolChoice->from_hash('required')->type, 'any',  "'required' -> type=any");
is(Langertha::ToolChoice->from_hash('any')->type,      'any',  "'any' -> type=any");
is(Langertha::ToolChoice->from_hash('auto')->type,     'auto', "'auto' -> type=auto");
is(Langertha::ToolChoice->from_hash('none')->type,     'none', "'none' -> type=none");

# --- Anthropic-style forced tool ---
{
  my $tc = Langertha::ToolChoice->from_hash({ type => 'tool', name => 'search' });
  is $tc->type, 'tool';
  is $tc->name, 'search';

  is_deeply $tc->to_anthropic, { type => 'tool', name => 'search' },
    'anthropic forced -> anthropic';
  is_deeply $tc->to_openai,
    { type => 'function', function => { name => 'search' } },
    'anthropic forced -> openai';
}

# --- OpenAI-style forced tool ---
{
  my $tc = Langertha::ToolChoice->from_hash({
    type => 'function',
    function => { name => 'search' },
  });
  is $tc->type, 'tool';
  is $tc->name, 'search';

  is_deeply $tc->to_openai,
    { type => 'function', function => { name => 'search' } },
    'openai forced -> openai';
  is_deeply $tc->to_anthropic, { type => 'tool', name => 'search' },
    'openai forced -> anthropic';
}

# --- {type => required} hash form ---
{
  my $tc = Langertha::ToolChoice->from_hash({ type => 'required' });
  is $tc->type, 'any', "{type=>'required'} normalizes to any";
  is $tc->to_openai, 'required';
  is_deeply $tc->to_anthropic, { type => 'any' };
}

# --- auto/none roundtrip ---
{
  my $tc = Langertha::ToolChoice->auto;
  is $tc->to_openai, 'auto';
  is_deeply $tc->to_anthropic, { type => 'auto' };
}
{
  my $tc = Langertha::ToolChoice->none;
  is $tc->to_openai, 'none';
  is_deeply $tc->to_anthropic, { type => 'none' };
}

# --- Perplexity serializer ---
{
  is( Langertha::ToolChoice->auto->to_perplexity, 'auto', 'perplexity auto' );
  is( Langertha::ToolChoice->none->to_perplexity, 'none', 'perplexity none' );
  is( Langertha::ToolChoice->any->to_perplexity,  'required', 'perplexity any -> required' );
  is( Langertha::ToolChoice->specific('foo')->to_perplexity, 'required',
    'perplexity named coerced to required (string-only API)' );
}

# --- Gemini serializer ---
{
  is_deeply(
    Langertha::ToolChoice->auto->to_gemini,
    { functionCallingConfig => { mode => 'AUTO' } },
    'gemini auto',
  );
  is_deeply(
    Langertha::ToolChoice->none->to_gemini,
    { functionCallingConfig => { mode => 'NONE' } },
    'gemini none',
  );
  is_deeply(
    Langertha::ToolChoice->any->to_gemini,
    { functionCallingConfig => { mode => 'ANY' } },
    'gemini any',
  );
  is_deeply(
    Langertha::ToolChoice->specific('extract')->to_gemini,
    { functionCallingConfig => { mode => 'ANY', allowed_function_names => ['extract'] } },
    'gemini named -> ANY + allowlist',
  );
  is_deeply(
    Langertha::ToolChoice->new( type => 'tool' )->to_gemini,
    { functionCallingConfig => { mode => 'AUTO' } },
    'gemini named without name falls back to AUTO',
  );
}

# --- ParallelToolUse alias support via BUILDARGS ---
use Langertha::Role::ParallelToolUse;
{
  # a throwaway Moose class composing the role
  package TestEng;
  use Moose;
  with 'Langertha::Role::ParallelToolUse';
  __PACKAGE__->meta->make_immutable;
}

is(TestEng->new(parallel_tool_use => 0)->parallel_tool_use, 0,
  'canonical name accepted');

is(TestEng->new(parallel_tool_calls => 0)->parallel_tool_use, 0,
  'openai alias parallel_tool_calls=0 -> parallel_tool_use=0');

is(TestEng->new(parallel_tool_calls => 1)->parallel_tool_use, 1,
  'openai alias parallel_tool_calls=1 -> parallel_tool_use=1');

is(TestEng->new(disable_parallel_tool_use => 1)->parallel_tool_use, 0,
  'anthropic alias disable=1 -> parallel=0');

is(TestEng->new(disable_parallel_tool_use => 0)->parallel_tool_use, 1,
  'anthropic alias disable=0 -> parallel=1');

ok !TestEng->new->has_parallel_tool_use, 'unset by default';

done_testing;
