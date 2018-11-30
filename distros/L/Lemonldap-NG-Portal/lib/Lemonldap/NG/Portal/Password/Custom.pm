package Lemonldap::NG::Portal::Password::Custom;

use strict;

sub new {
    my ( $class, $self ) = @_;
    unless ( $self->{conf}->{customPassword} ) {
        die 'Custom Password module not defined';
    }

    eval $self->{p}->loadModule( $self->{conf}->{customPassword} );
    ($@)
      ? return $self->{p}->loadModule( $self->{conf}->{customPassword} )
      : die 'Unable to load Password module ' . $self->{conf}->{customPassword};
}

1;
