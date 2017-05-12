package EO::System;

use strict;
use warnings;

use IO::Handle;
use EO::Singleton;
use EO::System::OS;
use EO::System::Perl;
use base qw( EO::Singleton );

our $VERSION = 0.96;

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->{out}   = \*STDOUT;
    $self->{in}    = \*STDIN;
    $self->{error} = \*STDERR;
    return 1;
  }
  return 0;
}

sub out {
  my $self = shift;
  $self = __PACKAGE__->new();
  if (@_) {
    $self->{ out } = shift;
    return $self;
  }
  return $self->{ out };
}

sub in {
  my $self = shift;
  $self = __PACKAGE__->new();
  if (@_) {
    $self->{ in } = shift;
    return $self;
  }
  return $self->{ in };
}

sub error {
  my $self = shift;
  $self = __PACKAGE__->new();
  if (@_) {
    $self->{ error } = shift;
    return $self;
  }
  return $self->{ error };
}


sub perl {
  return EO::System::Perl->new();
}

sub os {
  return EO::System::OS->new();
}

1;
