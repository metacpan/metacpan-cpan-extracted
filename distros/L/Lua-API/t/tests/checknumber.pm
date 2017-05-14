package checknumber;

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

    my $n = $L->checknumber( 1 );

    is( $n, 44.5, md( 3, 'passed value' ) );
}


sub test_lud : Test( 3 ) {

    my $L = shift->{L};

    $L->pushlightuserdata( {} );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1/i, md 'message' );
    $L->pop(1);
}

sub test_string : Test( 2 ) {

    my $L = shift->{L};

    $L->pushstring( '44.5' );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, 0, md 'return' );
}

sub test_number : Test( 2 ) {

    my $L = shift->{L};

    $L->pushnumber( 44.5 );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, 0, md 'return' );
}


1;
