package checktype;

use strict;
use warnings;

use lib 't';

use LuaTest;
use base qw[ LuaTest ];

use Lua::API;
use Test::Most;
bail_on_fail;


# no need to test more than a couple of types; just making sure things
# are passed correctly

sub testfunc {

    my $L = shift;

    my $type = $L->tointeger( -1 );
    $L->pop(1);

    $L->checktype( 1, $type );
}

sub test_nil_ok : Test( 1 ) {

    my $L = shift->{L};

    $L->pushnil;
    $L->pushinteger( Lua::API::TNIL );
    my $ret = $L->pcall( 2, 0, 0 );
    is( $ret, 0, md 'return' );
}

sub test_nil_nok : Test( 3 ) {

    my $L = shift->{L};

    $L->pushstring('foo');
    $L->pushinteger( Lua::API::TNIL );
    my $ret = $L->pcall( 2, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1/i, md 'message' );
    $L->pop(1);
}

sub test_number_ok : Test( 1 ) {

    my $L = shift->{L};

    $L->pushnumber(3);
    $L->pushinteger( Lua::API::TNUMBER );
    my $ret = $L->pcall( 2, 0, 0 );
    is( $ret, 0, md 'return' );
}

sub test_number_nok : Test( 3 ) {

    my $L = shift->{L};

    $L->pushstring('foo');
    $L->pushinteger( Lua::API::TNUMBER );
    my $ret = $L->pcall( 2, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1/i, md 'message' );
    $L->pop(1);
}



1;
