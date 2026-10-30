#!/usr/bin/env perl
# ABSTRACT: The context façade: skill root precedence, bare, AGENTS.md, settings env, explain report (ADR 0019, k151)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Context;
use Langertha::Raider::CLI;

# HOME is a temp dir, CLAUDE_CONFIG_DIR unset: the Claude directory is
# <home>/.claude. Every project is a temp dir beside the home, not below it,
# without .git, so the memory walk is the project alone.

local %ENV = %ENV;
delete $ENV{$_} for grep { /_API_KEY$/ } keys %ENV;
delete $ENV{CLAUDE_CONFIG_DIR};
my $home = path(tempdir(CLEANUP => 1))->realpath;
$ENV{HOME} = "$home";

sub put {
  my ( $base, $rel, $text ) = @_;
  my $f = path($base)->child($rel);
  $f->parent->mkpath;
  $f->spew_utf8($text);
  return $f;
}
sub skill { "---\ndescription: $_[0]\n---\nbody of $_[0]\n" }
sub project { path(tempdir(CLEANUP => 1))->realpath }
sub ctx { Langertha::Raider::Context->new(@_) }
sub names { [ map { $_->{name} } $_[0]->skill_catalog->skills ] }

# The home: native and Claude skills, one installed and enabled plugin.
put($home, '.raider/skills/home-native/SKILL.md', skill('home native'));
put($home, '.raider/skills/dup/SKILL.md', skill('dup from ~/.raider/skills'));
put($home, '.claude/skills/user-claude/SKILL.md', skill('user claude'));
put($home, '.claude/skills/dup/SKILL.md', skill('dup from ~/.claude/skills'));
put($home, '.claude/CLAUDE.md', "User memory.\n");
my $plugin = $home->child('.claude/plugins/cache/m/helper/1.0');
put($plugin, 'skills/tidy/SKILL.md', skill('plugin tidy'));
put($home, '.claude/plugins/installed_plugins.json', JSON::MaybeXS->new->encode({
  version => 2, plugins => { 'helper@m' => [ { scope => 'user', installPath => "$plugin" } ] } }));
put($home, '.claude/settings.json', '{ "enabledPlugins": { "helper@m": true } }');

subtest 'skill roots: explicit, native, Claude, plugins -- the first name wins' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "Project memory.\n");
  put($p, 'mixed/dirskill/SKILL.md', skill('dir skill in mixed'));
  put($p, 'mixed/flatskill.md', "flat skill in mixed\n");
  put($p, 'globbed/onlyflat.md', "only flat\n");
  put($p, 'globbed/notread/SKILL.md', skill('skills layout of a glob spec'));
  put($p, 'tree/treeskill/SKILL.md', skill('claude type'));
  put($p, 'tree/flatnot.md', "not flat in a claude spec\n");
  put($p, '.raider/skills/dup/SKILL.md', skill('dup from .raider/skills'));
  put($p, '.raider/skills/proj-native/SKILL.md', skill('project native'));
  put($p, '.claude/skills/dup/SKILL.md', skill('dup from .claude/skills'));
  put($p, '.claude/skills/proj-claude/SKILL.md', skill('project claude'));
  put($p, '.agents/skills/agents-skill/SKILL.md', skill('agents'));
  put($p, '.agents/skills/proj-claude/SKILL.md', skill('shadowed by .claude/skills'));

  # .raider/skills makes it a raider project: the Claude layout by claude: true.
  my $c = ctx(root => "$p", config_claude => 1, skill_specs => [
    { type => 'dir', path => 'mixed' },
    { type => 'dir', path => 'globbed', glob => '*.md' },
    { type => 'claude', path => "$p/tree" },
  ]);
  is([ $c->mode, $c->claude_layout ], [ 'raider', 1 ], 'raider mode, Claude layout by claude: true');
  is([ map { [ $_->{source}, $_->{layout} ] } @{ $c->skill_roots } ], [
    [ mixed => 'skills' ], [ mixed => 'flat' ], [ globbed => 'flat' ], [ "$p/tree" => 'skills' ],
    [ '.raider/skills' => 'skills' ], [ '~/.raider/skills' => 'skills' ], [ '~/.claude/skills' => 'skills' ],
    [ '.claude/skills' => 'skills' ], [ '.agents/skills' => 'skills' ],
    [ '.raider/commands' => 'commands' ], [ '~/.raider/commands' => 'commands' ],
    [ '~/.claude/commands' => 'commands' ], [ '.claude/commands' => 'commands' ],
  ], 'roots in ADR 0019 §4 order, the command roots of ADR 0030 last');
  is(names($c), [
    'dirskill', 'flatskill', 'onlyflat', 'treeskill',
    'dup', 'proj-native', 'home-native', 'user-claude', 'proj-claude', 'agents-skill',
    'helper:tidy',
  ], 'skills in precedence order, plugin skill last');
  is($c->skill_catalog->find('dup')->{source}, '.raider/skills', 'the project .raider/skills wins dup');
  is([ sort map { $_->{source} } grep { $_->{name} eq 'dup' } $c->skill_catalog->shadowed ],
    [ '.claude/skills', '~/.claude/skills', '~/.raider/skills' ], 'the other dups are shadowed');
  ok($c->has_listed_skills, 'skills listed');
  like(($c->prompt_items)[-1], qr/^- helper:tidy: plugin tidy$/m, 'the listing is the last item');
};

subtest 'raider and native projects: no Claude roots, no memory, no settings' => sub {
  my $raider = project();
  put($raider, '.raider/config.yml', "model: x\n");
  put($raider, 'CLAUDE.md', "Ignored memory.\n");
  put($raider, '.claude/skills/proj-claude/SKILL.md', skill('project claude'));
  my $c = ctx(root => "$raider");
  is($c->mode, 'raider', 'raider mode');
  ok(!$c->claude_layout, 'Claude layout off');
  is($c->memory, undef, 'no memory');
  is($c->settings, undef, 'no settings');
  is(names($c), [qw( dup home-native )], 'only ~/.raider/skills');
  unlike(join("\n", $c->prompt_items), qr/Ignored memory/, 'CLAUDE.md not in the prompt');

  my $on = ctx(root => "$raider", config_claude => 1);
  ok($on->claude_layout, 'claude: true switches it on');
  like(join("\n", $on->prompt_items), qr/Ignored memory/, 'then CLAUDE.md is read');
  is(names($on), [qw( dup home-native user-claude proj-claude helper:tidy )], 'and the Claude roots');

  my $native = project();
  my $n = ctx(root => "$native");
  is($n->mode, 'native', 'native mode');
  is(names($n), [qw( dup home-native )], 'native: ~/.raider/skills only');
  is([ $n->prompt_items ], [ match qr/\ASkills: / ], 'only the listing');
  is(names(ctx(root => "$native", force_claude => 1)), [qw( dup home-native user-claude helper:tidy )],
    'native with --claude: the user Claude roots and plugins');
};

subtest 'bare: nothing at all' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "Project memory.\n");
  put($p, 'AGENTS.md', "Agents.\n");
  put($p, '.claude/settings.json', '{ "env": { "RAIDER_T126_BARE": "x" } }');
  local $ENV{RAIDER_T126_BARE};
  my $c = ctx(root => "$p", bare => 1, force_claude => 1, want_agents_md => 1,
    skill_specs => [ { type => 'dir', path => 'x' } ]);
  is($c->mode, 'bare', 'mode bare');
  is($c->skill_roots, [], 'no roots');
  is(names($c), [], 'no skills');
  is($c->memory, undef, 'no memory');
  is($c->agents_md, undef, 'no AGENTS.md');
  is([ $c->prompt_items ], [], 'no prompt items');
  is([ $c->apply_env ], [], 'no env');
  is($ENV{RAIDER_T126_BARE}, undef, 'nothing set');
  is($c->report->{layout}{mode}, 'bare', 'report says bare');
};

subtest 'AGENTS.md: its own item, never twice' => sub {
  my $native = project();
  put($native, 'AGENTS.md', "Agents rule.\n");
  is(ctx(root => "$native")->agents_md, undef, 'only when asked for');
  my $c = ctx(root => "$native", want_agents_md => 1);
  like($c->agents_md, { label => 'AGENTS.md', kind => 'AGENTS.md', scope => 'project' }, 'item');
  is([ $c->prompt_items ]->[0], "Contents of $native/AGENTS.md (project instructions (AGENTS.md)):\n\nAgents rule.",
    'prompt text');

  my $claude = project();
  put($claude, '.claude/settings.json', '{}');
  put($claude, 'AGENTS.md', "Agents rule.\n");
  my $cc = ctx(root => "$claude", want_agents_md => 1);
  is($cc->mode, 'claude', 'Claude mode by .claude/');
  is($cc->agents_md, undef, 'the memory holds AGENTS.md already');
  my $all = join "\n", $cc->prompt_items;
  is(scalar( () = $all =~ /Agents rule/g ), 1, 'AGENTS.md once in the prompt');
  like($all, qr/\ACodebase and user instructions are shown below\./, 'memory under the Claude Code header');
  is([ map { $_->{label} } $cc->instruction_items ], [ '~/.claude/CLAUDE.md', 'AGENTS.md' ], 'instruction items');
};

subtest 'apply_env: the settings env into %ENV, once' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "x\n");
  put($p, '.claude/settings.json', '{ "env": { "RAIDER_T126_A": "one", "RAIDER_T126_B": 2 } }');
  put($p, '.claude/settings.local.json', '{ "env": { "RAIDER_T126_A": "local" } }');
  local $ENV{RAIDER_T126_A} = 'before';
  local $ENV{RAIDER_T126_B};
  my $c = ctx(root => "$p");
  is([ $c->apply_env ], [qw( RAIDER_T126_A RAIDER_T126_B )], 'keys applied');
  is($ENV{RAIDER_T126_A}, 'local', 'local settings win, and over the process env');
  is($ENV{RAIDER_T126_B}, '2', 'numbers as strings');
  $ENV{RAIDER_T126_A} = 'changed later';
  is([ $c->apply_env ], [qw( RAIDER_T126_A RAIDER_T126_B )], 'again: only the keys');
  is($ENV{RAIDER_T126_A}, 'changed later', 'not applied twice');
  is($c->applied_env, [qw( RAIDER_T126_A RAIDER_T126_B )], 'applied_env');

  my $raider = project();
  put($raider, '.raider.yml', "model: x\n");
  put($raider, '.claude/settings.json', '{ "env": { "RAIDER_T126_C": "no" } }');
  local $ENV{RAIDER_T126_C};
  is([ ctx(root => "$raider")->apply_env ], [], 'raider project: no Claude settings');
  is($ENV{RAIDER_T126_C}, undef, 'nothing set');
};

subtest 'nested_memory_for' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "top\n");
  put($p, 'a/CLAUDE.md', "nested a\n");
  put($p, 'a/f.txt', "f\n");
  my $c = ctx(root => "$p");
  is($c->nested_memory_for('a/f.txt'), "Contents of $p/a/CLAUDE.md (project instructions, checked into the codebase):\n\nnested a",
    'first touch');
  is($c->nested_memory_for("$p/a/f.txt"), undef, 'once');
  is($c->nested_memory_for('/etc/passwd'), undef, 'outside the root');
  is(ctx(root => "$p", bare => 1)->nested_memory_for('a/f.txt'), undef, 'bare: never');
};

subtest 'report: plain data, env names only' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', '@notes.md'."\n");
  put($p, 'notes.md', "imported\n");
  put($p, '.claude/settings.json', JSON::MaybeXS->new->encode({
    env => { RAIDER_T126_SECRET => 'hunter2' },
    permissions => { allow => [ 'Bash(ls)', 'Read' ], deny => ['Bash(rm:*)'], defaultMode => 'acceptEdits' },
    hooks => { PreToolUse => [ { matcher => 'Bash', hooks => [] }, { hooks => [] } ] },
    model => 'opus',
  }));
  put($p, '.claude/settings.local.json', '{ not json');
  put($p, '.claude/skills/hidden/SKILL.md', "---\ndisable-model-invocation: true\n---\nh\n");
  local $ENV{RAIDER_T126_SECRET};
  my $c = ctx(root => "$p");
  $c->apply_env;
  my $r = $c->report;
  my $json = JSON::MaybeXS->new(canonical => 1)->encode($r);
  unlike($json, qr/hunter2/, 'no env value');
  like($r, {
    layout => { mode => 'claude', reason => 'CLAUDE.md in root', claude_layout => 1,
      claude_layout_reason => 'Claude mode', project_dir => "$p" },
    memory => [
      { label => '~/.claude/CLAUDE.md', scope => 'user', kind => 'CLAUDE.md', imports => [] },
      { label => 'CLAUDE.md', scope => 'project', imports => [ "$p/notes.md" ] },
    ],
    settings => {
      files => [
        { label => '~/.claude/settings.json', exists => 1, error => undef },
        { label => '.claude/settings.json', exists => 1, error => undef },
        { label => '.claude/settings.local.json', exists => 1, error => match qr/^invalid JSON/ },
      ],
      permissions => { allow => 2, ask => 0, deny => 1, additional_directories => 0, default_mode => 'acceptEdits' },
      env => ['RAIDER_T126_SECRET'],
      enabled_plugins => ['helper@m'],
      hooks => { PreToolUse => 2 },
      ignored => [ { key => 'model', source => '.claude/settings.json' } ],
    },
    skills => bag {
      item { name => 'hidden', source => '.claude/skills', listed => 0 };
      item { name => 'helper:tidy', source => 'plugin helper', listed => 1 };
      etc;
    },
    plugins => [ { name => 'helper', key => 'helper@m', scope => 'user' } ],
  }, 'shape');
  is(ref $r->{shadowed_skills}, 'ARRAY', 'shadowed_skills');
  is(ref $r->{skill_problems}, 'ARRAY', 'skill_problems');

  my $native = ctx(root => ''.project())->report;
  ok(!exists $native->{settings}, 'no settings outside the Claude layout');
  is($native->{layout}{project_dir}, undef, 'no project dir');
  is($native->{plugins}, [], 'no plugins');
};

subtest 'application: mission items, -M keeps the memory, persona names CLAUDE.md' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "Project memory text.\n");
  put($p, '.claude/skills/greet/SKILL.md', skill('greets'));
  my %a = ( root => "$p", engine => 'openai', api_key => 'x', trace => 0 );
  my $m = Langertha::Raider::CLI->new(%a)->mission;
  my @at = map { index($m, $_) } 'You are an interactive agent', 'Project memory text.', '- greet: greets', 'Tools (MCP):';
  ok(( !grep { $_ < 0 } @at ) && $at[0] < $at[1] && $at[1] < $at[2] && $at[2] < $at[3],
    'neutral base, memory, skill listing, tools -- in this order');
  unlike($m, qr/Langertha|shield-maiden|caveman/i, 'Claude mode: no raider persona');
  like($m, qr/^  - skill\(skill, \[args\]\)$/m, 'the skill tool is mounted');
  unlike($m, qr/body of greets/, 'no skill body');

  my $flag = Langertha::Raider::CLI->new(%a, mission => 'Flag mission.')->mission;
  like($flag, qr/\AFlag mission\./, '-M leads');
  like($flag, qr/Project memory text\./, '-M keeps the Claude memory');
  unlike($flag, qr/You are Langertha/, '-M replaces the persona');

  my $app = Langertha::Raider::CLI->new(%a);
  is([ $app->loaded_skill_names ], [qw( dup home-native user-claude greet helper:tidy )], 'loaded_skill_names');
  is([ $app->ignored_agent_files ], [], 'CLAUDE.md is not ignored in Claude mode');
  like($app->explain_config, { layout => { mode => 'claude' }, memory => [ {}, { label => 'CLAUDE.md' } ] },
    'explain_config carries the context report');

  my $raider = project();
  put($raider, '.raider.md', "Raider instructions.\n");
  put($raider, 'CLAUDE.md', "Claude.\n");
  put($raider, 'AGENTS.md', "Agents.\n");
  my $r = Langertha::Raider::CLI->new(%a, root => "$raider");
  is([ $r->ignored_agent_files ], [ { path => 'CLAUDE.md', profile => 'claude' }, { path => 'AGENTS.md', profile => 'openai' } ],
    'raider project: both ignored, with the flag that loads them');
  my $rc = Langertha::Raider::CLI->new(%a, root => "$raider", claude => 1);
  is([ $rc->ignored_agent_files ], [ { path => 'AGENTS.md', profile => 'openai' } ], '--claude loads CLAUDE.md');
  like($rc->mission, qr/via C<\.raider\.md or CLAUDE\.md> in working dir/, 'persona names both');
};

done_testing;
