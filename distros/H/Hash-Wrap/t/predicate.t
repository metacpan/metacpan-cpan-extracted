#! perl

## no critic

use Test2::V0;

use Scalar::Util 'blessed';

use Hash::Wrap ( {
        -predicate => 1
    },
);


my $obj = wrap_hash { ( a => 1, b => 2, c => [9] ) };

is( $obj->has_a, T(), 'has a' );
is( $obj->has_b, T(), 'has b' );
is( $obj->has_c, T(), 'has c' );

is( $obj->has_d, F(), "doesn't have d" );


done_testing;
