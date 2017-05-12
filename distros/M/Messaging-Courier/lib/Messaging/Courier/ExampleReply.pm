package Messaging::Courier::ExampleReply;

use strict;
use warnings;

use XML::LibXML;
use Messaging::Courier::Message;
use base qw( Messaging::Courier::Message );

sub token {
  my $self = shift;
  if (@_) {
    $self->{ token } = shift;
    return $self;
  }
  return $self->{ token };
}

sub serialize {
  my $self = shift;

  $self->addNode( 'token', contents => $self->token || '' );
}

1;
