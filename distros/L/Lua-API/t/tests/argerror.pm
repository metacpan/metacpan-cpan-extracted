package argerror;

use strict;
use warnings;


use LuaTest;
use base qw[ LuaTest ];

use Lua::API;

use Test::More;

sub testfunc {

    shift->argerror( 1, "extra message" );
}

sub test_argerror : Test( 3 ) {

    my $L = shift->{L};

    my $ret = $L->pcall( 0, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1(.*)extra message/i, md 'message' );
    $L->pop(1);
}

1;
