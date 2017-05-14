package checkstack;

use strict;
use warnings;

use lib 't';

use LuaTest;
use base qw[ LuaTest ];

use POSIX qw[ INT_MAX ];
use Lua::API;
use Test::Most;
bail_on_fail;


sub testfunc {

    my $L = shift;

    my $len = $L->tointeger(-1);
    $L->checkstack( $len, "bad stack" );
}


sub test_big : Test( 3 ) {

    my $L = shift->{L};

    $L->pushinteger( INT_MAX );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    is( $L->tostring(-1), 'stack overflow (bad stack)', md 'message' );
    $L->pop(1);
}

sub test_small : Test( 1 ) {

    my $L = shift->{L};

    $L->pushinteger( 1 );
    my $ret = $L->pcall( 1, 0, 0 );
    diag( $L->tostring(-1) ) if $ret;
    is( $ret, 0, md 'return' );
}


1;
