package LuaTest;

use strict;
use warnings;

use base qw[ Exporter Test::Class ];

our @EXPORT = qw[ md ];

use Lua::API;

use Test::Most;

use Scalar::Util;

INIT { bail_on_fail;
       Test::Class->runtests;
}

sub md {
    my $stack = @_ > 1 ? shift( @_ ) : 1;
    my ( $func ) = (caller($stack))[3];

    $func =~ s/:test_/ /;
    $func =~ s/_/ /g;

    "$func: " . $_[0];
}

sub register : Test(startup) {

    my $t = shift;
    my $class = Scalar::Util::blessed($t);
    $t->{testfunc} = \&{"${class}::testfunc"};

}
sub setup_interpreter : Test( setup ) {

    my $t = shift;
    my $L = Lua::API::State->open;

    $L->register( 'testfunc', $t->{testfunc} );
    $L->getfield( Lua::API::GLOBALSINDEX, 'testfunc' );

    $t->{L} = $L;
}

sub check_stack : Test( teardown => 1 ) {

    is( shift->{L}->gettop, 0, md 'stack' );
}


1;
