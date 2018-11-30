package Lemonldap::NG::Portal::UserDB::Custom;

use strict;

sub new {
    my ( $class, $self ) = @_;
    unless ( $self->{conf}->{customUserDB} ) {
        die 'Custom User DB module not defined';
    }

    eval $self->{p}->loadModule( $self->{conf}->{customUserDB} );
    ($@)
      ? return $self->{p}->loadModule( $self->{conf}->{customUserDB} )
      : die 'Unable to load UserDB module ' . $self->{conf}->{customUserDB};
}

1;
