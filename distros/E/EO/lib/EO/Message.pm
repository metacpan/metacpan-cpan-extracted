package EO::Message;

use strict;
use warnings;

use EO;
use EO::Array;
use base qw( EO );

our $VERSION = 0.96;

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->arguments( EO::Array->new );
    return 1;
  }
  return 0;
}

sub selector {
  my $self = shift;
  if (@_) {
    $self->{ selector } = shift;
    return $self;
  }
  return $self->{ selector };
}

sub arguments {
  my $self = shift;
  if (@_) {
    $self->{ arguments } = shift;
    return $self;
  }
  return $self->{ arguments };
}

sub send_to {
  my $self = shift;
  my $receiver = shift;
  my $meth = $self->selector;
  $receiver->$meth( @{ $self->arguments } );
}

1;

__END__

=head1 NAME

EO::Message - definition of a message class

=head1 SYNOPSIS

  use EO::Message;

  my $message = EO::Message->new();
  $message->selector( 'foo' );
  $message->arguments( [qw(one two three)] );

  $message->send_to( $object );
  $message->send_to( 'Class' );

  my $selector  = $message->selector;
  my $arguments = $message->arguments;

=head1 DESCRIPTION

C<EO::Message> provides a representation of a message sent to an object in
the system.

=cut

