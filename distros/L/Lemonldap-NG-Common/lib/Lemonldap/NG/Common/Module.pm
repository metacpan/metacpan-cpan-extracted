package Lemonldap::NG::Common::Module;

use strict;
use Mouse;

our $VERSION = '2.0.0';

# Object that provides loggers and error methods (typically PSGI object)
has p => ( is => 'rw', weak_ref => 1 );

# Lemonldap::NG configuration hash ref
has conf => ( is => 'rw', weak_ref => 1 );

has logger => ( is => 'rw', lazy => 1, default => sub { $_[0]->{p}->logger } );
has userLogger =>
  ( is => 'rw', lazy => 1, default => sub { $_[0]->{p}->userLogger } );

sub error {
    my $self = shift;
    return $self->p->error(@_);
}

1;
