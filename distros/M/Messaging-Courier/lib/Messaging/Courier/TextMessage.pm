package Messaging::Courier::TextMessage;

use strict;
use warnings;

use Messaging::Courier::Message;
use base qw( Messaging::Courier::Message );

sub text {
  my $self = shift;
  if (@_) {
    $self->{ text } = shift;
    return $self;
  }
  return $self->{ text };
}

sub serialize {
  my $self = shift;

  $self->addNode( 'text', contents => $self->text || '' );
}

1;
