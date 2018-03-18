#! perl

use Test2::V0;

use Scalar::Util 'blessed';

use Hash::Wrap ( {
        -as     => 'wrap_as_defined',
        -defined => 1
    },
    {
        -as     => 'wrap_as_foo',
        -defined => 'foo'
    },
);


my %hash = ( a => 1, b => undef );

subtest "default" => sub {
    my $obj = wrap_as_defined \%hash;

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, undef, 'retrieve another value' );

    ok( $obj->defined( 'a' ),  "a defined" );
    ok( !$obj->defined( 'b' ), "existant undefined is not defined" );
    ok( !$obj->defined( 'd' ), "non-existant is not defined" );
    ok( ! exists $hash{d}, "defined doesn't autovivify" );
};

subtest "rename" => sub {
    my $obj = wrap_as_foo \%hash;

    is( $obj->a, 1, 'retrieve value' );

    ok( $obj->foo( 'a' ),  "a foo" );
    ok( !$obj->foo( 'b' ), "existant unfoo is not foo" );
    ok( !$obj->foo( 'd' ), "non-existant is not foo" );
    ok( ! exists $hash{d}, "foo doesn't autovivify" );
};

done_testing;
