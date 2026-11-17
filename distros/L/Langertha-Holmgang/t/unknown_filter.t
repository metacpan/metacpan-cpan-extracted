#!/usr/bin/env perl
# An argument filter ({name|filter}) the case names but format 2 does not know (k35),
# on invented cases (ADR 0003).
# Claims: (1) lint refuses an unknown filter at load time wherever the world would apply
# it -- in a handler's apply (path, value, at, from, to) and in the when path of a
# handler or an observation -- even when no solution reaches that handler, with field
# and reason; the known filters split, int and lc load; a {name|Upper} that is no filter
# pattern stays text and loads. (2) Should such a case run anyway (lint bypassed), the
# model never sees the filter's error text: the tool result in the outgoing request is
# the world's generic refusal, without the filter's name, a file or a line. (3) The
# same for an unknown filter in a when path (k39): World->call never dies; a handler
# whose when cannot be evaluated does not fit (the generic refusal, state unchanged),
# an observation whose when cannot be evaluated does not answer (the simulator does).
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Holmgang::SuiteDir qw( suite_dir refused try_load );
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer tool );
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Target;
use Langertha::Holmgang::World;

use constant World => 'Langertha::Holmgang::World';

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

# a fan plus a label tool the reference solution never calls; __APPLY__ / __WHEN__ are
# its handler's change and condition
my $HEAD = <<'Y';
format: 2
id: __ID__
version: 1
title: Fan
tools:
  - name: fan_set
    description: Sets the fan level.
    parameters: { type: object, required: [level], properties: { level: { type: string, enum: [off, low, high] } } }
    handlers:
      - apply: [ { set: fan.level, value: '{level}' } ]
        output: "fan <: $state.fan.level :>"
  - name: fan_label
    description: Labels the fan.
    parameters: { type: object, required: [label], properties: { label: { type: string }, n: { type: string } } }
    handlers:
      - when: [ __WHEN__ ]
        apply: [ __APPLY__ ]
        output: labelled
  - name: run_command
    description: Shell.
    simulator: run_command
    parameters: { type: object, required: [host, command], properties: { host: { type: string }, command: { type: string } } }
Y

my $CASE = <<'Y';
id: c1
title: Cool the room
messages: [ { role: user, content: "It is hot in here." } ]
state: { fan: { level: "off", label: "", tags: [ a, b ] } }
rules:
  - { title: fan on high, state: fan.level, equals: high }
  - { title: nothing else, unchanged_except: [ fan.level ] }
solution: [ { tool: fan_set, args: { level: high } } ]
alternatives: [ { title: stepwise, calls: [ { tool: fan_set, args: { level: low } }, { tool: fan_set, args: { level: high } } ] } ]
wrong_solutions: [ { title: low only, calls: [ { tool: fan_set, args: { level: low } } ] } ]
Y

my $WHEN = '{ path: fan, exists: true }';

sub head {
  my ( %o ) = @_;
  my $h = $HEAD;
  $h =~ s/__WHEN__/$o{when} \/\/ $WHEN/e;
  $h =~ s/__APPLY__/$o{apply}/e;
  return $h;
}

# --- (1) lint refuses an unknown filter at load time --------------------------------
my $F = qr/\Acases\/c1\.yaml: tools\.fan_label\.handlers\[0\]/;
my $WHY = qr/unknown filter 'upper'/;
refused( $CASE, qr/$F\.apply\[0\]\.value\z/, $WHY, 'unknown filter in an apply value: refused, though no solution reaches it',
  head => head( apply => q({ set: fan.label, value: '{label|upper}' }) ) );
refused( $CASE, qr/$F\.apply\[0\]\.value\.text\z/, $WHY, '... nested inside a value',
  head => head( apply => q({ set: fan.label, value: { text: 'fan {label|upper}' } }) ) );
refused( $CASE, qr/$F\.apply\[0\]\.set\z/, $WHY, '... in the path of a change',
  head => head( apply => q({ set: 'fan.{label|upper}', value: x }) ) );
refused( $CASE, qr/$F\.apply\[0\]\.at\z/, $WHY, '... in the at of an insert',
  head => head( apply => q({ insert: fan.tags, at: '{n|upper}', value: x }) ) );
refused( $CASE, qr/$F\.apply\[0\]\.to\z/, $WHY, '... in the to of a move',
  head => head( apply => q({ move: fan.tags, from: '0', to: '{n|upper}' }) ) );
refused( $CASE, qr/$F\.when\[0\]\.path\z/, $WHY, '... in the when path of a handler',
  head => head( when => q({ path: 'fan.{label|upper}', exists: true }), apply => q({ set: fan.label, value: x }) ) );
refused( $CASE.q(observe: [ { match: { host: '^h$', command: '^ping' }, when: [ { path: 'fan.{host|upper}', exists: true } ], output: seen } ])."\n",
  qr/\Acases\/c1\.yaml: observe\[0\]\.when\[0\]\.path\z/, $WHY, '... in the when path of an observation',
  head => head( apply => q({ set: fan.label, value: x }) ) );

for my $known ( qw( split int lc ) ) {
  my ( $s, $err ) = try_load( $CASE, head => head( apply => "{ set: fan.label, value: '{label|$known}' }" ) );
  ok( $s, "known filter $known loads" ) or diag "$err";
}
{
  my ( $s, $err ) = try_load( $CASE, head => head( apply => q({ set: fan.label, value: 'x {label|Upper} {label|}' }) ) );
  ok( $s, 'a brace text that is no filter pattern stays text and loads' ) or diag "$err";
}

# --- (2) at run time the model never sees the filter's error text -------------------
{
  package NoLint;
  sub new  { bless {}, shift }
  sub lint { 1 }
}
my $dir   = suite_dir( head => head( apply => q({ set: fan.label, value: '{label|upper}' }) ), cases => { 'c1.yaml' => $CASE } );
my $suite = Langertha::Holmgang::Loader->new( lint => NoLint->new )->load($dir);
my ( $case ) = @{ $suite->cases };

my $e = Langertha::Engine::Virtual->new( script => [ tool( fan_label => { label => 'quiet' } ), answer('ok') ] );
my $r = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ) )->run_case($case);

my ( $result ) = grep { $_->{role} eq 'tool' } @{ $e->requests->[1]{body}{messages} };
ok( $result, 'the tool result goes back in the next request' );
my $seen = $result->{content} // '';
unlike( $seen, qr/filter|upper|Expectation|World|\.pm|line \d/i, 'the model sees no filter error text, file or line' )
  or diag $seen;
is( $seen, 'Fehler: dieser Aufruf ist in diesem Szenario nicht vorgesehen.', '... only the generic refusal' );
is( $r->{calls}[0]{succeeded}, 0, '... and the call failed' );
is( $r->{state}{fan}{label}, '', '... leaving the state unchanged' );

# --- (3) an unknown filter in a when path, lint bypassed (k39) ----------------------
{
  my $dir = suite_dir( head => head( when => q({ path: 'fan.{label|upper}', exists: true }), apply => q({ set: fan.label, value: x }) ),
    cases => { 'c1.yaml' => $CASE } );
  my ( $case ) = @{ Langertha::Holmgang::Loader->new( lint => NoLint->new )->load($dir)->cases };

  my $world = World->new( state => $case->initial_state, tools => $case->tools, observe => $case->observe // [] );
  my @got;
  my $died = !eval { @got = $world->call( fan_label => { label => 'quiet' } ); 1 };
  ok( !$died, 'handler when path: World->call does not die' ) or diag $@;
  is( $got[0], 'Fehler: dieser Aufruf ist in diesem Szenario nicht vorgesehen.', '... the handler does not fit: generic refusal' );
  is( $got[2], 0, '... the call failed' );
  is( $world->state->{fan}{label}, '', '... state unchanged' );

  my $e = Langertha::Engine::Virtual->new( script => [ tool( fan_label => { label => 'quiet' } ), answer('ok') ] );
  my $r = eval { Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ) )->run_case($case) };
  ok( $r, '... the run goes on' ) or diag $@;
  my ( $res ) = grep { $_->{role} eq 'tool' } @{ ( $e->requests->[1] // {} )->{body}{messages} || [] };
  is( $res && $res->{content}, 'Fehler: dieser Aufruf ist in diesem Szenario nicht vorgesehen.', '... the outgoing tool result is the generic refusal' );
}
{
  my $obs = q(observe: [ { match: { host: '^h1$', command: '^echo' }, when: [ { path: 'fan.{host|upper}', exists: true } ], output: OBSERVED } ]);
  my $dir = suite_dir( head => head( apply => q({ set: fan.label, value: x }) ),
    cases => { 'c1.yaml' => ( $CASE =~ s/state: \{ fan:/state: { h1: { type: linux }, fan:/r ).$obs."\n" } );
  my ( $case ) = @{ Langertha::Holmgang::Loader->new( lint => NoLint->new )->load($dir)->cases };
  my $world = World->new( state => $case->initial_state, tools => $case->tools, observe => $case->observe // [] );
  my @got;
  my $died = !eval { @got = $world->call( run_command => { host => 'h1', command => 'echo hallo' } ); 1 };
  ok( !$died, 'observation when path: World->call does not die' ) or diag $@;
  isnt( $got[0], 'OBSERVED', '... the observation does not answer' );
  like( $got[0] // '', qr/hallo/, '... the simulator does' );
}

done_testing;
