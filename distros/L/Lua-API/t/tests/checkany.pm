package checkany;

use strict;
use warnings;

use lib 't';

use LuaTest;
use base qw[ LuaTest ];

use Lua::API;
use Test::Most;
bail_on_fail;


sub testfunc {

    my $L = shift;

    $L->checkany( 1 );
}


sub test_empty : Test( 3 ) {

    my $L = shift->{L};

    my $ret = $L->pcall( 0, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1/i, md 'message' );
    $L->pop(1);
}

sub test_bool : Test( 2 ) {

    my $L = shift->{L};

    $L->pushboolean( 1 );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, 0, md 'return' );
    is( $L->gettop, 0, md 'stack' );
}

sub test_nil : Test( 2 ) {

    my $L = shift->{L};

    $L->pushnil;
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, 0, md 'return' );
    is( $L->gettop, 0, md 'stack' );
}

1;
