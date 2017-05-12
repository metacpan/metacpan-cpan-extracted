#+##############################################################################
#                                                                              #
# File: Messaging/Message/Queue/ZERO.pm                                        #
#                                                                              #
# Description: abstraction of a message queue returning empty messages         #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Messaging::Message::Queue::ZERO;
use strict;
use warnings;
our $VERSION  = "1.6.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

#
# inheritance
#

our @ISA = qw(Messaging::Message::Queue);

#
# used modules
#

use No::Worries::Die qw(dief);
use Params::Validate qw(validate_with);

#
# constructor
#

sub new : method {
    my($class, %option, $self);

    $class = shift(@_);
    %option = validate_with(
        params      => \@_,
        spec        => {},
        allow_extra => 0,
    );
    $self = {};
    bless($self, $class);
    return($self);
}

#
# Directory::Queue methods that can be used
#

sub first : method {
    return("first");
}

sub next : method { ## no critic 'ProhibitBuiltinHomonyms'
    return("next");
}

sub count : method {
    return(1);
}

sub purge : method {
}

sub path : method {
    return("ZERO");
}

sub id : method {
    return("ZERO");
}

sub touch : method {
}

sub lock : method { ## no critic 'ProhibitBuiltinHomonyms'
    return(1);
}

sub unlock : method {
    return(1);
}

sub remove : method {
}

sub get : method {
    return("");
}

#
# Directory::Queue methods that cannot be used
#

sub add : method {
    dief("unsupported method: add()");
}

sub add_ref : method {
    dief("unsupported method: add_ref()");
}

sub add_path : method {
    dief("unsupported method: add_path()");
}

sub get_ref : method {
    dief("unsupported method: get_ref()");
}

sub get_path : method {
    dief("unsupported method: get_path()");
}

sub copy : method {
    dief("unsupported method: copy()");
}

#
# add a message object to the queue
#

sub add_message : method {
    dief("unsupported method: add_message()");
}

#
# get a message object from the queue
#

sub get_message : method {
    return(Messaging::Message->new());
}

1;

__DATA__

=head1 NAME

Messaging::Message::Queue::ZERO - abstraction of a message queue returning empty messages

=head1 SYNOPSIS

  use Messaging::Message;
  use Messaging::Message::Queue::ZERO;

  # create a message queue
  $mq = Messaging::Message::Queue::ZERO->new();

  # get a message to the queue
  $msg = $mq->get_message("");

=head1 DESCRIPTION

This module provides an abstraction of a message queue working a bit like
C</dev/zero>: it cannot be written to and, when read, it generates an infinite
sequence of empty messages.

=head1 METHODS

In addition to the standard L<Directory::Queue> methods, the following methods
are available:

=over

=item new(OPTIONS)

return a new Messaging::Message::Queue::ZERO object (class method)

=item add_message(MESSAGE)

add the given message (a Messaging::Message object) to the queue,
this generates an error

=item get_message(ELEMENT)

get the message from the given element, this returns an empty message

=back

=head1 SEE ALSO

L<Directory::Queue>,
L<Messaging::Message>,
L<Messaging::Message::Queue>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2016
