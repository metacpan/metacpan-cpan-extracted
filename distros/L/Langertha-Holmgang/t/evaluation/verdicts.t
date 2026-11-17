#!/usr/bin/env perl
# Verdicts per target, variant and suite (ADR 0008), ported from cai-platform
# t/eval_batch_verdicts.t and the verdict subtest of t/db/eval_batch.t. What
# cai-platform calls one run per round is one run with repetitions here.
# Claimed: (1) k is the run's repeat, pass_k the share of cases passed in ALL
# k repetitions, pass_any (pass@k) in at least one; (2) a repetition that is
# missing or ended in any status but passed has not passed; (3) case_results
# per case in order of the suite; (4) threshold.pass_rate and pass_k: below is
# not ok; (5) a hard case with one forbidden call in any repetition is not ok
# whatever the rate, a soft one only lowers the rate; (6) weights weigh rate
# and pass_k; (7) a run that did not complete is never ok, with or without a
# threshold (cai-platform Eval::Batch::verdicts runs_aborted, ported in k58);
# repetitions without any result but error (target not reached) are counted;
# a suite in which no repetition was measured at all is not ok, with or
# without a threshold, shown NOT MEASURED, while some unmeasured repetitions
# next to a measured one do not decide ok (ADR 0008 k73 amendment, reversing
# part of k58; the partial rule is ADR 0009 k42). Invented data only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Test::Fatal qw( exception );

use Holmgang::EvalReport qw( report evaluation );
use Langertha::Holmgang::Evaluation;

# rounds( target, suite, [ case => status, … ], … ) — one run, one repetition per list
sub rounds {
  my ( $target, $suite, @rounds ) = @_;
  my @res;
  for my $i ( 0 .. $#rounds ) {
    my @st = @{ $rounds[$i] };
    while ( my ( $id, $status ) = splice @st, 0, 2 ) {
      my ( $s, $fc ) = split /:/, $status;
      push @res, [ $id, $i + 1, $s, $fc ];
    }
  }
  return { target => $target, suite => $suite, repeat => scalar @rounds, results => \@res };
}

sub one {
  my ( $runs, $th ) = @_;
  return evaluation( $runs, thresholds => $th // {} )->verdicts->[0];
}

subtest 'all passed' => sub {
  my $v = one( [ rounds( 'm', 's', map { [ a => 'passed', b => 'passed' ] } 1 .. 3 ) ] );
  is $v->{k}, 3, 'k = 3';
  is $v->{pass_k}, 1, 'pass^k 1';
  is $v->{pass_any}, 1, 'pass@k 1';
  is_deeply $v->{case_results}, [ { case_id => 'a', passed => 3, repetitions => 3 },
    { case_id => 'b', passed => 3, repetitions => 3 } ], 'case_results compact';
  ok $v->{ok}, 'ok';
  is $v->{pass_k_min}, undef, 'without threshold pass_k_min undef';
  is $v->{pass_rate}, undef, 'and pass_rate undef';
};

my $wobbly = rounds( 'm', 's',
  [ a => 'passed', b => 'passed', c => 'passed', d => 'failed' ],
  [ a => 'passed', b => 'failed', c => 'passed', d => 'failed' ],
  [ a => 'passed', b => 'passed', c => 'passed', d => 'failed' ] );

subtest 'one case wobbles' => sub {
  my $v = one( [$wobbly] );
  is $v->{k}, 3, 'k = 3';
  is $v->{pass_k}, 0.5, 'pass^k 2/4';
  is $v->{pass_any}, 0.75, 'pass@k 3/4 (d never passed)';
  is $v->{rate}, 0.6667, 'rate 8/12';
  is $v->{results}, 12, '12 results';
  is $v->{passed}, 8, '8 passed';
  is_deeply $v->{counts}, { passed => 8, failed => 4, uncertain => 0, turn_limit => 0,
    error => 0, context_exceeded => 0, no_vision => 0 }, 'every status counted under its own name';
  is_deeply $v->{case_results}[1], { case_id => 'b', passed => 2, repetitions => 3 }, 'b: 2 of 3';
  ok $v->{ok}, 'without threshold ok';
};

subtest 'not passed: every status but passed' => sub {
  my $v = one( [ rounds( 'm', 's', [ a => 'passed', b => 'passed' ], [ a => 'error', b => 'passed' ] ) ] );
  is $v->{pass_k}, 0.5, 'error in one repetition: not passed for pass^k';
  is $v->{pass_any}, 1, 'pass@k: passed in the other';
  is_deeply $v->{case_results}[0], { case_id => 'a', passed => 1, repetitions => 2 }, 'a: 1 of 2';
  for my $st (qw( uncertain context_exceeded no_vision turn_limit failed )) {
    my $w = one( [ rounds( 'm', 's', [ a => 'passed' ], [ a => $st ] ) ] );
    is $w->{pass_k}, 0, $st.' in one repetition: not passed';
    is $w->{rate}, 0.5, '... and in the rate denominator';
    is $w->{counts}{$st}, 1, '... counted as '.$st;
  }
};

subtest 'a repetition is missing' => sub {
  my $v = one( [ rounds( 'm', 's', [ a => 'passed', b => 'passed' ], [ a => 'passed' ] ) ] );
  is $v->{k}, 2, 'k = 2';
  is $v->{pass_k}, 0.5, 'missing repetition: not passed';
  is_deeply $v->{case_results}[1], { case_id => 'b', passed => 1, repetitions => 1 }, 'b: 1 of 1 present';
  is $v->{rate}, 1, 'rate over the results present';
  $v = one( [ rounds( 'm', 's', [ a => 'passed' ], [] ) ] );
  is $v->{pass_k}, 0, 'empty second repetition: pass^k 0';
  is $v->{pass_any}, 1, 'pass@k 1';
};

subtest 'threshold pass_k' => sub {
  my $v = one( [$wobbly], { s => { pass_k => 0.6 } } );
  is $v->{pass_k_min}, 0.6, 'pass_k_min 0.6';
  is $v->{pass_rate}, undef, 'no pass_rate';
  ok !$v->{ok}, 'pass^k 0.5 below: not ok';
  ok one( [$wobbly], { s => { pass_k => 0.5 } } )->{ok}, 'pass^k 0.5 reached: ok';
  ok one( [$wobbly], { s => { pass_rate => 0.6, pass_k => 0.5 } } )->{ok}, 'both reached: ok';
  ok !one( [$wobbly], { s => { pass_rate => 0.7, pass_k => 0.5 } } )->{ok}, 'pass_rate missed: not ok';
  ok one( [$wobbly], { s => { pass_rate => 0.5 } } )->{ok}, 'only pass_rate: pass^k does not decide';
  my $empty = { target => 'm', suite => 's', repeat => 1, cases => ['a'], results => [] };
  ok !one( [$empty], { s => { pass_k => 0.1 } } )->{ok}, 'no results with pass_k threshold: not ok';
  ok !one( [$empty], { s => { pass_rate => 0.1 } } )->{ok}, 'no results with pass_rate threshold: not ok';
  my $e = one( [$empty] );
  is $e->{pass_k}, undef, 'no results: pass_k undef';
  is $e->{rate}, undef, '... rate undef';
  is $e->{repetitions_error}, 1, '... the one repetition measured nothing';
  # flipped on purpose (k73): k58 claimed "no results, no threshold: ok"
  ok !$e->{ok}, '... without threshold not ok either: no repetition measured (k73)';
};

subtest 'target not reached, run not finished (k58)' => sub {
  my $v = one( [ rounds( 'm', 's', [ a => 'error', b => 'error' ] ) ] );
  is $v->{repetitions_error}, 1, 'every case error: the repetition measured nothing';
  is $v->{unfinished}, undef, 'run complete';
  # flipped on purpose (k73): k58 claimed "ok without threshold: counted, not
  # deciding" for this suite of one repetition, all error -- k = 1 makes it a
  # suite with no measured repetition at all, so it is not ok now
  ok !$v->{ok}, 'all error in the only repetition, no threshold: not ok (k73)';
  $v = one( [ rounds( 'm', 's', [ a => 'error', b => 'error' ], [ a => 'error', b => 'error' ] ) ] );
  is $v->{repetitions_error}, 2, 'all error in both repetitions: both measured nothing';
  ok !$v->{ok}, '... not ok without threshold (k73)';
  $v = one( [ rounds( 'm', 's', [ a => 'error' ], [] ) ] );
  is $v->{repetitions_error}, 2, 'one repetition all error, the other without any result: neither measured';
  ok !$v->{ok}, '... not ok (k73)';
  ok !one( [ rounds( 'm', 's', [ a => 'error', b => 'error' ] ) ], { s => { pass_rate => 0.1 } } )->{ok},
    'all error with a threshold: not ok';
  # the k58 claim "counted, not deciding" holds where something was measured (ADR 0009 k42)
  $v = one( [ rounds( 'm', 's', [ a => 'error', b => 'error' ], [ a => 'passed', b => 'failed' ] ) ] );
  is $v->{repetitions_error}, 1, 'one of two repetitions measured nothing';
  ok $v->{ok}, '... the other was measured: ok without threshold, counted, not deciding (ADR 0009 k42)';
  $v = one( [ rounds( 'm', 's', [ a => 'error', b => 'failed' ] ) ] );
  is $v->{repetitions_error}, 0, 'one case reached the target: measured';
  ok $v->{ok}, '... ok without threshold';
  $v = one( [ rounds( 'm', 's', [ a => 'context_exceeded' ] ) ] );
  is $v->{repetitions_error}, 0, 'context_exceeded counts as reached';
  ok $v->{ok}, '... all context_exceeded is a measurement: ok without threshold (k73)';
  $v = one( [ rounds( 'm', 's', [ a => 'no_vision', b => 'context_exceeded' ] ) ] );
  is $v->{repetitions_error}, 0, 'no_vision counts as reached';
  ok $v->{ok}, '... ok without threshold (k73)';
  $v = one( [ rounds( 'm', 's', [ a => 'passed', b => 'passed' ], [ a => 'error', b => 'error' ], [ a => 'passed', b => 'passed' ] ) ],
    { s => { pass_rate => 0.5 } } );
  is $v->{rate}, 0.6667, 'rate above the threshold';
  is $v->{repetitions_error}, 1, '... one of three repetitions measured nothing';
  ok $v->{ok}, '... the threshold decides';
  $v = one( [ rounds( 'm', 's', [ a => 'passed' ], [] ) ] );
  is $v->{repetitions_error}, 1, 'a repetition without any result counts';
  my $cut = { %{ rounds( 'm', 's', [ a => 'passed' ] ) }, status => 'cancelled', error => 'stopped by hand' };
  $v = one( [$cut] );
  is $v->{repetitions_error}, 0, 'cancelled run: what it has was measured';
  is_deeply $v->{unfinished}, { status => 'cancelled', error => 'stopped by hand' }, '... unfinished names status and error';
  ok !$v->{ok}, '... a partial state is not ok, all passed though';
  $v = one( [ { %{ rounds( 'm', 's', [ a => 'passed' ] ) }, status => 'aborted', error => undef } ], { s => { pass_rate => 0.5 } } );
  is_deeply $v->{unfinished}, { status => 'aborted', error => undef }, 'aborted run';
  ok !$v->{ok}, '... not ok above the threshold';
  my $ev = evaluation( [$cut, rounds( 'm', 'o', [ x => 'error' ] )] );
  like $ev->to_text, qr/^  run cancelled: stopped by hand$/m, 'text names the unfinished run';
  like $ev->to_text, qr/^  no result but error in 1 of 1 repetition\(s\): nothing measured$/m, '... and the repetitions without a measurement';
  like $ev->to_markdown, qr/^- m \/ plain \/ s: run cancelled: stopped by hand$/m, 'markdown note names its row';
  like $ev->to_text, qr/^m\s+plain\s+o\s+0\/1\s.*\sNOT MEASURED$/m, 'nothing measured: the verdict reads NOT MEASURED (k73)';
  like $ev->to_text, qr/^m\s+plain\s+s\s+1\/1\s.*\sNOT PASSED$/m, '... a verdict not ok for another reason NOT PASSED';
  like $ev->to_markdown, qr/^\| m \| plain \| o \| 0\/1 \|.* \| NOT MEASURED \|$/m, '... in markdown too';
  like $ev->to_markdown, qr/^\| m \| plain \| s \| 1\/1 \|.* \| NOT PASSED \|$/m, '... and NOT PASSED there';
  my $partial = evaluation( [ rounds( 'm', 's', [ a => 'error' ], [ a => 'passed' ] ) ] )->to_text;
  like $partial, qr/^m\s+plain\s+s\s+1\/2\s.*\sok$/m, 'one repetition measured: ok, not NOT MEASURED';
  like $partial, qr/^  no result but error in 1 of 2 repetition\(s\): nothing measured$/m, '... the other noted';
  my $none = evaluation( [ { target => 'm', suite => 's', repeat => 1, cases => ['a'], results => [],
    status => 'cancelled', error => 'stopped at once' } ] )->to_text;
  like $none, qr/^m\s+plain\s+s\s+0\/0\s.*\sNOT MEASURED$/m,
    'a run cancelled before any result: NOT MEASURED, the stronger word (k73)';
  like $none, qr/^  run cancelled: stopped at once$/m, '... the run noted';
  my $long = { %{ rounds( 'm', 's', [ a => 'passed' ] ) }, status => 'aborted', error => "line one\n  line two ".( 'x' x 300 ) };
  my ($note) = evaluation( [$long] )->to_text =~ /^  (run aborted: .*)$/m;
  like $note, qr/\Arun aborted: line one line two x+ \x{2026}\z/, 'a long multi-line run error: one line, cut with an ellipsis';
  is length( $note ), length( 'run aborted: ' ) + 200 + 2, '... at 200 characters';
};

subtest 'per target apart, in order of appearance' => sub {
  my $v = evaluation( [ rounds( 'm1', 's', [ a => 'passed' ], [ a => 'passed' ] ),
    rounds( 'm2', 's', [ a => 'failed' ] ) ] )->verdicts;
  is_deeply [ map { [ $_->{target}, $_->{k}, $_->{pass_k} ] } @$v ], [ [ 'm1', 2, 1 ], [ 'm2', 1, 0 ] ],
    'own k and pass^k per target';
  my $w = evaluation( [ { %{ rounds( 'm', 's', [ a => 'passed' ] ) }, variant => 'think' },
    { %{ rounds( 'm', 's', [ a => 'failed' ] ) }, variant => 'plain' } ] )->verdicts;
  is_deeply [ map { [ $_->{variant}, $_->{rate} ] } @$w ], [ [ 'think', 1 ], [ 'plain', 0 ] ],
    'same target, two variants: two verdicts';
};

subtest 'threshold and hard cases' => sub {
  my %th = ( s => { pass_rate => 0.5 } );
  my $hard = sub { my ( $r ) = @_; $r->{cases} = [ { id => 'inj', hard => 1 }, 'wahl' ]; $r };
  my $v = evaluation( [
    $hard->( rounds( 'm', 's', [ inj => 'passed', wahl => 'failed:2' ], [ inj => 'passed', wahl => 'passed' ] ) ),
    rounds( 'm', 'o', [ x => 'failed:1' ] ),
  ], thresholds => \%th )->verdicts;
  is_deeply [ map { [ @{$_}{qw( suite_id k results passed rate pass_rate )}, $_->{ok} ? 1 : 0 ] } @$v ],
    [ [ 's', 2, 4, 3, 0.75, 0.5, 1 ], [ 'o', 1, 1, 0, 0, undef, 1 ] ],
    'above threshold ok; soft forbidden call and no threshold: only the rate';
  $v = evaluation( [ $hard->( rounds( 'm', 's', [ inj => 'passed', wahl => 'passed' ],
    [ inj => 'failed:1', wahl => 'passed' ], [ inj => 'passed', wahl => 'passed' ] ) ) ], thresholds => \%th )->verdicts;
  is $v->[0]{rate}, 0.8333, 'rate above the threshold';
  ok !$v->[0]{ok}, '... but one forbidden call in a hard case in one of three repetitions: not ok';
  is_deeply $v->[0]{hard_failed}, [ { case_id => 'inj', forbidden_calls => 1, repetitions => 1 } ],
    '... names case, calls, repetitions';
  $v = evaluation( [ $hard->( rounds( 'm', 's', [ inj => 'passed', wahl => 'failed', w2 => 'failed' ] ) ) ],
    thresholds => \%th )->verdicts;
  ok !$v->[0]{ok}, 'below the threshold: not ok';
  my $tagged = rounds( 'm', 's', [ i => 'passed:1' ] );
  $tagged->{cases} = [ { id => 'i', tags => ['verbot'], hard => undef } ];
  ok !one( [$tagged] )->{ok}, 'hard from the tag verbot when the report says nothing';
  $tagged->{cases} = [ { id => 'i', tags => ['injection'], hard => undef } ];
  ok !one( [$tagged] )->{ok}, '... and from injection';
  $tagged->{cases} = [ { id => 'i', tags => ['injection'], hard => 0 } ];
  ok one( [$tagged] )->{ok}, 'the report\'s hard wins over the tags';
};

subtest 'weights' => sub {
  my $r = rounds( 'm', 's', [ a => 'passed', b => 'failed' ], [ a => 'passed', b => 'passed' ] );
  $r->{cases} = [ { id => 'a', weight => 3 }, { id => 'b', weight => 1 } ];
  my $v = one( [$r] );
  is $v->{rate}, 0.875, 'rate weighted: (3+3+1) / (3+3+1+1)';
  is $v->{pass_k}, 0.75, 'pass^k weighted: 3 / 4';
  is $v->{pass_any}, 1, 'pass@k weighted';
  is $v->{passed}, 3, 'passed stays a count';
};

subtest 'reports are merged first' => sub {
  my $rep = report( rounds( 'm', 's', [ a => 'passed' ], [ a => 'failed' ] ) );
  my $again = Langertha::Holmgang::Report->from_json( $rep->to_json );
  my $v = Langertha::Holmgang::Evaluation->new( reports => [ $rep, $again ] )->verdicts;
  is scalar @$v, 1, 'one verdict';
  is $v->[0]{results}, 2, 'the same repetitions count once';
  is_deeply( Langertha::Holmgang::Evaluation->new( report => $again )->as_data,
    Langertha::Holmgang::Evaluation->new( report => $rep )->as_data, 'a report read back evaluates the same' );
};

subtest 'refusals' => sub {
  like exception { Langertha::Holmgang::Evaluation->new( reports => [] ) }, qr/needs reports/, 'no report';
  like exception { Langertha::Holmgang::Evaluation->new( reports => [ {} ] ) }, qr/is not a Langertha::Holmgang::Report/,
    'not a report';
  like exception { Langertha::Holmgang::Evaluation->new( report => report(), thresholds => [] ) },
    qr/thresholds must be a hash/, 'thresholds not a hash';
};

done_testing;
