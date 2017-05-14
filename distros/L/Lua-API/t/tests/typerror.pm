package typerror;

use strict;
use warnings;

use Test::More;

use LuaTest;
use base qw[ LuaTest ];
use Lua::API;

sub testfunc {

    shift()->typerror( 1, 'boo' );

}

sub test_typerror : Test( 3 ) {

    my $L = shift->{L};
    my $ret = $L->pcall( 0, 0, 0 );
    is ( $ret, Lua::API::ERRRUN, md 'return' );
    is( $L->gettop, 1, md 'stack' );
    like( $L->tostring(-1), qr/bad argument #1/i, md 'message' );
    $L->pop(1);
}

1;
