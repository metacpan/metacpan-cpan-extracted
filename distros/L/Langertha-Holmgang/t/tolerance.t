#!/usr/bin/env perl
# tolerance beside equals (k49): a number within a tolerance of the expected
# one, for values read off an image. Claims: (1) Expectation::near and
# check_value compare |value - equals| <= tolerance, bounds included, with
# binary rounding allowed for, numeric text too, never a boolean, a reference
# or other text, in rules, list element patterns and file content alike;
# (2) the shape check refuses tolerance without a numeric equals and a
# tolerance that is no number of 0 or more, with the field; (3) a case using it
# loads, grades within and outside the tolerance, and lint refuses a wrong
# solution that lands inside it. Invented suite (ADR 0003).
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::SuiteDir qw( try_load refused );
use Langertha::Holmgang::Expectation qw( check_value condition near );
use Langertha::Holmgang::Grader;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

# --- (1) the comparison -------------------------------------------------------
ok( near( 42, 42, 0 ), 'near: equal, tolerance 0' );
ok( near( 42.5, 42, 0.5 ) && near( 41.5, 42, 0.5 ), '... both bounds included' );
ok( !near( 42.51, 42, 0.5 ), '... just outside' );
ok( near( 41.8, 42, 0.2 ), '... binary rounding allowed for (41.8 - 42 is not exactly 0.2)' );
ok( near( 0.3, 0.1 + 0.2, 0 ), '... 0.1 + 0.2 equals 0.3 at tolerance 0' );
ok( !near( 42.0000001, 42, 0 ), '... the slack is far below any written tolerance' );
ok( near( '41.9', 42, 0.1 ) && near( -3, '-2.5', '0.5' ), '... numeric text on either side' );
ok( !near( $_, 1, 1 ), '... not near: '.( defined $_ ? "'$_'" : 'undef' ) )
  for undef, 'abc', '', ' 1', "1\n", 'inf', 'nan';
ok( !near( JSON::MaybeXS::true(), 1, 1 ), '... nor a boolean' );
ok( !near( [1], 1, 1 ), '... nor a list' );

my $st = { r => { umsatz => { 2023 => 12.4, 2024 => '15' }, punkte => [ { x => 1, y => 2.9 } ] }, f => { content => '7.05' }, t => 'zwölf' };
my $ok  = sub { ( condition( $st, @_ ) )[0] };
my $why = sub { ( condition( $st, @_ ) )[1] };
ok( $ok->( { path => 'r.umsatz.2023', equals => 12, tolerance => 0.5 } ), 'rule: within' );
ok( !$ok->( { path => 'r.umsatz.2023', equals => 12, tolerance => 0.3 } ), 'rule: outside' );
is( $why->( { path => 'r.umsatz.2023', equals => 12, tolerance => 0.3 } ), 'is 12.4, not within 0.3 of 12', '... reason' );
ok( $ok->( { path => 'r.umsatz.2024', equals => 15.2, tolerance => 0.25 } ), 'a number stored as text' );
ok( !$ok->( { path => 't', equals => 12, tolerance => 100 } ), 'text that is no number is never within' );
ok( !$ok->( { path => 'r.umsatz.2025', equals => 12, tolerance => 1 } ), 'missing path' );
is( $why->( { path => 'r.umsatz.2025', equals => 12, tolerance => 1 } ), 'missing', '... reason' );
ok( $ok->( { path => 'f', equals => 7, tolerance => 0.05 } ), 'a file entry counts with its content' );
ok( $ok->( { path => 'r.punkte', any => { y => { equals => 3, tolerance => 0.1 } } } ), 'inside a list element pattern' );
ok( !$ok->( { path => 'r.punkte', any => { y => { equals => 3, tolerance => 0.05 } } } ), '... outside' );
ok( !$ok->( { path => 'r.umsatz.2023', equals => 12.4, tolerance => 1, in => [ 1, 2 ] } ), 'other expectations still hold beside it' );
ok( $ok->( { path => 'r.umsatz.2023', equals => 12.4 } ), 'equals without tolerance is unchanged' );

# --- (2) and (3) a suite with a dial ------------------------------------------
my $HEAD = <<'Y';
format: 2
id: __ID__
version: 1
title: Dial
tools:
  - name: dial_set
    description: Sets the dial to the value read off the chart.
    parameters: { type: object, required: [value], properties: { value: { type: number } } }
    handlers:
      - apply: [ { set: dial.value, value: '{value}' } ]
        output: "dial <: $state.dial.value :>"
Y

my $CASE = <<'Y';
id: c1
title: Read the peak
messages: [ { role: user, content: "Set the dial to the peak of the chart." } ]
state: { dial: { value: 0 } }
rules:
  - { title: peak read, state: dial.value, equals: 42, tolerance: 0.5 }
solution: [ { tool: dial_set, args: { value: 42.3 } } ]
alternatives: [ { title: rounded, calls: [ { tool: dial_set, args: { value: 42 } } ] } ]
wrong_solutions: [ { title: next bar, calls: [ { tool: dial_set, args: { value: 43 } } ] } ]
Y

{
  my ( $s, $err ) = try_load( $CASE, head => $HEAD );
  ok( $s, 'a case with tolerance loads (lint green)' ) or diag $err;
  if ($s) {
    my $c = $s->cases->[0];
    is_deeply( $c->rules->[0], { title => 'peak read', state => 'dial.value', equals => 42, tolerance => 0.5 }, 'rule kept as written' );
    my $g = Langertha::Holmgang::Grader->new;
    is( $g->replay( $c, [ { tool => 'dial_set', args => { value => 41.5 } } ] )->{status}, 'passed', 'graded: on the bound passes' );
    my $r = $g->replay( $c, [ { tool => 'dial_set', args => { value => '41.4' } } ] );
    is( $r->{status}, 'failed', 'graded: outside fails' );
    is( $r->{rules}[0]{reason}, 'is "41.4", not within 0.5 of 42', '... with the reason' );
  }
}

my $rule = '{ title: peak read, state: dial.value, equals: 42, tolerance: 0.5 }';
my $with = sub { my ( $r ) = @_; $CASE =~ s/\Q$rule\E/$r/r };
refused( $with->('{ title: peak read, state: dial.value, tolerance: 0.5 }'), qr/rules\[0\]\.tolerance\z/, qr/needs equals/,
  'tolerance without equals', head => $HEAD );
refused( $with->('{ title: peak read, state: dial.value, regex: "^4", tolerance: 0.5 }'), qr/rules\[0\]\.tolerance\z/, qr/needs equals/,
  '... beside another expectation', head => $HEAD );
refused( $with->('{ title: peak read, state: dial.value, equals: high, tolerance: 0.5 }'), qr/rules\[0\]\.equals\z/, qr/number expected/,
  'equals that is no number', head => $HEAD );
refused( $with->('{ title: peak read, state: dial.value, equals: 42, tolerance: -1 }'), qr/rules\[0\]\.tolerance\z/, qr/0 or more/,
  'negative tolerance', head => $HEAD );
refused( $with->('{ title: peak read, state: dial.value, equals: 42, tolerance: wide }'), qr/rules\[0\]\.tolerance\z/, qr/0 or more/,
  'tolerance that is text', head => $HEAD );
refused( $with->('{ title: peak read, state: dial.value, equals: 42, tolerance: [1] }'), qr/rules\[0\]\.tolerance\z/, qr/0 or more/,
  'tolerance that is a list', head => $HEAD );
refused( $with->('{ title: peak read, state: dial.value, equals: 42, tolerances: 0.5 }'), qr/rules\[0\]\.tolerances\z/, qr/unknown key/,
  'a typo stays an unknown key', head => $HEAD );
refused( $CASE =~ s/value: 43/value: 42.4/r, qr/wrong_solutions\[0\]/, qr/wrong solution "next bar" passes/,
  'lint: a wrong solution inside the tolerance keeps the case from loading', head => $HEAD );
refused( $CASE =~ s/value: 42\.3/value: 42.6/r, qr/: solution\z/, qr/does not pass/,
  'lint: a reference solution outside the tolerance keeps the case from loading', head => $HEAD );

done_testing;
