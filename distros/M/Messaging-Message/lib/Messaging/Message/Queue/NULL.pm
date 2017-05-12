#+##############################################################################
#                                                                              #
# File: Messaging/Message/Queue/NULL.pm                                        #
#                                                                              #
# Description: abstraction of a null message queue                             #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Messaging::Message::Queue::NULL;
use strict;
use warnings;
our $VERSION  = "1.6.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

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
    return("");
}

sub next : method { ## no critic 'ProhibitBuiltinHomonyms'
    return("");
}

sub count : method {
    return(0);
}

sub purge : method {
}

sub path : method {
    return("NULL");
}

sub id : method {
    return("NULL");
}

sub add : method {
    return("");
}

#
# Directory::Queue methods that cannot be used
#

sub touch : method {
    dief("unsupported method: touch()");
}

sub lock : method { ## no critic 'ProhibitBuiltinHomonyms'
    dief("unsupported method: lock()");
}

sub unlock : method {
    dief("unsupported method: unlock()");
}

sub remove : method {
    dief("unsupported method: remove()");
}

sub add_ref : method {
    dief("unsupported method: add_ref()");
}

sub add_path : method {
    dief("unsupported method: add_path()");
}

sub get : method {
    dief("unsupported method: get()");
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
    return("null");
}

#
# get a message object from the queue
#

sub get_message : method {
    dief("unsupported method: get_message()");
}

1;

__DATA__

=head1 NAME

Messaging::Message::Queue::NULL - abstraction of a null message queue

=head1 SYNOPSIS

  use Messaging::Message;
  use Messaging::Message::Queue::NULL;

  # create a message queue
  $mq = Messaging::Message::Queue::NULL->new();

  # add a message to the queue
  $msg = Messaging::Message->new(body => "hello world");
  $mq->add_message($msg);

=head1 DESCRIPTION

This module provides an abstraction of a message queue working a bit like
C</dev/null>: it can be written to but it always appears empty.

=head1 METHODS

In addition to the standard L<Directory::Queue> methods, the following methods
are available:

=over

=item new(OPTIONS)

return a new Messaging::Message::Queue::NULL object (class method)

=item add_message(MESSAGE)

add the given message (a Messaging::Message object) to the queue,
this does nothing

=item get_message(ELEMENT)

get the message from the given element, this generates an error

=back

=head1 SEE ALSO

L<Directory::Queue>,
L<Messaging::Message>,
L<Messaging::Message::Queue>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2016
