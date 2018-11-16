#! perl

use Test2::V0;

use IPC::PrettyPipe::Arg;

sub new { IPC::PrettyPipe::Arg->new( @_ ); }


try_ok {
    my $arg = new(
        name  => 'a',
        value => '%OUTPUT%',
    );
    is( $arg->valmatch( qr/%OUTPUT%/ ), 1, 'match' );
};

try_ok {
    my $arg = new(
        name  => 'a',
        value => '%OUTPUT%',
    );
    is( $arg->valmatch( qr/%INPUT%/ ), '', 'valmatch: value, not matched' );
};


try_ok {
    my $arg = new( name => 'a', );
    is( $arg->valmatch( qr/%INPUT%/ ), '', 'valmatch: no value' );
};

try_ok {
    my $arg = new(
        name  => 'a',
        value => '%OUTPUT%bar',
    );
    $arg->valsubst( qr/%OUTPUT%/, 'foo' );
    is( $arg->value, 'foobar', 'valsubst: value match' );
};


try_ok {
    my $arg = new( name => 'a', );

    is( $arg->valsubst( qr/%OUTPUT%/, 'foo' ), 0, 'valsubst: no value' );
};


try_ok {
    my $arg = new(
        name  => 'a',
        value => '%OUTPUT%bar',
    );
    $arg->valsubst( qr/%INPUT%/, 'foo' );
    is( $arg->value, '%OUTPUT%bar', 'valsubst not match' );
};



done_testing;
