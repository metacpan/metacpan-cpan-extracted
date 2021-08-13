#! perl

use Test2::V0;

use Scalar::Util 'blessed';

use Hash::Wrap ( {
        -predicate => 1
    },
);


my %hash = ( a => 1, b => 2, c => [9] );

my $obj = wrap_hash \%hash;

is( $obj->a, 1, 'retrieve value' );
is( $obj->b, 2, 'retrieve another value' );
is( $obj->c, [9], 'retrieve another value' );

ok( $obj->has_a,      "a exists" );
ok( !$obj->has_d,     "d does not exist" );
ok( !exists $hash{d}, "exists doesn't autovivify" );

done_testing;
