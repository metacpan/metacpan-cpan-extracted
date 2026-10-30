#!/usr/bin/env perl
# ABSTRACT: Claude Code memory: CLAUDE.md hierarchy, @imports, nested memory (ADR 0019 §2, k151)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Context::Memory;

# All below one real temp base; $ENV{HOME} and $ENV{CLAUDE_CONFIG_DIR}
# point into it, so the real ~/.claude is never read.
my $base = path(tempdir(CLEANUP => 1))->realpath;
my $home = $base->child('home');
my $cfg  = $base->child('claude-config');
my $out  = $base->child('outside');
$_->mkpath for $home, $cfg, $out;

local $ENV{HOME}              = "$home";
local $ENV{CLAUDE_CONFIG_DIR} = "$cfg";

sub put {
  my ( $file, $text ) = @_;
  $file->parent->mkpath;
  $file->spew_utf8($text);
  return $file;
}

sub memory {
  my ( $root, $walk, %args ) = @_;
  return Langertha::Raider::Context::Memory->new(
    root      => "$root",
    walk_dirs => [ map { "$_" } @{ $walk // [ $root ] } ],
    %args,
  );
}

sub shape { [ map { [ $_->{label}, $_->{scope}, $_->{kind} ] } @{ $_[0]->items } ] }

subtest 'load order, scopes, AGENTS.md fallback' => sub {
  my $repo = $out->child('repo');
  my $mid  = $repo->child('mid');
  my $root = $mid->child('proj');
  put($cfg->child('CLAUDE.md'), "User.\n");
  put($repo->child('CLAUDE.md'), "Repo.\n");
  put($repo->child('CLAUDE.local.md'), "Repo local.\n");
  put($mid->child('AGENTS.md'), "Mid agents.\n");
  put($root->child('CLAUDE.md'), "Proj.\n");
  put($root->child('AGENTS.md'), "Proj agents, shadowed.\n");
  put($root->child('CLAUDE.local.md'), "Proj local.\n");
  my $m = memory($root, [ $repo, $mid, $root ]);
  is shape($m), [
    [ $cfg->child('CLAUDE.md')->stringify,        'user',     'CLAUDE.md' ],
    [ $repo->child('CLAUDE.md')->stringify,       'ancestor', 'CLAUDE.md' ],
    [ $repo->child('CLAUDE.local.md')->stringify, 'local',    'CLAUDE.local.md' ],
    [ $mid->child('AGENTS.md')->stringify,        'ancestor', 'AGENTS.md' ],
    [ 'CLAUDE.md',                                'project',  'CLAUDE.md' ],
    [ 'CLAUDE.local.md',                          'local',    'CLAUDE.local.md' ],
  ], 'user, then each level top down: CLAUDE.md (else AGENTS.md), CLAUDE.local.md';
  is $m->items->[4]{file}, $root->child('CLAUDE.md')->stringify, 'file is absolute';
  is $m->items->[4]{text}, "Proj.\n", 'text';
  is $m->items->[4]{imports}, [], 'no imports';

  is $m->prompt_text, join("\n\n",
    'Contents of '.$cfg->child('CLAUDE.md')." (user's private global instructions for all projects):\n\nUser.",
    'Contents of '.$repo->child('CLAUDE.md')." (project instructions, checked into the codebase):\n\nRepo.",
    'Contents of '.$repo->child('CLAUDE.local.md')." (user's private project instructions, not checked in):\n\nRepo local.",
    'Contents of '.$mid->child('AGENTS.md')." (project instructions (AGENTS.md)):\n\nMid agents.",
    'Contents of '.$root->child('CLAUDE.md')." (project instructions, checked into the codebase):\n\nProj.",
    'Contents of '.$root->child('CLAUDE.local.md')." (user's private project instructions, not checked in):\n\nProj local.",
  ), 'prompt_text in the Claude Code shape';
  $cfg->child('CLAUDE.md')->remove;
};

subtest 'labels and skipped files' => sub {
  my $dev  = $home->child('dev');
  my $root = $dev->child('p');
  put($dev->child('CLAUDE.md'), "Dev.\n");
  put($root->child('CLAUDE.md'), " \n\t\n");
  put($root->child('AGENTS.md'), "Agents.\n");
  delete local $ENV{CLAUDE_CONFIG_DIR};
  put($home->child('.claude', 'CLAUDE.md'), "User.\n");
  my $m = memory($root, [ $home, $dev, $root ]);
  is shape($m), [
    [ '~/.claude/CLAUDE.md', 'user',     'CLAUDE.md' ],
    [ '~/dev/CLAUDE.md',     'ancestor', 'CLAUDE.md' ],
    [ 'AGENTS.md',           'project',  'AGENTS.md' ],
  ], '~/ labels under the home; a whitespace-only CLAUDE.md is skipped, AGENTS.md takes over';
  $home->child('.claude')->remove_tree;

  my $none = $out->child('none');
  $none->mkpath;
  my $e = memory($none);
  is $e->items, [], 'no items';
  is $e->prompt_text, undef, 'prompt_text undef without items';

  SKIP: {
    skip 'running as root, chmod 000 is still readable', 1 if $> == 0;
    my $locked = $out->child('locked');
    put($locked->child('CLAUDE.md'), "Secret.\n")->chmod(0);
    is memory($locked)->items, [], 'unreadable file skipped';
    $locked->child('CLAUDE.md')->chmod(0644);
  }
};

subtest '@path imports' => sub {
  my $root = $out->child('imp');
  my $abs  = put($out->child('abs.md'), "Absolute.\n");
  put($root->child('docs', 'a.md'), "A says \@b.md\n");
  put($root->child('docs', 'b.md'), "B.\n\n");
  put($home->child('shared.md'), "Shared.\n");
  put($root->child('c.md'), "Only in code.\n");
  put($root->child('b.c'), "Not an import.\n");
  put($root->child('CLAUDE.md'), join '',
    "Intro \@docs/a.md\n",
    "\@~/shared.md\n",
    "Abs: \@$abs end\n",
    "Mail me at a\@b.c or see \@missing.md and \@~nobody\n",
    "Code `x \@c.md y` and ``y ` \@c.md z`` stay\n",
    "```perl\n\@c.md\n```\n",
    "~~~~\n\@c.md\n~~~\n\@c.md\n~~~~\n",
    "After: \@docs/b.md\n",
  );
  my ( $item ) = @{ memory($root)->items };
  is $item->{text}, join('',
    "Intro A says B.\n",
    "Shared.\n",
    "Abs: Absolute. end\n",
    "Mail me at a\@b.c or see \@missing.md and \@~nobody\n",
    "Code `x \@c.md y` and ``y ` \@c.md z`` stay\n",
    "```perl\n\@c.md\n```\n",
    "~~~~\n\@c.md\n~~~\n\@c.md\n~~~~\n",
    "After: \@docs/b.md\n",
  ), 'relative, nested, ~/ and absolute expanded; email, missing, code spans, fences and repeats left';
  is $item->{imports}, [
    $root->child('docs', 'a.md')->stringify,
    $root->child('docs', 'b.md')->stringify,
    $home->child('shared.md')->stringify,
    "$abs",
  ], 'imports lists every file actually imported';
};

subtest 'cycles and self-imports' => sub {
  my $root = $out->child('cyc');
  put($root->child('p.md'), "P \@q.md\n");
  put($root->child('q.md'), "Q \@p.md \@CLAUDE.md\n");
  put($root->child('CLAUDE.md'), "Top \@p.md\n");
  my ( $item ) = @{ memory($root)->items };
  is $item->{text}, "Top P Q \@p.md \@CLAUDE.md\n", 'a file in the chain is not imported again';
  is $item->{imports}, [ map { $root->child($_)->stringify } qw( p.md q.md ) ], 'imports';
};

subtest 'depth limit' => sub {
  my $root = $out->child('deep');
  put($root->child("d$_.md"), "D$_ \@d".($_ + 1).".md\n") for 1 .. 7;
  put($root->child('CLAUDE.md'), "\@d1.md\n");
  my ( $item ) = @{ memory($root)->items };
  is $item->{text}, "D1 D2 D3 D4 D5 \@d6.md\n", 'five levels by default';
  is scalar @{ $item->{imports} }, 5, 'five imports';
  my ( $one ) = @{ memory($root, undef, max_import_depth => 1)->items };
  is $one->{text}, "D1 \@d2.md\n", 'max_import_depth 1';
  my ( $zero ) = @{ memory($root, undef, max_import_depth => 0)->items };
  is $zero->{text}, "\@d1.md\n", 'max_import_depth 0 imports nothing';
};

subtest 'nested_for' => sub {
  my $parent = $out->child('nest');
  my $root   = $parent->child('root');
  put($parent->child('CLAUDE.md'), "Parent.\n");
  put($root->child('CLAUDE.md'), "Root.\n");
  put($root->child('sub', 'CLAUDE.md'), "Sub \@inc.md\n");
  put($root->child('sub', 'inc.md'), "included\n");
  put($root->child('sub', 'CLAUDE.local.md'), "Sub local.\n");
  put($root->child('sub', 'deeper', 'CLAUDE.md'), "Deeper.\n");
  put($root->child('sub', 'deeper', 'f.pm'), "1;\n");
  put($root->child('other', 'CLAUDE.md'), "Other.\n");
  $root->child('plain')->mkpath;

  my $m = memory($root);
  is [ map { $_->{label} } @{ $m->items } ], [ 'CLAUDE.md' ], 'nested files are not loaded up front';

  my @got = $m->nested_for('sub/deeper/f.pm');
  is [ map { [ $_->{label}, $_->{scope}, $_->{kind} ] } @got ], [
    [ 'sub/CLAUDE.md',        'nested', 'CLAUDE.md' ],
    [ 'sub/deeper/CLAUDE.md', 'nested', 'CLAUDE.md' ],
  ], 'every CLAUDE.md between root and the file, top down, no CLAUDE.local.md';
  is $got[0]{text}, "Sub included\n", 'imports expanded';
  is $m->nested_text(@got), join("\n\n",
    'Contents of '.$root->child('sub', 'CLAUDE.md')." (project instructions, checked into the codebase):\n\nSub included",
    'Contents of '.$root->child('sub', 'deeper', 'CLAUDE.md')." (project instructions, checked into the codebase):\n\nDeeper.",
  ), 'nested_text';
  is [ $m->nested_for($root->child('sub', 'deeper', 'f.pm')->stringify) ], [], 'once per object';
  is [ $m->nested_for('sub/deeper/new/dir/x.pm') ], [], 'a path that does not exist yet: nothing new';
  is [ map { $_->{label} } $m->nested_for('other') ], [ 'other/CLAUDE.md' ], 'a directory includes itself';
  is [ $m->nested_for('plain/x') ], [], 'no CLAUDE.md on the way';
  is [ $m->nested_for('.') ], [], 'root itself: nothing';
  is [ $m->nested_for('x.pm') ], [], 'a file in root: nothing';
  is [ $m->nested_for("$parent") ], [], 'outside root: nothing';
  is [ $m->nested_for('sub/../../CLAUDE.md') ], [], 'escaping root with ..: nothing';
  is $m->nested_text, undef, 'nested_text undef without items';

  my $fresh = memory($root);
  is [ map { $_->{label} } $fresh->nested_for('sub/deeper/new/x.pm') ],
    [ 'sub/CLAUDE.md', 'sub/deeper/CLAUDE.md' ], 'not-yet-existing path below existing dirs';

  my $link = $out->child('nest-link');
  symlink "$root", "$link" or skip_all 'no symlinks';
  my $via = memory($link);
  is [ map { $_->{label} } $via->nested_for($link->child('other', 'f')->stringify) ],
    [ 'other/CLAUDE.md' ], 'root given through a symlink';
};

done_testing;
