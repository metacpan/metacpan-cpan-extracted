#+##############################################################################
#                                                                              #
# File: Messaging/Message/Queue/DQS.pm                                         #
#                                                                              #
# Description: abstraction of a Directory::Queue::Simple message queue         #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Messaging::Message::Queue::DQS;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

#
# inheritance
#

our @ISA = qw(Messaging::Message::Queue Directory::Queue::Simple);

#
# used modules
#

use Messaging::Message qw(_require);
use Params::Validate qw(validate_with validate_pos :types);

#
# constructor
#

sub new : method {
    my($class, %option, $compression, $self);

    _require("Directory::Queue::Simple");
    $class = shift(@_);
    %option = validate_with(
        params      => \@_,
        spec        => { compression => { type => SCALAR, optional => 1 } },
        allow_extra => 1,
    );
    $compression = delete($option{compression});
    if ($compression) {
        # check that this compression is indeed available...
        Messaging::Message->new()->jsonify(compression => $compression);
    }
    $self = Directory::Queue::Simple->new(%option);
    if ($compression) {
        # extend the object the dirty way...
        $self->{compression} = $compression;
    }
    bless($self, $class);
    return($self);
}

#
# add a message object to the queue
#

sub add_message : method {
    my($self, $msg, %opt);

    $self = shift(@_);
    validate_pos(@_, { isa => "Messaging::Message" });
    $msg = shift(@_);
    %opt = (compression => $self->{compression}) if $self->{compression};
    return($self->add_ref($msg->serialize_ref(%opt)));
}

#
# get a message object from the queue
#

sub get_message : method {
    my($self, $elt);

    $self = shift(@_);
    validate_pos(@_, { type => SCALAR });
    $elt = shift(@_);
    return(Messaging::Message->deserialize_ref($self->get_ref($elt)));
}

1;

__DATA__

=head1 NAME

Messaging::Message::Queue::DQS - abstraction of a Directory::Queue::Simple message queue

=head1 SYNOPSIS

  use Messaging::Message;
  use Messaging::Message::Queue::DQS;

  # create a message queue
  $mq = Messaging::Message::Queue::DQS->new(path => "/some/where");

  # add a message to the queue
  $msg = Messaging::Message->new(body => "hello world");
  printf("msg added as %s\n", $mq->add_message($msg));

  # browse the queue
  for ($name = $mq->first(); $name; $name = $mq->next()) {
      next unless $mq->lock($name);
      $msg = $mq->get_message($name);
      # one could use $mq->unlock($name) to only browse the queue...
      $mq->remove($name);
  }

=head1 DESCRIPTION

This module provides an abstraction of a message queue. It derives
from the L<Directory::Queue::Simple> module that provides a generic
directory based queue.

It simply stores the serialized message (with optional compression) as
a Directory::Queue::Simple element.

=head1 METHODS

In addition to the methods inherited from L<Directory::Queue::Simple>,
the following methods are available:

=over

=item new(OPTIONS)

return a new Messaging::Message::Queue::DQS object (class method),
the OPTIONS are the ones for Directory::Queue::Simple->new() with the
addition of C<compression>, like for Messaging::Message->jsonify()

=item add_message(MESSAGE)

add the given message (a Messaging::Message object) to the queue and
return the corresponding element name

=item get_message(ELEMENT)

get the message from the given element (which must be locked) and
return a Messaging::Message object

=back

=head1 SEE ALSO

L<Directory::Queue::Simple>,
L<Messaging::Message>,
L<Messaging::Message::Queue>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2021
