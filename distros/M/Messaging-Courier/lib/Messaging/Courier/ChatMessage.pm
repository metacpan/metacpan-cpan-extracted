package Messaging::Courier::ChatMessage;

use strict;
use warnings;

use Messaging::Courier::TextMessage;
use base qw( Messaging::Courier::TextMessage );

sub init {
  my $self = shift;
  $self->nick($ENV{USER});
  $self->SUPER::init(@_);
}

sub nick {
  my $self = shift;
  if (@_) {
    $self->{ nick } = shift;
    return $self;
  }
  return $self->{ nick };
}

sub serialize {
  my $self = shift;

  $self->addNode( 'nick', contents => $self->nick || '?' );
  $self->SUPER::serialize();
}

1;
