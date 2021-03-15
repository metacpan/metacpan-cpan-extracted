#!perl
use Test::Most tests => 24;
my $deeply = \&eq_or_diff;

use List::GroupingPriorityQueue
  qw(grpriq_add grpriq_min grpriq_min_values grpriq_max grpriq_max_values);

my $queue = [];

grpriq_add( $queue, 2, 're' );
$deeply->( $queue, [ [ ['re'], 2 ] ] );

grpriq_add( $queue, 8, 'bi' );
$deeply->( $queue, [ [ ['re'], 2 ], [ ['bi'], 8 ] ] );

# synopsis
#for my $entry (@{$queue}) {
#    my ($payload_r, $priority) = @{$entry};
#    use Data::Dumper; diag $priority, " ", Dumper $payload_r;
#}

grpriq_add( $queue, 0, 'no' );
$deeply->( $queue, [ [ ['no'], 0 ], [ ['re'], 2 ], [ ['bi'], 8 ] ] );

grpriq_add( $queue, 8, 'eight' );
$deeply->( $queue, [ [ ['no'], 0 ], [ ['re'], 2 ], [ [ 'bi', 'eight' ], 8 ] ] );

grpriq_add( $queue, 0, 'zero' );
$deeply->(
    $queue, [ [ [ 'no', 'zero' ], 0 ], [ ['re'], 2 ], [ [ 'bi', 'eight' ], 8 ] ]
);

grpriq_add( $queue, 1, 'pa' );
$deeply->(
    $queue,
    [   [ [ 'no', 'zero' ],  0 ],
        [ ['pa'],            1 ],
        [ ['re'],            2 ],
        [ [ 'bi', 'eight' ], 8 ]
    ]
);

grpriq_add( $queue, 5, 'mu' );
$deeply->(
    $queue,
    [   [ [ 'no', 'zero' ],  0 ],
        [ ['pa'],            1 ],
        [ ['re'],            2 ],
        [ ['mu'],            5 ],
        [ [ 'bi', 'eight' ], 8 ]
    ]
);

grpriq_add( $queue, 5, 'five' );
$deeply->(
    $queue,
    [   [ [ 'no', 'zero' ],  0 ],
        [ ['pa'],            1 ],
        [ ['re'],            2 ],
        [ [ 'mu', 'five' ],  5 ],
        [ [ 'bi', 'eight' ], 8 ]
    ]
);

$deeply->( grpriq_min($queue),        [ [ 'no', 'zero' ], 0 ] );
$deeply->( grpriq_min_values($queue), ['pa'] );
$deeply->( grpriq_max($queue),        [ [ 'bi', 'eight' ], 8 ] );
$deeply->( grpriq_max_values($queue), [ 'mu', 'five' ] );

$queue = [];
is( grpriq_min_values($queue), undef );
is( grpriq_max_values($queue), undef );

grpriq_add( $queue, 99, qw{so so} );
grpriq_add( $queue, 99, qw{birje botpi} );
$deeply->( grpriq_min($queue), [ [qw{so so birje botpi}], 99 ] );

# OO
my $pq = List::GroupingPriorityQueue->new;

# this uses the more extensively tested grpriq_add
$pq->insert( 2, 'cat' );
$pq->insert( 4, 'dog' );
$pq->insert( 2, 'mlatu' );
$pq->insert( 3, 'finpe' );
$pq->insert( 8, 'cribe' );
$pq->insert( 5, 'tirxu' );

$deeply->( $pq->pop, [qw/cat mlatu/] );
$deeply->( $pq->min, [ ['finpe'], 3 ] );
$deeply->( $pq->max, [ ['cribe'], 8 ] );

$deeply->( $pq->min_values, ['dog'] );
$deeply->( $pq->max_values, ['tirxu'] );

is( $pq->min_values, undef );
is( $pq->max_values, undef );

# ->each
$pq->insert(qw/5 perli/);
$pq->insert(qw/1 plise/);
my ( @gismu, @priorities );
$pq->each(
    sub {
        my ( $pay, $pri ) = @_;
        push @gismu,      @$pay;
        push @priorities, $pri;
    }
);
$deeply->( \@priorities, [ 1, 5 ] );
$deeply->( \@gismu,      [qw/plise perli/] );
