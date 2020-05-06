package Lemonldap::NG::Common::Notifications;

use strict;
use Mouse;
use JSON qw(to_json);

our $VERSION = '2.0.8';

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

has extension => (
    is      => 'rw',
    default => 'json'
);

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

sub BUILD {
    my $self = shift;
    $self->extension('xml') if $self->conf->{oldNotifFormat};
    $self->logger->debug( 'Use extension "'
          . $self->extension
          . '" to store notification files' );
}

sub getNotifications {
    my ( $self, $uid ) = @_;
    my $forAll = $self->get( $self->conf->{notificationWildcard} );
    if ( $uid and $uid =~ /^_all(Pending|Existing)_$/ ) {
        $self->logger->info("Retrieve all $1 notifications");
        my $all = ( $1 eq 'Pending' ? $self->getAll() : $self->getExisting() );
        $all = { map { $_ => to_json( $all->{$_} ) } keys %$all };
        return ( $forAll ? { %$all, %$forAll } : $all );
    }
    my $forUser = $self->get($uid);
    if ( $forUser and $forAll ) {
        return { %$forUser, %$forAll };
    }
    else {
        return ( ( $forUser ? $forUser : $forAll ), $forUser );
    }
}

sub getAcceptedNotifs {
    my ( $self, $uid, $ref ) = @_;
    my $forAll =
      $self->getAccepted( $self->conf->{notificationWildcard}, $ref );
    my $forUser = $self->getAccepted( $uid, $ref );
    if ( $forUser and $forAll ) {
        return { %$forUser, %$forAll };
    }
    else {
        return ( ( $forUser ? $forUser : $forAll ), $forUser );
    }
}

1;
