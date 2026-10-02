#!/usr/bin/env perl
# ABSTRACT: Test Raider engine_catalog and dynamic engine switching

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Groq;
use Langertha::Raider;

# --- Create test engines ---

my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'test-openai-key',
  model   => 'gpt-4o',
);

my $anthropic = Langertha::Engine::Anthropic->new(
  api_key => 'test-anthropic-key',
  model   => 'claude-sonnet-4-6',
);

my $groq = Langertha::Engine::Groq->new(
  api_key => 'test-groq-key',
  model   => 'llama-3.3-70b-versatile',
);

# --- Raider without engine_catalog ---

my $simple_raider = Langertha::Raider->new(
  engine    => $openai,
  raider_mcp => 1,
);

is($simple_raider->active_engine, $openai,
  'active_engine returns default engine without catalog');

is($simple_raider->active_engine_name, undef,
  'active_engine_name is undef without catalog');

is_deeply($simple_raider->engine_info, {
  name  => 'default',
  class => 'Langertha::Engine::OpenAI',
  model => 'gpt-4o',
}, 'engine_info for default engine');

# engine_catalog defaults to empty hashref
is_deeply($simple_raider->engine_catalog, {},
  'engine_catalog defaults to empty hashref');

# --- Raider with engine_catalog ---

my $raider = Langertha::Raider->new(
  engine         => $openai,
  raider_mcp     => 1,
  engine_catalog => {
    general => {
      description => 'General purpose model for everyday tasks',
    },
    fast => {
      engine      => $groq,
      description => 'Fast inference for simple tasks',
    },
    smart => {
      engine      => $anthropic,
      description => 'Claude for complex reasoning',
    },
  },
);

# --- active_engine defaults to engine ---

is($raider->active_engine, $openai,
  'active_engine returns default engine initially');

is($raider->active_engine_name, undef,
  'active_engine_name is undef initially');

# --- catalog entry without engine refers to default engine ---

{
  my $switched = $raider->switch_engine('general');
  is($switched, $openai,
    'switch_engine to engine-less entry returns default engine');
  is($raider->active_engine, $openai,
    'active_engine returns default engine for engine-less catalog entry');
  is($raider->active_engine_name, 'general',
    'active_engine_name is the catalog name, not default');
  is_deeply($raider->engine_info, {
    name  => 'general',
    class => 'Langertha::Engine::OpenAI',
    model => 'gpt-4o',
  }, 'engine_info uses catalog name for engine-less entry');

  my $list = $raider->list_engines;
  is($list->{general}{engine}, $openai,
    'list_engines resolves engine-less entry to default engine');
  is($list->{general}{description}, 'General purpose model for everyday tasks',
    'list_engines preserves description for engine-less entry');
  ok($list->{general}{active}, 'engine-less entry shows as active');
  ok(!$list->{default}{active}, 'default not active when engine-less entry is');

  $raider->reset_engine;
}

# --- switch_engine ---

my $switched = $raider->switch_engine('smart');
is($switched, $anthropic, 'switch_engine returns the new engine');
is($raider->active_engine, $anthropic,
  'active_engine returns switched engine');
is($raider->active_engine_name, 'smart',
  'active_engine_name reflects the switch');

# _tools_dirty should be set
ok($raider->_tools_dirty, '_tools_dirty set after switch_engine');
$raider->_tools_dirty(0);  # reset for next test

# --- engine_info after switch ---

is_deeply($raider->engine_info, {
  name  => 'smart',
  class => 'Langertha::Engine::Anthropic',
  model => 'claude-sonnet-4-6',
}, 'engine_info after switch_engine');

# --- switch to another engine ---

$raider->switch_engine('fast');
is($raider->active_engine, $groq,
  'switch to second catalog engine');
is($raider->active_engine_name, 'fast',
  'active_engine_name updated');
ok($raider->_tools_dirty, '_tools_dirty set after second switch');
$raider->_tools_dirty(0);

is_deeply($raider->engine_info, {
  name  => 'fast',
  class => 'Langertha::Engine::Groq',
  model => 'llama-3.3-70b-versatile',
}, 'engine_info after switching to fast');

# --- reset_engine ---

my $default = $raider->reset_engine;
is($default, $openai, 'reset_engine returns default engine');
is($raider->active_engine, $openai,
  'active_engine returns default after reset');
is($raider->active_engine_name, undef,
  'active_engine_name is undef after reset');
ok($raider->_tools_dirty, '_tools_dirty set after reset_engine');
$raider->_tools_dirty(0);

is_deeply($raider->engine_info, {
  name  => 'default',
  class => 'Langertha::Engine::OpenAI',
  model => 'gpt-4o',
}, 'engine_info after reset_engine');

# --- switch_engine with nonexistent name croaks ---

eval { $raider->switch_engine('nonexistent') };
like($@, qr/Engine 'nonexistent' not found in engine_catalog/,
  'switch_engine croaks on unknown engine name');

# active_engine should be unchanged after failed switch
is($raider->active_engine, $openai,
  'active_engine unchanged after failed switch');

# --- list_engines ---

$raider->switch_engine('smart');
$raider->_tools_dirty(0);

my $list = $raider->list_engines;

ok(exists $list->{default}, 'list_engines has default entry');
ok(exists $list->{fast},    'list_engines has fast entry');
ok(exists $list->{smart},   'list_engines has smart entry');

is($list->{default}{engine}, $openai, 'default engine is correct');
ok(!$list->{default}{active}, 'default is not active after switch');

is($list->{smart}{engine}, $anthropic, 'smart engine is correct');
is($list->{smart}{description}, 'Claude for complex reasoning',
  'smart description preserved');
ok($list->{smart}{active}, 'smart is active');

is($list->{fast}{engine}, $groq, 'fast engine is correct');
is($list->{fast}{description}, 'Fast inference for simple tasks',
  'fast description preserved');
ok(!$list->{fast}{active}, 'fast is not active');

# --- reset clears engine state ---

$raider->switch_engine('fast');
$raider->_tools_dirty(0);
is($raider->active_engine_name, 'fast', 'precondition: engine is fast');

$raider->reset;

is($raider->active_engine, $openai,
  'reset clears active engine');
is($raider->active_engine_name, undef,
  'reset clears active engine name');

# --- switch_engine sets _tools_dirty even when already dirty ---

$raider->_tools_dirty(1);
$raider->switch_engine('smart');
ok($raider->_tools_dirty, '_tools_dirty stays set');
$raider->_tools_dirty(0);

# --- reset_engine sets _tools_dirty even when already dirty ---

$raider->_tools_dirty(1);
$raider->reset_engine;
ok($raider->_tools_dirty, '_tools_dirty stays set after reset_engine');

# === Self-tool: raider_switch_engine ===

# --- Tool definition is generated when engine_catalog + raider_mcp are set ---

my $self_tools = $raider->_self_tool_definitions;
my ($switch_tool) = grep { $_->{name} eq 'raider_switch_engine' } @$self_tools;
ok($switch_tool, 'raider_switch_engine self-tool is defined');

# --- Correct enum with default + catalog keys ---

my $enum = $switch_tool->{inputSchema}{properties}{name}{enum};
is_deeply($enum, ['default', 'fast', 'general', 'smart'],
  'enum contains default + sorted catalog keys');

# --- NOT generated for empty catalog ---

my $empty_raider = Langertha::Raider->new(
  engine     => $openai,
  raider_mcp => 1,
);
my $empty_tools = $empty_raider->_self_tool_definitions;
my ($no_switch) = grep { $_->{name} eq 'raider_switch_engine' } @$empty_tools;
ok(!$no_switch, 'raider_switch_engine NOT defined with empty catalog');

# --- NOT generated when switch_engine not enabled ---

my $selective_raider = Langertha::Raider->new(
  engine         => $openai,
  raider_mcp     => { ask_user => 1 },
  engine_catalog => {
    fast => { engine => $groq, description => 'Fast' },
  },
);
my $selective_tools = $selective_raider->_self_tool_definitions;
my ($no_switch2) = grep { $_->{name} eq 'raider_switch_engine' } @$selective_tools;
ok(!$no_switch2, 'raider_switch_engine NOT defined when not enabled in raider_mcp');

# --- _switch_engine_tool switches correctly ---

$raider->reset_engine;
$raider->_tools_dirty(0);

my $result = $raider->_switch_engine_tool({ name => 'smart' });
like($result, qr/Switched to engine 'smart'/,
  '_switch_engine_tool returns success message');
like($result, qr/Langertha::Engine::Anthropic/,
  '_switch_engine_tool message includes class');
is($raider->active_engine, $anthropic,
  'engine actually switched after _switch_engine_tool');

# --- _switch_engine_tool with default resets ---

$result = $raider->_switch_engine_tool({ name => 'default' });
like($result, qr/Switched to default engine/,
  '_switch_engine_tool default returns reset message');
is($raider->active_engine, $openai,
  'engine reset to default after _switch_engine_tool default');
is($raider->active_engine_name, undef,
  'active_engine_name is undef after reset via tool');

# --- _switch_engine_tool with unknown name returns error ---

$result = $raider->_switch_engine_tool({ name => 'nonexistent' });
like($result, qr/Error:.*not found in engine catalog/,
  '_switch_engine_tool returns error for unknown name');

# --- _switch_engine_tool without name returns error ---

$result = $raider->_switch_engine_tool({});
like($result, qr/Error: name required/,
  '_switch_engine_tool returns error when name missing');

# === add_engine ===

$raider->_tools_dirty(0);
my $deepseek = Langertha::Engine::OpenAI->new(
  api_key => 'test-deepseek-key',
  model   => 'deepseek-chat',
);
$raider->add_engine('deep', engine => $deepseek, description => 'DeepSeek');

ok(exists $raider->engine_catalog->{deep},
  'add_engine adds entry to catalog');
is($raider->engine_catalog->{deep}{engine}, $deepseek,
  'add_engine stores correct engine');
is($raider->engine_catalog->{deep}{description}, 'DeepSeek',
  'add_engine stores description');
ok($raider->_tools_dirty, '_tools_dirty set after add_engine');

# Verify the new engine appears in tool definition enum
my $updated_tools = $raider->_self_tool_definitions;
my ($updated_switch) = grep { $_->{name} eq 'raider_switch_engine' } @$updated_tools;
my $updated_enum = $updated_switch->{inputSchema}{properties}{name}{enum};
is_deeply($updated_enum, ['default', 'deep', 'fast', 'general', 'smart'],
  'enum updated after add_engine');

# add_engine without engine creates alias for default
$raider->add_engine('alias', description => 'Alias for default');
is($raider->engine_catalog->{alias}{description}, 'Alias for default',
  'add_engine without engine stores description');
{
  my $a = $raider->switch_engine('alias');
  is($a, $openai, 'engine-less add_engine entry resolves to default engine');
  $raider->reset_engine;
}
delete $raider->engine_catalog->{alias};

# === remove_engine ===

$raider->_tools_dirty(0);
$raider->remove_engine('deep');

ok(!exists $raider->engine_catalog->{deep},
  'remove_engine removes entry from catalog');
ok($raider->_tools_dirty, '_tools_dirty set after remove_engine');

# remove_engine resets active engine if it was the removed one
$raider->switch_engine('fast');
$raider->_tools_dirty(0);
is($raider->active_engine_name, 'fast', 'precondition: active is fast');

$raider->remove_engine('fast');
is($raider->active_engine, $openai,
  'remove_engine resets to default when removing active engine');
is($raider->active_engine_name, undef,
  'active_engine_name is undef after removing active engine');

# remove_engine croaks on unknown name
eval { $raider->remove_engine('nonexistent') };
like($@, qr/Engine 'nonexistent' not found in engine_catalog/,
  'remove_engine croaks on unknown name');

done_testing;
