#! perl


##############

# These tests are incomplete; still need to check pushcfunction,
# pushcclosure, and hooks

##############

use Test::Most;

use Lua::API;

my $L = Lua::API::State->open;

sub throw_error {

    my $L = shift;

    $L->error( 'error' );

}

{
    my $ret = $L->cpcall( \&throw_error, {} );

    bail_on_fail;
    is ( $ret, Lua::API::ERRRUN, 'error: return with ERRRUN' );
    is( $L->gettop, 1, 'error: stack ok' );
    is( $L->tostring(-1), 'main::throw_error: error', 'error: message' );
    $L->pop(1);
}

sub throw_die {

    my $L = shift;

    die( "die" );
}

{
    my $ret = $L->cpcall( \&throw_die, {} );

    bail_on_fail;
    is ( $ret, Lua::API::ERRRUN, 'die: return with ERRRUN' );
    is( $L->gettop, 1, 'die: stack ok' );
    like( $L->tostring(-1), qr{die at t/error.t}, 'die: message' );
}


done_testing();
