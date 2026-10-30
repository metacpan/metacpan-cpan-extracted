#!/usr/bin/env perl
# ABSTRACT: Layout mode of a project root: bare, raider, claude, native (ADR 0019 §1, k151)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Context::Layout;

# Everything lives below one real temp base: $home is $ENV{HOME}, $cfg is
# $ENV{CLAUDE_CONFIG_DIR}, $out is a place outside the home. The real
# ~/.claude is never read.
my $base = path(tempdir(CLEANUP => 1))->realpath;
my $home = $base->child('home');
my $cfg  = $base->child('claude-config');
my $out  = $base->child('outside');
$_->mkpath for $home, $cfg, $out;

local $ENV{HOME}              = "$home";
local $ENV{CLAUDE_CONFIG_DIR} = "$cfg";

my $n = 0;
sub dir {
  my ( $parent, @files ) = @_;
  my $dir = $parent->child('p'.++$n);
  $dir->mkpath;
  for my $f (@files) {
    if ($f =~ m{/\z}) { $dir->child($f)->mkpath }
    else              { $dir->child($f)->spew_utf8("x\n") }
  }
  return $dir;
}

sub layout { Langertha::Raider::Context::Layout->new(root => "$_[0]", @_[1 .. $#_]) }

sub is_mode {
  my ( $root, $mode, $reason, $name, %args ) = @_;
  my $l = layout($root, %args);
  is [ $l->mode, $l->reason ], [ $mode, $reason ], $name;
  return $l;
}

subtest 'defaults' => sub {
  my $l = layout($out);
  is $l->home, "$home", 'home from $ENV{HOME}';
  is $l->claude_home, "$cfg", 'claude_home from $ENV{CLAUDE_CONFIG_DIR}';
  local $ENV{CLAUDE_CONFIG_DIR} = '';
  is layout($out)->claude_home, $home->child('.claude')->stringify,
    'empty CLAUDE_CONFIG_DIR: <home>/.claude';
  delete local $ENV{CLAUDE_CONFIG_DIR};
  is layout($out)->claude_home, $home->child('.claude')->stringify,
    'no CLAUDE_CONFIG_DIR: <home>/.claude';
};

subtest 'mode table' => sub {
  is_mode(dir($out, '.raider/', '.raider/config.yml', 'CLAUDE.md'), bare => '--bare', 'bare wins over everything', bare => 1);
  is_mode(dir($out, '.raider/', '.raider/config.yml', 'CLAUDE.md', '.claude/'), raider => '.raider/config.yml in root',
    '.raider/config.yml wins over Claude files');
  is_mode(dir($out, '.raider/', '.raider/instructions.md'), raider => '.raider/instructions.md in root',
    '.raider/instructions.md');
  is_mode(dir($out, '.raider/', '.raider/skills/'), raider => '.raider/skills/ in root', '.raider/skills/');
  is_mode(dir($out, '.raider/', '.raider/agents/'), raider => '.raider/agents/ in root', '.raider/agents/');
  is_mode(dir($out, '.raider/', '.raider/packs/'), raider => '.raider/packs/ in root', '.raider/packs/');
  # ADR 0020 replaced ADR 0011's raiders/<name>.yml by agents/<name>.md:
  # nothing reads .raider/raiders/, so it must not switch the Claude layout off.
  is_mode(dir($out, '.raider/', '.raider/raiders/', '.raider/raiders/Oli.yml', 'CLAUDE.md'),
    claude => 'CLAUDE.md in root', '.raider/raiders/ is no project marker');
  is_mode(dir($out, '.raider/', '.raider/raiders/'), native => 'no raider or Claude files',
    '.raider/ with only raiders/ is no raider project');
  # raider writes these itself in any project it runs in (journal, local::lib):
  # they must not turn a Claude Code project native (found by stream A).
  is_mode(dir($out, '.raider/', '.raider/sessions/', '.raider/.gitignore', '.raider/lib/', 'CLAUDE.md'),
    claude => 'CLAUDE.md in root', 'raider\'s own sessions/, lib/, .gitignore are no project marker');
  is_mode(dir($out, '.raider/'), native => 'no raider or Claude files', 'an empty .raider/ is no marker');
  is_mode(dir($out, '.raider.yml', 'CLAUDE.md'), raider => '.raider.yml in root', 'legacy .raider.yml');
  is_mode(dir($out, '.raider.md'), raider => '.raider.md in root', 'legacy .raider.md');
  is_mode(dir($out, '.raider'), native => 'no raider or Claude files', 'a .raider file is not a layout');
  is_mode(dir($out, 'CLAUDE.md'), claude => 'CLAUDE.md in root', 'CLAUDE.md');
  is_mode(dir($out, 'CLAUDE.local.md'), claude => 'CLAUDE.local.md in root', 'CLAUDE.local.md');
  is_mode(dir($out, '.claude/'), claude => '.claude/ in root', '.claude/ directory');
  is_mode(dir($out, 'AGENTS.md'), native => 'no raider or Claude files', 'AGENTS.md alone is no marker');
  is_mode(dir($out), native => 'no raider or Claude files', 'empty project');
};

subtest 'root is the home' => sub {
  $home->child('CLAUDE.md')->spew_utf8("x\n");
  $home->child('.raider')->mkpath;
  is_mode($home, native => 'root is the home directory', 'whatever is there');
  my $link = $base->child('home-link');
  symlink "$home", "$link" or skip_all 'no symlinks';
  is_mode($link, native => 'root is the home directory', 'compared by real path');
  $home->child('CLAUDE.md')->remove;
  $home->child('.raider')->remove_tree;
};

subtest 'the home .claude is no marker' => sub {
  $home->child('.claude')->mkpath;
  is_mode(dir($home), native => 'no raider or Claude files',
    '<home>/.claude while CLAUDE_CONFIG_DIR points elsewhere');
  {
    delete local $ENV{CLAUDE_CONFIG_DIR};
    is_mode(dir($home), native => 'no raider or Claude files', '<home>/.claude as claude_home');
  }
  $home->child('.claude')->remove_tree;

  my $real = $base->child('real-claude');
  $real->mkpath;
  symlink "$real", $home->child('.claude')->stringify or skip_all 'no symlinks';
  is_mode(dir($home), native => 'no raider or Claude files', 'a symlinked <home>/.claude');
  $home->child('.claude')->remove;

  my $proj = dir($out, '.claude/');
  local $ENV{CLAUDE_CONFIG_DIR} = $proj->child('.claude')->stringify;
  is_mode($proj, native => 'no raider or Claude files', 'CLAUDE_CONFIG_DIR inside the project');
};

subtest 'markers along the walk' => sub {
  my $dev = dir($home, 'CLAUDE.md');
  my $proj = $dev->child('proj');
  $proj->mkpath;
  is_mode($proj, claude => 'CLAUDE.md in '.$dev, 'ancestor under the home, named by path');
  is [ map { "$_" } layout($proj)->walk_dirs ], [ "$home", "$dev", "$proj" ], 'walk from the home';

  my $local = dir($home, 'CLAUDE.local.md');
  $local->child('a', 'b')->mkpath;
  is_mode($local->child('a', 'b'), claude => 'CLAUDE.local.md in '.$local, 'CLAUDE.local.md above');

  my $parent = dir($out, 'CLAUDE.md');
  my $child = $parent->child('child');
  $child->mkpath;
  is_mode($child, native => 'no raider or Claude files', 'outside home and repo: only root is walked');
  is [ map { "$_" } layout($child)->walk_dirs ], [ "$child" ], 'walk is only root';
  is layout($child)->repo_top, undef, 'no repository';

  my $raider_below = dir($dev);
  $raider_below->child('.raider')->mkpath;
  $raider_below->child('.raider', 'config.yml')->spew_utf8("x\n");
  is_mode($raider_below, raider => '.raider/config.yml in root', 'raider files in root beat an ancestor CLAUDE.md');
};

subtest 'repository walk' => sub {
  my $repo = dir($out, '.git/', 'CLAUDE.md');
  my $root = $repo->child('sub', 'dir');
  $root->mkpath;
  my $l = is_mode($root, claude => 'CLAUDE.md in '.$repo, 'marker at the repository top');
  is $l->repo_top->stringify, "$repo", 'repo_top';
  is [ map { "$_" } $l->walk_dirs ], [ "$repo", $repo->child('sub')->stringify, "$root" ],
    'walk from the repository top';
  is layout($repo)->repo_top->stringify, "$repo", 'repo_top is root itself';

  my $wt = dir($home);
  $wt->child('.git')->spew_utf8("gitdir: /elsewhere\n");
  $wt->child('x')->mkpath;
  my $wl = layout($wt->child('x'));
  is $wl->repo_top->stringify, "$wt", '.git as a file (worktree)';
  is [ map { "$_" } $wl->walk_dirs ], [ "$wt", $wt->child('x')->stringify ],
    'the repository top beats the home as walk start';
};

subtest 'claude_layout' => sub {
  my @cases = (
    [ 'bare',             [ '.raider/', '.raider/config.yml', 'CLAUDE.md' ], { bare => 1, force_claude => 1, config_claude => 1 },
      0, 'off: --bare' ],
    [ 'claude mode',      [ 'CLAUDE.md' ], {}, 1, 'Claude mode' ],
    [ 'claude + --claude', [ 'CLAUDE.md' ], { force_claude => 1 }, 1, 'Claude mode' ],
    [ 'raider',           [ '.raider/', '.raider/config.yml', 'CLAUDE.md' ], {}, 0, 'off: raider project without claude: true' ],
    [ 'raider claude: false', [ '.raider/', '.raider/config.yml' ], { config_claude => 0 }, 0,
      'off: raider project without claude: true' ],
    [ 'raider claude: true',  [ '.raider/', '.raider/config.yml' ], { config_claude => 1 }, 1, 'claude: true in config' ],
    [ 'raider --claude',  [ '.raider/', '.raider/config.yml' ], { force_claude => 1, config_claude => 0 }, 1, '--claude' ],
    [ 'native',           [], {}, 0, 'off: no raider or Claude files' ],
    [ 'native claude: true', [], { config_claude => 1 }, 0, 'off: no raider or Claude files' ],
    [ 'native --claude',  [], { force_claude => 1 }, 1, '--claude' ],
  );
  for my $c (@cases) {
    my ( $name, $files, $args, $on, $reason ) = @$c;
    my $l = layout(dir($out, @$files), %$args);
    is [ $l->claude_layout ? 1 : 0, $l->claude_layout_reason ], [ $on, $reason ], $name;
  }
  my $l = layout($home, force_claude => 1);
  is [ $l->mode, $l->claude_layout ? 1 : 0 ], [ 'native', 1 ], 'home --claude';
  is layout($home)->claude_layout_reason, 'off: root is the home directory', 'home without --claude';
};

subtest 'project_dir' => sub {
  my $repo = dir($out, '.git/', '.claude/');
  my $root = $repo->child('sub');
  $root->mkpath;
  is layout($root)->project_dir->stringify, "$repo", '.claude/ at the repository top';
  $root->child('CLAUDE.md')->spew_utf8("x\n");
  is layout($root)->project_dir->stringify, "$root", 'nearest CLAUDE.md wins';
  my $empty = dir($out);
  is layout($empty)->project_dir->stringify, "$empty", 'default root';
  $home->child('.claude')->mkpath;
  my $under = dir($home);
  is layout($under)->project_dir->stringify, "$under", 'the home .claude is no project dir';
  $home->child('.claude')->remove_tree;
};

subtest 'decided once' => sub {
  my $root = dir($out);
  my $l = layout($root);
  is $l->mode, 'native', 'native first';
  $root->child('CLAUDE.md')->spew_utf8("x\n");
  is [ $l->mode, $l->reason ], [ 'native', 'no raider or Claude files' ], 'same object keeps its decision';
  is layout($root)->mode, 'claude', 'a new object sees the file';
};

done_testing;
