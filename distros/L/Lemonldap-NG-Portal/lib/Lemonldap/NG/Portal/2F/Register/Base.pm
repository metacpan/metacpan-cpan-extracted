# Base package for 2F Register modules
package Lemonldap::NG::Portal::2F::Register::Base;

use strict;
use Mouse;

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has logo  => ( is => 'rw', default => '2f.png' );
has label => ( is => 'rw' );

sub init {
    my ($self) = @_;

    # Set logo if overridden
    $self->logo( $self->conf->{ $self->prefix . "2fLogo" } )
      if ( $self->conf->{ $self->prefix . "2fLogo" } );

    # Set label if provided, translation files will be used otherwise
    $self->label( $self->conf->{ $self->prefix . "2fLabel" } )
      if ( $self->conf->{ $self->prefix . "2fLabel" } );

    return 1;
}

1;
