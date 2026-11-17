#!/usr/bin/env perl
# The rule kind check, ported from cai-platform t/eval_grader_check.t onto an
# invented world (ADR 0003): a command run after the run on a COPY of the end
# state in the simulator. Claims: (1) met only when exit status and output (text
# or lines) fit, and the reason names what does not; (2) the command changes no
# graded state and is no call; (3) when it hits a gap of the simulation the rule
# is not met, carries the gap, and the case is uncertain instead of failed; (4)
# the loader reads the rule, refuses incomplete ones and unknown devices, counts
# check as a rule on the end state, and lint refuses a case whose reference
# solution makes the check command hit a gap.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Holmgang::SuiteDir qw( try_load refused );
use Langertha::Holmgang::Case;
use Langertha::Holmgang::Grader;
use Langertha::Holmgang::World;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $G = Langertha::Holmgang::Grader->new;
my $state = { box1 => { type => 'linux', files => {
  '/usr/local/bin/stamp.sh' => { mode => '0755', content => "#!/bin/bash\nset -e\nmkdir -p /srv/out\necho done > /srv/out/flag\n" },
  '/srv/in/a.txt' => "a\n",
} } };
my $rule = sub {
  my ( %o ) = @_;
  return { title => $o{title} // 'check', check => { host => $o{host} // 'box1', command => $o{command} }, expect => $o{expect} };
};
my $case = Langertha::Holmgang::Case->new( id => 'c', state => $state, rules => [] );
my $R = sub { $G->rule( $_[0], { state => $state }, $case ) };

# --- (1) exit and output -------------------------------------------------------
{
  my ( $ok, $d ) = $R->( $rule->( command => 'bash /usr/local/bin/stamp.sh && cat /srv/out/flag',
    expect => { exit => 0, output => { regex => '\Adone\z' } } ) );
  ok( $ok, 'the script runs and writes the flag: met' ) or diag $d;
  like( $d, qr/exit 0/, '... the reason names the exit status' );

  ( $ok, $d ) = $R->( $rule->( command => 'cat /srv/out/flag', expect => { exit => 0 } ) );
  ok( !$ok, 'the flag does not exist in the end state (the first check ran on a copy)' );
  like( $d, qr/exit 1 instead of 0/, '... reason: exit status of cat' ) or diag $d;
  like( $d, qr/No such file/, '... with the output' );

  ( $ok, $d ) = $R->( $rule->( command => 'ls /srv/in', expect => { output => { regex => 'b\.txt' } } ) );
  ok( !$ok, 'output does not fit: not met' );
  like( $d, qr/\Aoutput do not fit/, '... the reason names the output' );

  ( $ok, $d ) = $R->( $rule->( command => 'ls /srv/in; echo b.txt', expect => { lines => { contains => [ 'a.txt', 'b.txt' ], length => 2 } } ) );
  ok( $ok, 'lines as a list (contains, length)' ) or diag $d;
  ( $ok, $d ) = $R->( $rule->( command => 'ls /srv/in', expect => { lines => { length => 2 } } ) );
  ok( !$ok, 'lines: wrong count' );
  like( $d, qr/\Alines of the output/, '... named as lines' );

  ( $ok, $d ) = $R->( $rule->( command => 'test -e /srv/none', expect => { exit => 1 } ) );
  ok( $ok, 'expected failure (exit 1)' ) or diag $d;
  ( $ok, $d ) = $R->( $rule->( command => 'test -e /srv/in/a.txt', expect => { exit => 1 } ) );
  ok( !$ok, 'exit 1 expected, the command succeeds: not met' );
  like( $d, qr/exit 0 instead of 1/, '... reason' );

  ( $ok, $d ) = $R->( $rule->( command => q{bash -c 'echo part; exit 3'}, expect => { exit => 3, output => { equals => 'part' } } ) );
  ok( $ok, 'exit N of a script arrives as the exit status' ) or diag $d;

  ( $ok, $d ) = $R->( $rule->( host => 'box9', command => 'true', expect => { exit => 0 } ) );
  ok( !$ok, 'unknown device: not met' );
  like( $d, qr/Could not resolve hostname box9/, '... like ssh' );
}

# --- (2) a copy, no call -------------------------------------------------------
{
  my $c = Langertha::Holmgang::Case->new( id => 'c', state => $state, rules => [
    $rule->( command => 'rm /srv/in/a.txt && ls /srv/in', expect => { exit => 0 } ),
    { title => 'nothing changed', unchanged_except => [] } ] );
  my $end = Langertha::Holmgang::World->clone( $c->initial_state );
  my $before = Langertha::Holmgang::World->clone($end);
  my $g = $G->grade( $c, { state => $end, calls => [] } );
  is( $g->{status}, 'passed', 'the check deletes on the copy: nothing else changed stays met' ) or diag explain $g->{rules};
  is_deeply( $end, $before, '... the end state itself is untouched' );
  is_deeply( $g->{sim_gaps}, [], '... and the check is no call' );
}

# --- (3) gap of the simulation --------------------------------------------------
{
  my $c = Langertha::Holmgang::Case->new( id => 'c', state => $state,
    rules => [ $rule->( command => 'vi /srv/in/a.txt', expect => { exit => 0 } ) ] );
  my $g = $G->grade( $c, { calls => [] } );
  my ( $r ) = @{ $g->{rules} };
  ok( !$r->{passed}, 'gap in the check command: not met' );
  like( $r->{reason}, qr/gap of the simulation.*vi/, '... the reason names the gap' );
  is( $r->{sim_gap}, 'vi /srv/in/a.txt', '... and keeps it' );
  is( $g->{status}, 'uncertain', '... the case is uncertain instead of failed' );
}

# --- (4) loader and lint ---------------------------------------------------------
my $HEAD = <<'Y';
format: 2
id: __ID__
version: 1
title: Shell
tools:
  - name: run_command
    description: Shell.
    simulator: run_command
    parameters: { type: object, required: [host, command], properties: { host: { type: string }, command: { type: string } } }
Y
my $CASE = <<'Y';
id: c1
title: Write a marker
messages: [ { role: user, content: "Put ok into /srv/mark." } ]
state: { box1: { type: linux } }
rules:
  - title: "marker there"
    check: { host: box1, command: "test -f /srv/mark && cat /srv/mark" }
    expect: { exit: 0, output: { regex: '\Aok\z' } }
  - { title: nothing else, unchanged_except: [ [box1, files, /srv/mark] ] }
solution: [ { tool: run_command, args: { host: box1, command: "echo ok > /srv/mark" } } ]
alternatives: [ { title: printf, calls: [ { tool: run_command, args: { host: box1, command: "printf 'ok\\n' > /srv/mark" } } ] } ]
wrong_solutions: [ { title: empty, calls: [ { tool: run_command, args: { host: box1, command: "touch /srv/mark" } } ] } ]
Y
{
  my ( $s, $err ) = try_load( $CASE, head => $HEAD );
  ok( $s, 'a case with check loads (check counts as a rule on the end state)' ) or diag $err;
  my ( $r ) = @{ $s->cases->[0]->rules };
  is_deeply( $r->{check}, { host => 'box1', command => 'test -f /srv/mark && cat /srv/mark' }, '... the check command as written' );
  is( $r->{expect}{exit}, 0, '... expected exit status' );
}
refused( $CASE =~ s/^    expect: .*\n//mr, qr/rules\[0\]\.expect\z/, qr/missing/, 'check without expect refused', head => $HEAD );
refused( $CASE =~ s/expect: \{ exit: 0, output: \{ regex: '\\Aok\\z' \} \}/expect: {}/r, qr/rules\[0\]\.expect\z/,
  qr/exit, output or lines/, 'expect without an expectation refused', head => $HEAD );
refused( $CASE =~ s/check: \{ host: box1,/check: { host: box7,/r, qr/rules\[0\]\.check\.host/, qr/no device/,
  'unknown device refused', head => $HEAD );
refused( $CASE =~ s/test -f \/srv\/mark && cat \/srv\/mark/test -f \/srv\/mark && vi \/srv\/mark/r,
  qr/: solution\z/, qr/check command "marker there" hits a gap of the simulation: vi/, 'the reference solution makes the check hit a gap: lint red', head => $HEAD );
refused( $CASE =~ s/expect: \{ exit: 0,/expect: { exit: 300,/r, qr/rules\[0\]\.expect\.exit/, qr/outside 0\.\.255/,
  'exit outside 0..255 refused', head => $HEAD );
refused( $CASE =~ s/unchanged_except: \[ \[box1, files, \/srv\/mark\] \]/unchanged_except: []/r, qr/: solution\z/,
  qr/reference solution does not pass: "nothing else": also changed: box1\.files\.\/srv\/mark\z/,
  'reason of a missed rule in the lint refusal', head => $HEAD );

done_testing;
