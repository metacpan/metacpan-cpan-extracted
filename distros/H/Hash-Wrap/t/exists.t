#! perl

use Test2::V0;

use Scalar::Util 'blessed';

use Hash::Wrap ( {
        -as     => 'wrap_as_exists',
        -exists => 1
    },
    {
        -as     => 'wrap_as_foo',
        -exists => 'foo'
    },
);


my %hash = ( a => 1, b => 2, c => [9] );

subtest "default" => sub {
    my $obj = wrap_as_exists \%hash;

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );
    is( $obj->c, [9], 'retrieve another value' );

    ok( $obj->exists( 'a' ),  "a exists" );
    ok( !$obj->exists( 'd' ), "d does not exist" );
    ok( ! exists $hash{d}, "exists doesn't autovivify" );
};

subtest "rename" => sub {
    my $obj = wrap_as_foo \%hash;

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );
    is( $obj->c, [9], 'retrieve another value' );

    ok( $obj->foo( 'a' ),  "a exists" );
    ok( !$obj->foo( 'd' ), "d does not exist" );
};

done_testing;
