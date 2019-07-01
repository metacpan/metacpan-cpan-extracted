package Lemonldap::NG::Portal::Register::Custom;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Register::Base';

sub new {
    my ( $class, $self ) = @_;
    unless ( $self->{conf}->{customRegister} ) {
        die 'Custom register module not defined';
    }

    my $res = $self->{p}->loadModule( $self->{conf}->{customRegister} );
    unless ($res) {
        die 'Unable to load register module ' . $self->{conf}->{customRegister};
    }
    return $res;
}

1;
