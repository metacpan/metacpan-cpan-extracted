package argcheck;

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
    my $cond = $L->tointeger( -1 ) ;
    $L->pop(1);

    die( "dead" ) if $cond == 2;

    $L->argcheck( $cond, 1, "extra message" );
}


sub test_true : Test( 1 ) {

    my $L = shift->{L};

    $L->pushinteger( 1 );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, 0, md 'return'  );
}

sub test_false : Test( 3 ) {

    my $L = shift->{L};

    $L->pushinteger( 0 );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1(.*)extra message/i, md 'message' );
    $L->pop(1);
}

sub test_die : Test( 3 ) {

    my $L = shift->{L};

    $L->pushinteger( 2 );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/dead/i, md 'message' );
    $L->pop(1);
}

1;
