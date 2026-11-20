#!/usr/bin/env perl
# Scenarios (AppWorld's scenario goal completion). Claimed: cases with the same
# scenario are variants of one task; a scenario is solved only when every
# variant passed in all k repetitions; a case without scenario is a scenario of
# its own; verdicts carry scenarios only when a case of the suite has one, and
# it does not decide ok; the field survives a report round trip; the text
# notes it.
# Invented data only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::EvalReport qw( report evaluation );
use Langertha::Holmgang::Evaluation;
use Langertha::Holmgang::Report;

my $run = {
  target => 'm', suite => 's', repeat => 2,
  cases  => [ { id => 'a1', scenario => 'x' }, { id => 'a2', scenario => 'x' }, { id => 'b1', scenario => 'y' },
              { id => 'b2', scenario => 'y' }, 'c' ],
  results => [
    [ a1 => 1, 'passed' ], [ a1 => 2, 'passed' ], [ a2 => 1, 'passed' ], [ a2 => 2, 'passed' ],
    [ b1 => 1, 'passed' ], [ b1 => 2, 'passed' ], [ b2 => 1, 'passed' ], [ b2 => 2, 'failed' ],
    [ c  => 1, 'passed' ], [ c  => 2, 'passed' ],
  ],
};

my $v = evaluation( [$run] )->verdicts->[0];
is_deeply $v->{scenarios}, { total => 3, solved => 2, rate => 0.6667, unsolved => ['y'] },
  'x solved, y not (one variant failed once), c its own and solved';
is $v->{rate}, 0.9, 'the case rate is unchanged';
ok $v->{ok}, 'scenarios do not decide ok';

my $plain = evaluation( [ { target => 'm', suite => 's', results => [ [ a => 1, 'passed' ] ] } ] )->verdicts->[0];
ok !exists $plain->{scenarios}, 'no scenario in the suite: no field';

my $back = Langertha::Holmgang::Report->from_json( report($run)->to_json );
my ($c) = grep { $_->{case_id} eq 'a1' } @{ $back->runs->[0]{cases} };
is $c->{scenario}, 'x', 'scenario survives the report round trip';
my ($cc) = grep { $_->{case_id} eq 'c' } @{ $back->runs->[0]{cases} };
ok !exists $cc->{scenario}, '... and is omitted where absent';

like evaluation( [$run] )->to_text, qr/scenarios: 2\/3 solved in every variant \(66\.7%\)/, 'the text notes it';

done_testing;
