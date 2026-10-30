#!/usr/bin/env perl
# ABSTRACT: /reload reads the Claude memory, settings (env) and skills again (k157, ADR 0019)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Context;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY
  GROQ_API_KEY MISTRAL_API_KEY GEMINI_API_KEY K157_VAR K157_KEEP )};
delete $ENV{CLAUDE_CONFIG_DIR};

sub project { path(tempdir(CLEANUP => 1))->realpath }
sub put { my ( $base, $rel, $text ) = @_; $base->child($rel)->touchpath->spew_utf8($text) }
sub skill { "---\ndescription: $_[0]\n---\nbody of $_[0]\n" }

subtest 'Context::reload: memory, settings, env, skills' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "First rule.\n");
  put($p, '.claude/settings.json', '{ "env": { "K157_VAR": "one", "K157_KEEP": "kept" } }');
  put($p, '.claude/skills/alpha/SKILL.md', skill('alpha'));
  local $ENV{K157_KEEP} = 'before';
  my $c = Langertha::Raider::Context->new(root => "$p");
  $c->apply_env;
  is($ENV{K157_VAR}, 'one', 'env applied');
  is([ map { $_->{text} } $c->instruction_items ], ["First rule.\n"], 'memory');
  is([ map { $_->{name} } $c->skill_catalog->listed ], ['alpha'], 'skills');

  put($p, 'CLAUDE.md', "Second rule.\n");
  put($p, '.claude/settings.json', '{ "env": { "K157_VAR": "two" } }');
  put($p, '.claude/skills/beta/SKILL.md', skill('beta'));
  is([ map { $_->{text} } $c->instruction_items ], ["First rule.\n"], 'cached until reload');
  is($c->reload, $c, 'reload returns the context');
  is([ map { $_->{text} } $c->instruction_items ], ["Second rule.\n"], 'memory read again');
  is([ sort map { $_->{name} } $c->skill_catalog->listed ], [qw( alpha beta )], 'skills read again');
  is($ENV{K157_VAR}, 'two', 'env value changed');
  is($ENV{K157_KEEP}, 'before', 'a key the settings dropped gets its old value back');
  is($c->applied_env, ['K157_VAR'], 'applied_env');

  put($p, '.claude/settings.json', '{}');
  $c->reload;
  ok(!exists $ENV{K157_VAR}, 'a key that was not set before is removed');
};

subtest 'Context::reload: mode follows the files, nested memory is not repeated' => sub {
  my $p = project();
  put($p, 'sub/CLAUDE.md', "Sub rule.\n");
  my $c = Langertha::Raider::Context->new(root => "$p");
  is($c->mode, 'native', 'no marker: native');
  put($p, 'CLAUDE.md', "Top.\n");
  $c->reload;
  is($c->mode, 'claude', 'CLAUDE.md appeared: Claude mode');
  like($c->nested_memory_for('sub/x.txt'), qr/Sub rule\./, 'nested handed out');
  $c->reload;
  is($c->nested_memory_for('sub/x.txt'), undef, 'not handed out again after a reload');
};

subtest '/reload: mission, skill tool and the report line' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "First rule: ALPHA.\n");
  my $app = Langertha::Raider::CLI->new(root => "$p", engine => 'openai', api_key => 'x', trace => 0);
  $app->raider;
  like($app->raider->mission, qr/ALPHA/, 'mission at start');
  like($app->raider->mission, qr/^  - skill\(skill, \[args\]\)$/m, 'Claude layout: the skill tool is mounted without skills');
  unlike($app->raider->mission, qr/Skills: specialised/, 'no listing');
  my $before = @{ $app->_mcps };

  put($p, 'CLAUDE.md', "Changed rule: OMEGA.\n");
  put($p, '.claude/skills/greet/SKILL.md', skill('greets'));
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  my $cmds = Langertha::Raider::CLI::Commands->new(
    app => $app, output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0));
  $cmds->dispatch('/reload');
  $fh->flush;
  my $out = decode_utf8($buf);
  like($out, qr/^context reloaded: layout claude, 1 instruction file, 1 listed skill$/m, 'report line');
  my $mission = $app->raider->mission;
  like($mission, qr/OMEGA/, 'memory read again');
  unlike($mission, qr/ALPHA/, 'old memory gone');
  like($mission, qr/- greet: greets/, 'skill listed');
  like($mission, qr/^  - skill\(skill, \[args\]\)$/m, 'skill tool described');
  is(scalar @{ $app->_mcps }, $before, 'the skill tool client was replaced, not added');

  $p->child('.claude/skills/greet')->remove_tree;
  $cmds->dispatch('/reload');
  unlike($app->raider->mission, qr/- greet:/, 'skill gone from the listing');
};

subtest '/reload mounts and unmounts the skill tool outside the Claude layout' => sub {
  my $p = project();
  put($p, '.raider/config.yml', "engine: openai\n");
  my $app = Langertha::Raider::CLI->new(root => "$p", engine => 'openai', api_key => 'x', trace => 0);
  $app->raider;
  unlike($app->raider->mission, qr/skill\(skill/, 'no skill, no tool');
  my $before = @{ $app->_mcps };
  put($p, '.raider/skills/greet/SKILL.md', skill('greets'));
  $app->reload_context;
  $app->reload_mission;
  like($app->raider->mission, qr/^  - skill\(skill, \[args\]\)$/m, 'tool mounted');
  is(scalar @{ $app->_mcps }, $before + 1, 'with its client');
  $p->child('.raider/skills/greet')->remove_tree;
  $app->reload_context;
  $app->reload_mission;
  unlike($app->raider->mission, qr/skill\(skill/, 'unmounted again');
  is(scalar @{ $app->_mcps }, $before, 'client gone');
};

done_testing;
