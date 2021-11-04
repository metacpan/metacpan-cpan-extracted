#+##############################################################################
#                                                                              #
# File: Messaging/Message/Queue.pm                                             #
#                                                                              #
# Description: abstraction of a message queue                                  #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Messaging::Message::Queue;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Messaging::Message qw(_require);
use Params::Validate qw(validate_with :types);

#
# constructor
#

sub new : method {
    my($class, %option, $mqc);

    $class = shift(@_);
    %option = validate_with(
        params      => \@_,
        spec        => {
            type => { type => SCALAR, regex => qr/^[a-zA-Z0-9]+$/ },
        },
        allow_extra => 1,
    );
    $mqc = $class . "::" . $option{type};
    _require($mqc);
    delete($option{type});
    return($mqc->new(\%option));
}

1;

__DATA__

=head1 NAME

Messaging::Message::Queue - abstraction of a message queue

=head1 SYNOPSIS

  use Messaging::Message::Queue;

  $mq = Messaging::Message::Queue->new(type => Foo, ... options ...);
  # is identical too
  $mq = Messaging::Message::Queue::Foo->new(... options ...);

=head1 DESCRIPTION

This module provides an abstraction of a message queue. Its only
purpose is to offer a unified method to create a new queue. The
functionality is implemented in child modules such as
L<Messaging::Message::Queue::DQN>.

The only available method is:

=over

=item new(OPTIONS)

create a new message queue object; OPTIONS must contain the type of
queue (which is the name of the child class), see above

=back

=head1 SEE ALSO

L<Messaging::Message>,
L<Messaging::Message::Queue::DQN>,
L<Messaging::Message::Queue::DQS>,
L<Messaging::Message::Queue::NULL>,
L<Messaging::Message::Queue::ZERO>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2021
