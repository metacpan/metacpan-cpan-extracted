#!/usr/bin/env perl
# ABSTRACT: Live task -- raider --claude picks up a project's .claude/ context

use strict;
use warnings;
use lib 't/lib';
use Test::Raider::Live qw( live_opt_in run_raider_task check_journal );
BEGIN { live_opt_in() }
use Test2::V0;
use Path::Tiny;

# Opt-in (RAIDER_LIVE_TASKS=1), costs real money. The workspace holds a
# minimal fixture .claude/ with one skill (probe-style) whose rule the
# prompt never spells out: only an agent that discovered the project's
# skill can satisfy the VERSION check below.

my $fixture = path(__FILE__)->absolute->parent->parent->child('fixtures', 'live-claude');

my $run = run_raider_task(
  flags  => ['--claude'],
  seed   => sub {
    my ($ws) = @_;
    $fixture->child('.claude')->visit(
      sub {
        my ($p) = @_;
        return unless $p->is_file;
        my $dest = $ws->child($p->relative($fixture));
        $dest->parent->mkpath;
        $p->copy($dest);
      },
      { recurse => 1 },
    );
    $ws->child('cpanfile')->spew_utf8("on test => sub {\n  requires 'Test::More';\n};\n");
  },
  prompt => <<'P',
Create the module RaiderProbe::Greeter in lib/RaiderProbe/Greeter.pm with a
class method greet($class, $name) that returns "Hello, $name!", plus
t/greeter.t testing it. Follow this project's conventions for RaiderProbe
modules. Run `prove -l t` and make sure it passes. Be brief.
P
);

ok(!$run->{timed_out}, 'raider finished within the timeout') or diag $run->{output};
is($run->{exit}, 0, 'bin/raider exits 0') or diag $run->{output};

my $ws = $run->{workspace};
my $module = $ws->child('lib', 'RaiderProbe', 'Greeter.pm');
ok($module->is_file, 'module written') or diag $run->{output};
ok($ws->child('t', 'greeter.t')->is_file, 'test written');

my $prove = `cd '$ws' && $^X -S prove -l t 2>&1`;
is($? >> 8, 0, 'prove -l t is green in the workspace') or diag $prove;

my $out = `cd '$ws' && $^X -Ilib -MRaiderProbe::Greeter -e 'print RaiderProbe::Greeter->greet("Ada")' 2>&1`;
is($out, 'Hello, Ada!', 'greet works');

my $src = $module->is_file ? $module->slurp_utf8 : '';
like($src, qr/^\s*our\s+\$VERSION\s*=\s*['"]0\.042['"]\s*;/m,
  'module follows the .claude/ probe-style skill (our $VERSION = 0.042)');
like($src, qr/^\s*1;\s*\z/m, 'module ends with 1;');

check_journal($run);

done_testing;
