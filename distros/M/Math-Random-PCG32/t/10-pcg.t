#!perl
use 5.14.0;
use warnings;
use Math::Random::PCG32;
use Test2::V0;

can_ok(
    'Math::Random::PCG32',
    qw(coinflip decay irand irand64 irand_in irand_way
      rand rand_elm rand_from rand_idx roll sample)
);

my $rng = Math::Random::PCG32->new( 42, 54 );

# these at least agree with the "pcg32-demo" output compiled from
# https://github.com/imneme/pcg-c-basic as of commit bc39cd7
is( [ map $rng->irand, 1 .. 6 ],
    [ 0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e ] );

# another way to call the function is with the seed "object" as an
# argument which is faster than the OO form but risky (segfault) should
# the wrong thing get passed to a method of this module. so let's not
# advertise this in the docs...
#use Math::Random::PCG32 qw(irand);
#diag Math::Random::PCG32::irand( $rng );
#diag irand( $rng );
#diag $rng->irand;

my @letters = qw(a b c d e f g);
is( $rng->rand_idx( \@letters ), 5,   'rand_idx' );
is( $rng->rand_elm( \@letters ), 'b', 'rand_elm' );

# NOTE these may break if the perl internal message changes
like dies { $rng->rand_elm }, qr/Usage:/;
like dies { $rng->rand_elm(undef) }, qr/avref is not/;
like dies { $rng->rand_idx }, qr/Usage:/;
like dies { $rng->rand_idx(undef) }, qr/avref is not/;

#is($rng->rand_elm(undef), undef, 'rand_elm no arg');

is( sprintf( "%.2f", $rng->rand ),       '0.90',   'rand' );
is( sprintf( "%.2f", $rng->rand(1000) ), '973.52', 'rand x1000' );

#   % perl -e 'printf "%064b\n", 3664671147774981625' | fold -w 32
#   00110010110110111000011011111110
#   00011101110000000011010111111001
# so depending on what goes wrong the result might be 499135993 or less
# likely 853247742, possibly due to use64bitint=undef being set
is( $rng->irand64, 3664671147774981625, 'irand64' );

# floating point should be converted to int via truncate; if not, test
# should fail as 4..6 is different than 4..5
is( [ map $rng->irand_in( 4, 11.999 / 2 ), 1 .. 7 ],
    [ 4, 5, 5, 5, 4, 5, 4 ], 'irand_in' );

is( $rng->irand_way( 42, 640, 42, 640 ), undef, 'irand_way same point' );
# forced X and Y axis moves
is( [ $rng->irand_way( 0, 0, int( 1 + rand 100 ), 0 ) ], [ 1, 0 ] );
is( [ $rng->irand_way( 0, 0, 0, int( 1 + rand 100 ) ) ], [ 0, 1 ] );
# negative should do the same, only negative
is( [ $rng->irand_way( 0, 0, -int( 1 + rand 100 ), 0 ) ], [ -1, 0 ] );
is( [ $rng->irand_way( 0, 0, 0, -int( 1 + rand 100 ) ) ], [ 0,  -1 ] );

my @path;
my ( $x, $y ) = ( 0, 0 );
while (1) {
    ( $x, $y ) = $rng->irand_way( $x, $y, 5, 5 );
    last unless defined $x;
    push @path, [ $x, $y ];
}
is( \@path,
    [   [ 1, 0 ], [ 2, 0 ], [ 2, 1 ], [ 2, 2 ], [ 2, 3 ], [ 3, 3 ],
        [ 4, 3 ], [ 4, 4 ], [ 5, 4 ], [ 5, 5 ]
    ],
    'irand_way path positive'
);

@path = ();
( $x, $y ) = ( 3, 3 );
while (1) {
    ( $x, $y ) = $rng->irand_way( $x, $y, 0, 0 );
    last unless defined $x;
    push @path, [ $x, $y ];
}
is( \@path,
    [ [ 2, 3 ], [ 1, 3 ], [ 1, 2 ], [ 1, 1 ], [ 0, 1 ], [ 0, 0 ] ],
    'irand_way path negative'
);

is( [ map $rng->roll( 3, 6 ), 1 .. 6 ], [ 11, 10, 8, 12, 12, 11 ], 'roll' );

is( $rng->decay( 0,         1, 10 ), 10, 'decay min odds' );
is( $rng->decay( 2**32,     1, 1 ),  1,  'decay max odds' );
is( $rng->decay( 2**32 / 2, 1, 10 ), 3,  'decay 50% odds' );

# runs are probably why some games use Pseudo Random Distribution (PRD)
# or rubber band odds (Brogue) to reduce the influence of luck
is( [ map $rng->coinflip, 1 .. 6 ], [ 0, 0, 0, 0, 0, 0 ], 'coinflip' );

# rand_from
{
    my @gismu = qw(cribe finpe gerku mlatu ratcu);

    is( $rng->rand_from( \@gismu ), 'cribe',    'rand_from' );
    is( \@gismu, [qw(finpe gerku mlatu ratcu)], 'original mutated' );

    is( $rng->rand_from( \@gismu ), 'mlatu', 'rand_from II' );
    is( \@gismu, [qw(finpe gerku ratcu)],    'original mutated II' );

    is( $rng->rand_from( \@gismu ), 'ratcu',           'rand_from III' );
    is( \@gismu,                    [qw(finpe gerku)], 'original mutated III' );

    is( $rng->rand_from( \@gismu ), 'gerku',     'rand_from IV' );
    is( \@gismu,                    [qw(finpe)], 'original mutated IV' );

    is( $rng->rand_from( \@gismu ), 'finpe', 'rand_from V' );
    is( \@gismu,                    [],      'original mutated V' );

    is( $rng->rand_from( \@gismu ), undef, 'rand_from VI' );
    is( \@gismu,                    [],    'original mutated VI' );
}

# sample
{
    my @items = qw(Rock Paper Scissors Shotgun Orbitalnukes);
    is( $rng->sample( 3, \@items ), [qw/Rock Shotgun Orbitalnukes/] );

    is( $rng->sample( 99, \@items ),
        [qw(Rock Paper Scissors Shotgun Orbitalnukes)] );

    # edge cases (array ref always returned to avoid if defined ... and ...)
    is( $rng->sample( 0,  \@items ), [] );
    is( $rng->sample( 99, [] ),      [] );

    # no modification of the original
    is( \@items, [qw(Rock Paper Scissors Shotgun Orbitalnukes)] );
}

done_testing 41
