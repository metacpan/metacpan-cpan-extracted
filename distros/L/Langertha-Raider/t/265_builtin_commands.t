#!/usr/bin/env perl
# ABSTRACT: The built-in commands of ADR 0030 §5: /help, /reset, /skills, /agents, /hooks, /memory, /init, /context (k165)
use strict;
use warnings;
use utf8;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
my $home = isolate_home();
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;

delete @ENV{ grep { /_API_KEY\z/ } keys %ENV };
delete @ENV{qw( VISUAL EDITOR )};

# Every report goes through the output only, so all of it runs without a
# terminal (a one-shot run). /memory N gets a stubbed editor; /init only
# returns its run request.

{
  package Test::StubEditorCommands;
  use Moose;
  extends 'Langertha::Raider::CLI::Commands';
  has edits => ( is => 'ro', default => sub { [] } );
  has terminal => ( is => 'rw', default => 1 );
  sub is_terminal { $_[0]->terminal }
  sub editor { 'stub-editor' }
  sub run_editor {
    my ( $self, $editor, $file ) = @_;
    push @{ $self->edits }, [ $editor, $file ];
    Path::Tiny::path($file)->spew_utf8("Edited rule: OMEGA.\n");
    return 1;
  }
  __PACKAGE__->meta->make_immutable;
}

sub project { path(tempdir( CLEANUP => 1 ))->realpath }
sub put { my ( $base, $rel, $text ) = @_; $base->child($rel)->touchpath->spew_utf8($text) }

sub claude_project {
  my $p = project();
  put($p, 'CLAUDE.md', "First rule: ALPHA.\n");
  put($p, '.claude/commands/greet.md', "---\ndescription: Greet someone\nargument-hint: NAME [GREETING]\n---\nSay hi to \$0.\n");
  put($p, '.claude/commands/frontend/component.md', "Make a component.\n");
  put($p, '.claude/commands/hidden.md', "---\nuser-invocable: false\ndescription: only for the model\n---\nx\n");
  put($p, '.claude/commands/pdf.md', "---\ndescription: the pdf command\n---\nx\n");
  put($p, '.claude/skills/pdf/SKILL.md', "---\ndescription: Work with PDF files\n---\nbody\n");
  put($p, '.claude/skills/perl/SKILL.md', "---\ndescription: Perl help\npaths: lib/**/*.pm\n---\nbody\n");
  put($p, '.claude/skills/quiet/SKILL.md', "---\ndescription: hidden from the model\ndisable-model-invocation: true\n---\nbody\n");
  put($p, '.claude/agents/reviewer.md', "---\nname: reviewer\ndescription: Reviews code.\\nUse it after every change.\ntools: Read, Grep\n---\nYou review.\n");
  put($p, '.claude/agents/general-purpose.md', "---\ndescription: My own general agent\n---\nbody\n");
  put($p, '.claude/settings.json', JSON::MaybeXS->new( canonical => 1 )->encode({ hooks => {
    PreToolUse => [ { matcher => 'Bash', hooks => [ { type => 'command', command => './check.sh', timeout => 30 } ] } ],
    Stop       => [ { hooks => [ { type => 'command', command => 'notify', args => [ '--done' ] }, { type => 'http', url => 'http://x' } ] } ],
  } }));
  return $p;
}

sub app_for {
  my ( $root ) = @_;
  return Langertha::Raider::CLI->new( root => "$root", engine => 'openai', api_key => 'x', model => 'gpt-4o-mini', trace => 0 );
}

sub commands_for {
  my ( $app, $class ) = @_;
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  my $cmds = ( $class // 'Langertha::Raider::CLI::Commands' )->new(
    app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ) );
  my $read = sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t };
  return ( $cmds, $read );
}

subtest '/help lists the built-ins, then the user-invocable catalogue' => sub {
  my $p = claude_project();
  my ( $cmds, $read ) = commands_for(app_for($p));
  is($cmds->cmd_help, undef, 'returns nothing');
  my $out = $read->();
  like($out, qr{^  /clear /reset /new }m, 'clear with its aliases');
  like($out, qr{^  /$_\b}m, '/'.$_.' listed') for qw( compact context memory skills agents hooks init );
  like($out, qr{^skills and custom commands:$}m, 'a section for the catalogue');
  like($out, qr{^  /greet NAME \[GREETING\]\s+Greet someone \(\.claude/commands\)$}m, 'command with hint, description, source');
  like($out, qr{^  /frontend:component\s+Make a component\. \(\.claude/commands\)$}m, 'description from the first line');
  like($out, qr{^  /pdf\s+Work with PDF files \(\.claude/skills\)$}m, 'the skill, not the command it shadows');
  like($out, qr{^  /quiet\s+hidden from the model}m, 'not for the model, still for the user');
  unlike($out, qr{^  /hidden}m, 'user-invocable: false is not offered');
  my @names = $out =~ m{^  /([\w:-]+)\s.*\((?:\.claude/\w+)\)$}mg;
  is(\@names, [ sort @names ], 'sorted by name');

  my ( $none, $read_none ) = commands_for(app_for(project()));
  $none->cmd_help;
  my $o = $read_none->(); unlike($o, qr/^skills and custom commands:$/m, "no section without entries") or diag $o;
};

subtest '/help shows a YAML list argument-hint in brackets' => sub {
  my $p = project();
  put($p, '.claude/commands/fix.md', "---\nargument-hint: [issue]\ndescription: Fix it\n---\nx\n");
  my ( $cmds, $read ) = commands_for(app_for($p));
  $cmds->cmd_help;
  like($read->(), qr{^  /fix \[issue\]\s+Fix it }m, 'as written');
};

subtest '/reset and /new clear the history like /clear' => sub {
  my $app = app_for(project());
  my ( $cmds, $read ) = commands_for($app);
  for my $cmd (qw( cmd_reset cmd_new cmd_clear )) {
    $app->raider->history([ { role => 'user', content => 'hi' }, { role => 'assistant', content => 'ho' } ]);
    $cmds->$cmd;
    is($app->raider->history, [], $cmd.' emptied the history');
    is($read->(), "history cleared.\n", $cmd.' says so');
  }
};

subtest '/skills: every entry, conditional ones, shadowed' => sub {
  my $p = claude_project();
  my ( $cmds, $read ) = commands_for(app_for($p));
  $cmds->cmd_skills;
  my $out = $read->();
  like($out, qr{^  pdf \(skill, \.claude/skills\) model: yes, user: yes$}m, 'a skill');
  like($out, qr{^  greet \(command, \.claude/commands\) model: yes, user: yes$}m, 'a command');
  like($out, qr{^  hidden \(command, \.claude/commands\) model: yes, user: no$}m, 'not user-invocable');
  like($out, qr{^  quiet \(skill, \.claude/skills\) model: no, user: yes$}m, 'not model-invocable');
  like($out, qr{^  perl \(skill, \.claude/skills\) model: yes, user: yes, paths: lib/\*\*/\*\.pm \(not active yet\)$}m,
    'paths-conditional, not active yet');
  like($out, qr{^shadowed:\n  pdf \(\.claude/commands\) by \.claude/skills$}m, 'the shadowed command');

  my ( $none, $read_none ) = commands_for(app_for(project()));
  $none->cmd_skills;
  is($read_none->(), "no skills or custom commands.\n", 'empty catalogue');
};

subtest '/agents: the catalogue, first description line, tools, shadowed' => sub {
  my $p = claude_project();
  my ( $cmds, $read ) = commands_for(app_for($p));
  $cmds->cmd_agents;
  my $out = $read->();
  like($out, qr{^agents:$}m, 'header');
  like($out, qr{^  reviewer \(\.claude/agents\): Reviews code\.\n      tools: read_file, grep$}m,
    'first line only, tools in raider names');
  like($out, qr{^  general-purpose \(\.claude/agents\): My own general agent\n      tools: all$}m, 'the file wins');
  like($out, qr{^shadowed:\n  general-purpose \(built-in\) by \.claude/agents$}m, 'the built-in is shadowed');
};

subtest '/hooks: by event with matcher, command, timeout, source' => sub {
  my $p = claude_project();
  my ( $cmds, $read ) = commands_for(app_for($p));
  $cmds->cmd_hooks;
  is($read->(),
    "PreToolUse:\n"
    ."  Bash  ./check.sh  timeout 30s  (.claude/settings.json)\n"
    ."Stop:\n"
    ."  *  notify --done  (.claude/settings.json)\n"
    ."  *  http (not run by raider)  (.claude/settings.json)\n",
    'events sorted, groups in configuration order');

  my $q = project();
  put($q, 'CLAUDE.md', "x\n");
  my ( $none, $read_none ) = commands_for(app_for($q));
  $none->cmd_hooks;
  is($read_none->(), "no hooks configured.\n", 'Claude layout without hooks');

  my ( $native, $read_native ) = commands_for(app_for(project()));
  $native->cmd_hooks;
  like($read_native->(), qr/\Ano hooks configured \(hooks run in the Claude layout only\)\.\n\z/, 'native layout');

  my $d = project();
  put($d, '.claude/settings.json', '{ "disableAllHooks": true, "hooks": { "Stop": [ { "hooks": [ { "type": "command", "command": "x" } ] } ] } }');
  my ( $off, $read_off ) = commands_for(app_for($d));
  $off->cmd_hooks;
  is($read_off->(), "all hooks are disabled (disableAllHooks).\n", 'disableAllHooks');
};

subtest '/memory lists, /memory N edits and reloads' => sub {
  my $p = claude_project();
  my $app = app_for($p);
  like($app->raider->mission, qr/ALPHA/, 'memory in the mission');
  my ( $cmds, $read ) = commands_for($app, 'Test::StubEditorCommands');
  $cmds->cmd_memory('');
  my $user = path($ENV{HOME})->realpath->child('.claude', 'CLAUDE.md');
  is($read->(),
    "instruction files (/memory N to edit):\n"
    ."  1. CLAUDE.md (loaded)  ".$p->child('CLAUDE.md')."\n"
    ."  2. ~/.claude/CLAUDE.md (not there)  ".$user."\n",
    'loaded, then the targets; Claude mode has no native file');

  $cmds->cmd_memory('2');
  is($cmds->edits, [ [ 'stub-editor', "$user" ] ], 'the editor ran on the file');
  ok(-f $user, 'the missing file was created first');
  like($read->(), qr{\Acontext reloaded after editing ~/\.claude/CLAUDE\.md\.\n\z}, 'says so');
  like($app->raider->mission, qr/OMEGA/, 'the mission was reloaded');

  $cmds->cmd_memory('9');
  like($read->(), qr{^error: usage: /memory \[N\] \(N from 1 to 2\)$}m, 'out of range');

  $cmds->cmd_memory;
  is($read->(),
    "instruction files (/memory N to edit):\n"
    ."  1. ~/.claude/CLAUDE.md (loaded)  ".$user."\n"
    ."  2. CLAUDE.md (loaded)  ".$p->child('CLAUDE.md')."\n",
    'both loaded now, in load order');

  $cmds->terminal(0);
  $cmds->cmd_memory('2');
  is($read->(), $p->child('CLAUDE.md')."\n", 'without a terminal: the path');
  is(scalar @{ $cmds->edits }, 1, 'no editor started');
};

subtest '/memory in the native layout' => sub {
  my $p = project();
  put($p, '.raider/config.yml', "engine: openai\n");
  put($p, '.raider/instructions.md', "Native rule.\n");
  my ( $cmds, $read ) = commands_for(app_for($p));
  $cmds->cmd_memory;
  is($read->(),
    "instruction files (/memory N to edit):\n"
    ."  1. .raider/instructions.md (loaded)  ".$p->child('.raider/instructions.md')."\n",
    'the instructions file, loaded');

  my $q = project();
  my ( $empty, $read_empty ) = commands_for(app_for($q));
  $empty->cmd_memory;
  is($read_empty->(),
    "instruction files (/memory N to edit):\n"
    ."  1. .raider.md (not there)  ".$q->child('.raider.md')."\n",
    'the file /prompt would write');
};

subtest '/init returns a run request for the layout' => sub {
  my ( $claude ) = commands_for(app_for(claude_project()));
  my $req = $claude->cmd_init;
  is([ keys %$req ], [ 'prompt' ], 'a run request');
  like($req->{prompt}, qr/\APlease analyze this codebase and create a CLAUDE\.md file, which will be given to future instances of Claude Code to operate in this repository\./,
    'Claude Code text');
  like($req->{prompt}, qr/If there's already a CLAUDE\.md, suggest improvements to it\./, 'improve an existing one');
  like($req->{prompt}, qr/```\n# CLAUDE\.md\n\nThis file provides guidance to Claude Code \(claude\.ai\/code\) when working with code in this repository\.\n```/,
    'the prefix');

  my $p = project();
  put($p, '.raider/config.yml', "engine: openai\n");
  my ( $native, $read ) = commands_for(app_for($p));
  my $n = $native->cmd_init;
  like($n->{prompt}, qr/create a \.raider\.md file, which will be given to future instances of raider/, 'native file, raider');
  like($n->{prompt}, qr/```\n# \.raider\.md\n\nThis file provides guidance to raider when/, 'native prefix');
  unlike($n->{prompt}, qr/CLAUDE/, 'no CLAUDE.md');
  put($p, '.raider/instructions.md', "x\n");
  like($native->cmd_init->{prompt}, qr/create a \.raider\/instructions\.md file/, 'the native instructions file once it exists');
  is($read->(), '', 'prints nothing');
};

subtest '/context: the parts and a total' => sub {
  my $p = claude_project();
  my $app = app_for($p);
  my ( $cmds, $read ) = commands_for($app);
  $app->raider->history([ { role => 'user', content => 'x' x 400 }, { role => 'assistant', content => 'y' x 40 } ]);
  $cmds->cmd_context;
  my $out = $read->();
  my %n = $out =~ /^\s*(.+?)\s+~(\d+)$/mg;
  ok($n{'system prompt'} > 0, 'system prompt') or diag $out;
  ok($n{'instructions (claude base)'} > 0, 'the instructions item');
  ok(exists $n{'CLAUDE.md'}, 'the memory file');
  ok(exists $n{'other (tool list, packs, headers)'}, 'the rest');
  my ($tools) = grep { /^tool definitions \(\d+ tools\)$/ } keys %n;
  ok($tools && $n{$tools} > 0, 'tool definitions');
  ok($n{'history (2 messages)'} >= 110, 'history');
  is($n{total}, $n{'system prompt'} + $n{$tools} + $n{'history (2 messages)'}, 'total is the sum');
  ok(exists $n{'skill listing (4 skills)'}, 'the skill listing (Claude layout: the skill tool is mounted)');
  my $parts = 0;
  $parts += $_ for $out =~ /^    .+?\s+~(\d+)$/mg;
  is($parts, $n{'system prompt'}, 'the system prompt parts add up');
  like($out, qr/^  budget: 40000 tokens \(max_context_tokens\); history compacted above ~28000 \(70%\)$/m, 'the budget');
};

subtest '/context lists the native instructions file and the skill listing' => sub {
  my $p = project();
  put($p, '.raider/config.yml', "engine: openai\n");
  put($p, '.raider.md', "Custom rule.\n" x 20);
  put($p, '.raider/skills/greet/SKILL.md', "---\ndescription: greets\n---\nbody\n");
  my ( $cmds, $read ) = commands_for(app_for($p));
  $cmds->cmd_context;
  my %n = $read->() =~ /^\s*(.+?)\s+~(\d+)$/mg;
  is($n{'.raider.md'}, int(length("Custom rule.\n" x 20) / 4), 'the instructions file on its own');
  ok($n{'instructions (.raider.md)'} > 0, 'the base without it');
  ok(exists $n{'skill listing (1 skill)'}, 'the listing');
};

done_testing;
