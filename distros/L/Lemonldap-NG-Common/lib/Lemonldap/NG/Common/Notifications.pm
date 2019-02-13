package Lemonldap::NG::Common::Notifications;

use strict;
use Mouse;

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Common::Module';

sub import {
    if ( $_[1] eq 'XML' ) {
        extends 'Lemonldap::NG::Common::Notifications::XML',
          'Lemonldap::NG::Common::Module';
    }
    else {
        extends 'Lemonldap::NG::Common::Notifications::JSON',
          'Lemonldap::NG::Common::Module';
    }
}

has notifField => (
    is      => 'rw',
    builder => sub {
        my $uid =
             $_[0]->conf->{notificationField}
          || $_[0]->conf->{whatToTrace}
          || 'uid';
        $uid =~ s/^\$//;
        return $uid;
    }
);

sub getNotifications {
    my ( $self, $uid ) = @_;
    my $forUser = $self->get($uid);
    my $forAll  = $self->get( $self->conf->{notificationWildcard} );
    if ( $forUser and $forAll ) {
        return { %$forUser, %$forAll };
    }
    else {
        return ( ( $forUser ? $forUser : $forAll ), $forUser );
    }
}

1;
