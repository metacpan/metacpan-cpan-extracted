package checkudata;

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

    $L->checkudata( 1, 'mymeta' );
}

sub test_ok : Test( 1 ) {

    my $L = shift->{L};

    $L->newuserdata( 1 );
    my $pos = $L->gettop;
    $L->newmetatable( 'mymeta' );
    $L->setmetatable( $pos );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, 0, md 'return' );
}

sub test_nok : Test( 3 ) {

    my $L = shift->{L};

    $L->newuserdata( 1 );
    my $pos = $L->gettop;
    $L->newmetatable( 'notmeta' );
    $L->setmetatable( $pos );
    my $ret = $L->pcall( 1, 0, 0 );
    is( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1/i, md 'message' );
    $L->pop(1);
}




1;
