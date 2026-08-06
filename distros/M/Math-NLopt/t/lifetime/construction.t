#! perl

use v5.12;
use Test2::V0;
use Test2::Tools::AsyncSubtest 'fork_subtest';
use Scalar::Util 'weaken';

use Math::NLopt qw( NLOPT_LD_MMA NLOPT_NUM_ALGORITHMS );

subtest 'constructed objects are released' => sub {
    my $object = Math::NLopt->new( NLOPT_LD_MMA, 2 );
    my $weak   = $object;

    weaken( $weak );
    undef $object;

    ok( !defined $weak, 'constructor releases its object' );
};

done_testing;
