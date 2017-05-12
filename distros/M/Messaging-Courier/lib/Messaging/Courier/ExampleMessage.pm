package Messaging::Courier::ExampleMessage;

use strict;
use warnings;

use XML::LibXML;
use Messaging::Courier::Message;
use Messaging::Courier::ExampleReply;
use base qw( Messaging::Courier::Message );

sub username {
  my $self = shift;
  if (@_) {
    $self->{ username } = shift;
    return $self;
  }
  return $self->{ username };
}

sub password {
  my $self = shift;
  if (@_) {
    $self->{ password } = shift;
    return $self;
  }
  return $self->{ password };
}

sub serialize {
  my $self = shift;

  $self->addNode( 'username', contents => $self->username);
  $self->addNode( 'password', contents => $self->password);
}

sub reply_class {
  return 'Messaging::Courier::ExampleReply';
}

1;
