package optlstring;

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

    my $exp = $L->tostring(1);
    my $def = $L->tostring(2);
    my $value = $L->optlstring( 3, $def, my $len );

    is( $value, $exp, md( 3, 'passed value' ) );
    is( $len, length($exp), md( 3, 'length' ) );
}


sub test_ok : Test( 3 ) {

    my $L = shift->{L};

    $L->pushstring( 'bar' );
    $L->pushstring( 'foo' );
    $L->pushstring( 'bar' );

    my $ret = $L->pcall( 3, 0, 0 );
    is( $ret, 0, md 'return' );
}

sub test_nil : Test( 3 ) {

    my $L = shift->{L};

    $L->pushstring( 'foo' );
    $L->pushstring( 'foo' );
    $L->pushnil;
    my $ret = $L->pcall( 3, 0, 0 );
    is( $ret, 0, md 'return' );
}

sub test_nok : Test( 3 ) {

    my $L = shift->{L};

    $L->pushstring( 'foo' );
    $L->pushstring( 'foo' );
    $L->pushlightuserdata( {} );
    my $ret = $L->pcall( 3, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #3/i, md 'message' );
    $L->pop(1);
}


1;
