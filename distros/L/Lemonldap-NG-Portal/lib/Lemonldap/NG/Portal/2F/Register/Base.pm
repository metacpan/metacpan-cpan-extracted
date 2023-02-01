# Base package for 2F Register modules
package Lemonldap::NG::Portal::2F::Register::Base;

use strict;
use Mouse;

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has logo          => ( is => 'rw', default => '2f.png' );
has label         => ( is => 'rw' );
has authnLevel    => ( is => 'rw' );
has userCanRemove => ( is => 'rw' );

# 'type' field of stored _2fDevices
# Defaults to the last component of the package name
# But can be overriden by sfExtra
has type => (
    is      => 'rw',
    default => sub {
        ( split( '::', ref( $_[0] ) ) )[-1];
    }
);

sub init {
    my ($self) = @_;

    # Set logo if overridden
    $self->logo( $self->conf->{ $self->prefix . "2fLogo" } )
      if $self->conf->{ $self->prefix . "2fLogo" };

    # Set label if provided, translation files will be used otherwise
    $self->label( $self->conf->{ $self->prefix . "2fLabel" } )
      if $self->conf->{ $self->prefix . "2fLabel" };

    $self->authnLevel( $self->conf->{ $self->prefix . "2fAuthnLevel" } )
      if $self->conf->{ $self->prefix . "2fAuthnLevel" };

    # Set whether the user can remove this registration
    $self->userCanRemove(
        $self->conf->{ $self->prefix . '2fUserCanRemoveKey' } )
      if $self->conf->{ $self->prefix . '2fUserCanRemoveKey' };

    return 1;
}

# Legacy
sub canUpdateSfa {
    my ( $self, $req ) = @_;
    $self->logger->warn(
            ref($self)
          . "::canUpdateSfa is deprecated,"
          . " this check is now performed by the 2F Engine,"
          . " you can remove it from your custom module" );

    return;
}

# Check characters and truncate SFA name if too long
sub checkNameSfa {
    my ( $self, $req, $type, $name ) = @_;

    $name ||= "My$type";
    unless ( $name =~ /^[\w\s-]+$/ ) {
        $self->userLogger->error("$type name with bad character(s)");
        return;
    }
    $name = substr( $name, 0, $self->conf->{max2FDevicesNameLength} );
    $self->logger->debug("Return $type name: $name");

    return $name;
}

1;
