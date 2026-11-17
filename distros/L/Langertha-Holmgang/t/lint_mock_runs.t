#!/usr/bin/env perl
# Lint's two mock runs (cai-platform docs/entwurf-evals.md §3.5) through
# Langertha::Holmgang::Runner->lint_mock_runs, on invented cases (ADR 0003).
# Claims: the default loader runs them; replaying the reference solution
# against a mock model must pass (a solution that cannot finish within
# max_turns does not load, though its plain replay passes) and must give the
# same result twice (a world that answers differently each time does not
# load); answering text only must fail, and must pass in the "no tool"
# family.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Holmgang::SuiteDir qw( suite_dir try_load refused $FAN_HEAD $FAN_CASE );
use Langertha::Holmgang::Case;
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Lint;
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Simulators;
use Langertha::Holmgang::Target;

ok( Langertha::Holmgang::Loader->new->lint->has_mock_runs, 'the default loader lints with the mock runs' );

# the mock model: one call of the solution per turn, then an answer
{
  my ( $s ) = try_load($FAN_CASE);
  my $case = $s->cases->[0];
  my $e = Langertha::Holmgang::Runner->mock_engine($case);
  my $r = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ) )->run_case($case);
  is( $r->{status}, 'passed', 'mock model replaying the solution: passed' );
  is( scalar @{ $e->requests }, @{ $case->solution } + 1, '... one call per turn, then the answer' );
  $r = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new(
    engine => Langertha::Holmgang::Runner->mock_engine( $case, 'text' ) ) )->run_case($case);
  is( $r->{status}, 'failed', 'mock model answering text only: failed' );
  ok( !eval { Langertha::Holmgang::Runner->mock_engine( $case, 'guess' ); 1 }, 'mode checked' );
}

# a solution that needs more turns than max_turns allows
{
  my $short = $FAN_CASE."max_turns: 1\n";
  refused( $short, qr/\Acases\/c1\.yaml: solution\z/, qr/replaying the reference solution is turn_limit/,
    'solution cannot finish within max_turns: does not load' );
  my $plain = Langertha::Holmgang::Loader->new( lint => Langertha::Holmgang::Lint->new );
  my ( $s, $err ) = try_load( $short, loader => $plain );
  ok( $s, '... without the mock runs it would' ) or diag $err;
}

# a world that answers differently each time
{
  package Local::Sim::Counter;
  use Moose;
  with 'Langertha::Holmgang::Role::AnswerWorld';
  my $n = 0;
  sub device_type { 'counter' }
  sub tools { { ticket_open => [], ticket_list => [] } }
  sub tool {
    my ( $self, $world, $name, $args ) = @_;
    $world->{open} = 1 if $name eq 'ticket_open';
    return ( 'ticket '.++$n, 1 );
  }
  __PACKAGE__->meta->make_immutable;
}
{
  my $head = <<'Y';
format: 2
id: __ID__
version: 1
title: Desk
tools:
  - { name: ticket_open, description: Opens a ticket., simulator: counter, parameters: { type: object, properties: {} } }
  - { name: ticket_list, description: Lists the tickets., simulator: counter, parameters: { type: object, properties: {} } }
Y
  my $case = <<'Y';
id: c1
title: Open a ticket
messages: [ { role: user, content: "Open a ticket." } ]
state: { desk: { type: counter, open: 0 } }
rules: [ { title: ticket open, state: desk.open, equals: 1 } ]
solution: [ { tool: ticket_open, args: {} } ]
alternatives: [ { title: twice, calls: [ { tool: ticket_open, args: {} }, { tool: ticket_open, args: {} } ] } ]
wrong_solutions: [ { title: only looks, calls: [ { tool: ticket_list, args: {} } ] } ]
Y
  my $sims = Langertha::Holmgang::Simulators->new;
  $sims->register('Local::Sim::Counter');
  my $loader = Langertha::Holmgang::Loader->new( simulators => $sims );
  refused( $case, qr/\Acases\/c1\.yaml: solution\z/, qr/different result the second time/,
    'a world that answers differently: does not load', head => $head, loader => $loader );
  my $plain = Langertha::Holmgang::Loader->new( simulators => $sims, lint => Langertha::Holmgang::Lint->new(
    grader => Langertha::Holmgang::Grader->new( simulators => $sims ) ) );
  my ( $s, $err ) = try_load( $case, head => $head, loader => $plain );
  ok( $s, '... without the mock runs it would' ) or diag $err;
}

# the "no tool" family: text only is the right answer
{
  my $none = <<'Y';
id: c1
title: Just say thanks
messages: [ { role: user, content: "Thanks, that was all." } ]
state: { fan: { level: "off" } }
rules: [ { title: no tool, only_tools: [] } ]
solution: []
wrong_solutions: [ { title: needless call, calls: [ { tool: fan_set, args: { level: high } } ] } ]
Y
  my ( $s, $err ) = try_load($none);
  ok( $s, '"no tool" family: text only passes, the case loads' ) or diag $err;
}

# text only must fail outside the "no tool" family (the hook on its own: point 2
# of the lint refuses such a case before the mock runs are reached)
{
  my ( $s ) = try_load($FAN_CASE);
  my $fan = $s->cases->[0];
  my $case = Langertha::Holmgang::Case->new(
    id       => 'c1',
    tools    => $fan->tools,
    messages => [ { role => 'user', content => 'Keep it off.' } ],
    state    => { fan => { level => 'off' } },
    rules    => [ { title => 'fan off', state => 'fan.level', equals => 'off' } ],
    solution => [ { tool => 'fan_set', args => { level => 'off' } } ],
  );
  my $lint = Langertha::Holmgang::Lint->new;
  my $err = Langertha::Holmgang::Error->caught( do { eval { Langertha::Holmgang::Runner->lint_mock_runs->( $lint, $case, 'x' ) }; $@ } );
  ok( $err && $err->field eq 'x: rules' && $err->reason =~ /text only passes/, 'text only passes outside the family: refused' )
    or diag( $err // 'nothing thrown' );
}

done_testing;
