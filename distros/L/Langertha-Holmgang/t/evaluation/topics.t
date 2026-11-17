#!/usr/bin/env perl
# Values per topic, overall as the mean of the topics, length-tier curves
# (ADR 0008). The topic part is ported from cai-platform t/db/eval_batch.t
# ("nacheinander, Werte je Thema") without the database. Claimed: (1) per row
# (target and variant) and topic the results, every status under its own name
# and the weighted share passed; (2) overall is the mean of the topic rates,
# never one share over all cases; (3) curves per tier, in tier order, keep
# hits, context_exceeded and errors apart; untiered cases are on no curve;
# (4) the same curves per difficulty (k57), leicht before mittel before schwer.
# Invented data only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::EvalReport qw( evaluation );

sub run_of {
  my ( $target, $suite, $topic, @res ) = @_;
  return { target => $target, suite => $suite, topic => $topic, results => [ map { [ split /:/ ] } @res ] };
}

subtest 'per topic, as cai-platform by_topic' => sub {
  # two topics: licht (two suites) and wetter (one); each model solves c1, not c2
  my @runs = map {
    my $m = $_;
    map { run_of( $m, $_->[0], $_->[1], 'c1:1:passed', 'c2:1:failed' ) }
      [ 'lampe-a', 'licht' ], [ 'lampe-b', 'licht' ], [ 'wetter', 'wetter' ];
  } 'Modell 2', 'Modell 1';
  my $e = evaluation( \@runs );
  is_deeply [ map { join ':', $_->{target}, $_->{topic}, $_->{results}, @{ $_->{counts} }{qw( passed failed )} } @{ $e->topics } ],
    [ 'Modell 2:licht:4:2:2', 'Modell 2:wetter:2:1:1', 'Modell 1:licht:4:2:2', 'Modell 1:wetter:2:1:1' ],
    'per target in order of appearance, topics by name';
  is_deeply $e->topics->[0]{suites}, [ 'lampe-a', 'lampe-b' ], 'suites of a topic';
  is $e->topics->[0]{rate}, 0.5, 'share passed';
  is_deeply [ map { [ $_->{target}, $_->{topics}, $_->{results}, $_->{rate} ] } @{ $e->overall } ],
    [ [ 'Modell 2', 2, 6, 0.5 ], [ 'Modell 1', 2, 6, 0.5 ] ], 'overall per target';
  ok !exists $e->topics->[0]{_row}, 'no internal key leaks';
};

subtest 'overall is the mean of the topics' => sub {
  my $e = evaluation( [
    run_of( 'm', 'hard', 'a', 'h:1:passed' ),
    run_of( 'm', 'easy', 'b', map { "e$_:1:failed" } 1 .. 9 ),
  ] );
  is_deeply [ map { $_->{rate} } @{ $e->topics } ], [ 1, 0 ], 'topic rates';
  is $e->overall->[0]{rate}, 0.5, 'overall 0.5, not 1/10';
  is $e->overall->[0]{results}, 10, 'results summed';
  is $e->overall->[0]{counts}{failed}, 9, 'counts summed';
  $e = evaluation( [ run_of( 'm', 'x', 'a', 'h:1:passed' ),
    { target => 'm', suite => 'y', topic => 'b', cases => ['n'], results => [] } ] );
  is $e->topics->[1]{rate}, undef, 'topic without results: rate null';
  is $e->overall->[0]{rate}, 1, '... and not in the mean';
  is $e->overall->[0]{topics}, 2, '... but counted as a topic';
};

subtest 'every status, weights, tokens, default topic' => sub {
  my $r = run_of( 'm', 's', undef, 'a:1:passed:0:100', 'b:1:no_vision', 'c:1:context_exceeded',
    'd:1:error', 'e:1:turn_limit:0:50', 'f:1:uncertain', 'g:1:failed' );
  $r->{cases} = [ { id => 'a', weight => 2.5 }, qw( b c d e f g ) ];
  my $t = evaluation( [$r] )->topics->[0];
  is $t->{topic}, 'sonstiges', 'suite without topic: sonstiges';
  is_deeply $t->{counts}, { map { $_ => 1 } qw( passed failed uncertain turn_limit error context_exceeded no_vision ) },
    'seven statuses, none folded into another';
  is $t->{results}, 7, 'not measured statuses are results';
  is $t->{weight}, 8.5, 'weight summed';
  is $t->{rate}, 0.2941, 'rate weighted over all results: 2.5 / 8.5';
  is_deeply $t->{tokens}, { input => 150, output => 2, reasoning => undef }, 'tokens summed, null when none';
};

subtest 'length tiers' => sub {
  my $r = run_of( 'm', 's', 'lang',
    'a:1:passed', 'a:2:context_exceeded',
    'b:1:error', 'b:2:passed',
    'c:1:context_exceeded', 'c:2:context_exceeded',
    'd:1:passed', 'd:2:passed',
    'u:1:failed', 'u:2:failed' );
  $r->{cases} = [ { id => 'a', tier => '160k' }, { id => 'b', tier => '32k' }, { id => 'c', tier => '16k', weight => 3 },
    { id => 'd', tier => '96k' }, 'u' ];
  my $e = evaluation( [$r] );
  my @c = @{ $e->tier_curves };
  is_deeply [ map { $_->{tier} } @c ], [qw( 16k 96k 160k 32k )], 'known tiers in order, others after';
  is_deeply [ map { [ @{$_}{qw( tier results rate context_exceeded_rate error_rate )} ] } @c ], [
    [ '16k', 2, 0, 1, 0 ],
    [ '96k', 2, 1, 0, 0 ],
    [ '160k', 2, 0.5, 0.5, 0 ],
    [ '32k', 2, 0.5, 0, 0.5 ],
  ], 'hits, context_exceeded and errors apart';
  is $c[0]{weight}, 6, 'tier weight';
  is $c[0]{counts}{context_exceeded}, 2, 'tier counts';
  ok !grep( { ( $_->{tier} // '' ) eq '' } @c ), 'untiered case on no curve';
  is $c[0]{topic}, 'lang', 'curve per topic';
  my $two = evaluation( [ $r, { %$r, target => 'n' } ] )->tier_curves;
  is_deeply [ map { $_->{target} } @$two ], [ ('m') x 4, ('n') x 4 ], 'curve per target';
  is_deeply $e->difficulty_curves, [], 'no difficulty: no difficulty curve';
};

subtest 'difficulties (k57)' => sub {
  my $r = run_of( 'm', 's', 'denken',
    'a:1:passed', 'a:2:passed',
    'b:1:passed', 'b:2:error',
    'c:1:failed', 'c:2:context_exceeded',
    'd:1:passed', 'd:2:failed',
    'u:1:failed', 'u:2:failed' );
  $r->{cases} = [ { id => 'c', difficulty => 'schwer', weight => 2 }, { id => 'd', difficulty => 'brutal' },
    { id => 'b', difficulty => 'mittel' }, { id => 'a', difficulty => 'leicht', tier => '16k' }, 'u' ];
  my @c = @{ evaluation( [$r] )->difficulty_curves };
  is_deeply [ map { $_->{difficulty} } @c ], [qw( leicht mittel schwer brutal )], 'known difficulties in order, others after';
  is_deeply [ map { [ @{$_}{qw( difficulty results rate context_exceeded_rate error_rate )} ] } @c ], [
    [ 'leicht', 2, 1, 0, 0 ],
    [ 'mittel', 2, 0.5, 0, 0.5 ],
    [ 'schwer', 2, 0, 0.5, 0 ],
    [ 'brutal', 2, 0.5, 0, 0 ],
  ], 'hits, context_exceeded and errors apart';
  is $c[2]{weight}, 4, 'weight';
  is $c[2]{counts}{failed}, 1, 'counts';
  is $c[0]{topic}, 'denken', 'curve per topic';
  ok !exists $c[0]{tier}, 'a difficulty curve carries no tier';
  is scalar @{ evaluation( [$r] )->tier_curves }, 1, 'tier and difficulty are independent axes';
};

done_testing;
