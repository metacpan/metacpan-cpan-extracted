package Messaging::Courier;

use strict;
use warnings;

use EO;
use Spread;
use Data::UUID;
use Messaging::Courier::Frame;
use Messaging::Courier::Config;
use Regexp::Common;
use Time::HiRes qw(time);
use base qw( EO Class::Accessor::Chained );
__PACKAGE__->mk_accessors(qw( id mailbox name private_group ));

our $VERSION = '0.42';

our $DEFAULT_PEER = Messaging::Courier::Config->host  || '127.0.0.1';
our $DEFAULT_PORT = Messaging::Courier::Config->port  || '4803';
our $GROUP_NAME   = Messaging::Courier::Config->group || 'courier';

exception Messaging::Courier::Error::CouldNotJoin;
exception Messaging::Courier::Error::CouldNotConnect;

sub init {
  my $self = shift;
  my $args = { @_ };
  if ($self->SUPER::init( @_ )) {

    my $id   = Data::UUID->new->create_str;
    $self->id( $id );

    my $port = $args->{ Port } || $DEFAULT_PORT;
    my $host = $args->{ Peer } || $DEFAULT_PEER;
    my $name = $port . '@' . $host;
    $self->name($name);

    $self->_connect();
    return 1;
  }
  return 0;
}

sub DESTROY {
  my $self = shift;
  $self->disconnect;
}

sub send {
  my($self, $message) = @_;

  if(!UNIVERSAL::isa( $message, 'Messaging::Courier::Message')) {
    throw EO::Error::InvalidParameters
      text => "message should be a Messaging::Courier::Message object, not $message";
  }

  my $frame = $message->frame || Messaging::Courier::Frame->new();
  $message->frame( $frame );
  $frame->content( $message );
  $frame->on_send( $self );

  my $serialized = $frame->serialize;

  Spread::multicast(
		    $self->mailbox,
		    AGREED_MESS,
		    $GROUP_NAME,
		    0,
		    $serialized
		   );
}

sub receive {
  my $self = shift;
  my $timeout = shift || 0;
  my $replying_to = shift;

  if ($timeout && $timeout !~ /^$RE{num}{real}$/) {
    throw EO::Error::InvalidParameters
      text => 'timeout must be a number';
  }

  if ($timeout && $timeout < 0) {
    throw EO::Error::InvalidParameters
      text => 'timeout must be a positive number';
  }

  if ($replying_to && !UNIVERSAL::isa($replying_to,'Messaging::Courier::Message')) {
    throw EO::Error::InvalidParameters
      text => 'replying to should be a Messaging::Courier::Message object';
  }

  if (!$replying_to) {
    $self->_receive_simple($timeout);
  } else {
    $self->_receive_reply($timeout, $replying_to);
  }

}

sub receive_many {
  my $self = shift;
  my $timeout = shift || 0;
  my $replying_to = shift;

  if ($timeout && $timeout !~ /^$RE{num}{real}$/) {
    throw EO::Error::InvalidParameters
      text => 'timeout must be a number';
  }

  if ($timeout && $timeout < 0) {
    throw EO::Error::InvalidParameters
      text => 'timeout must be a positive number';
  }

  if (!UNIVERSAL::isa($replying_to,'Messaging::Courier::Message')) {
    throw EO::Error::InvalidParameters
      text => 'replying to should be a Messaging::Courier::Message object';
  }

  $self->_receive_reply_many($timeout, $replying_to);
}

sub _receive_simple {
  my $self = shift;
  my $timeout = shift || 0;
  my $cf;

  my $then = time;

  while ( 1 ) {
    if ($timeout) {
      my $time_left = $then - time + $timeout;
      return if $timeout && $time_left < 0.001;
    }

    my($service_type, $sender, $groups, $mess_type, $endian, $message);

    if ($timeout <= 0) {
      ($service_type, $sender, $groups, $mess_type, $endian, $message) =
	Spread::receive( $self->mailbox );
    } else {
      ($service_type, $sender, $groups, $mess_type, $endian, $message) =
	Spread::receive( $self->mailbox, $timeout );
    }

    if ( $sender ) {
      eval { $cf = Messaging::Courier::Frame->new_with_frame( $message ) };
      return $cf->content if not $@;
    }
  }
}

sub _receive_reply {
  my $self = shift;
  my $timeout = shift || 0;
  my $replying_to = shift;

  my $then = time;

  while (1) {

    my $message;

    if ($timeout) {
      my $time_left = $then - time + $timeout;
      return if $timeout && $time_left < 0.001;
      $message = $self->_receive_simple($time_left);
    } else {
      $message = $self->_receive_simple;
    }

    next unless $message;

    my $cf = $message->frame;
    if ($replying_to->frame && $replying_to->frame->id eq $cf->in_reply_to) {
      return $message;
    }
  }
}

sub _receive_reply_many {
  my $self = shift;
  my $timeout = shift;
  my $replying_to = shift;

  my $then = time;
  my @replies;

  while (1) {
    my $time_left = $then - time + $timeout;
    return @replies if $timeout && $time_left < 0.001;

    my $message = $self->_receive_simple($time_left);
    next unless $message;

    my $cf = $message->frame;
    if ($replying_to->frame && $replying_to->frame->id eq $cf->in_reply_to) {
      push @replies, $message;
    }
  }
}

sub ask {
  my($self, $message, $timeout) = @_;
  $self->send($message);
  return $self->receive( $timeout || 0, $message );
}

sub ask_many {
  my($self, $message, $timeout) = @_;
  $self->send($message);

  if (not defined $timeout) {
    throw EO::Error::InvalidParameters
      text => 'Need timeout for ask_many';
  }

  return $self->receive_many( $timeout || 0, $message );
}

sub _connect {
  my $self = shift;
  my $id   = $self->id;
  my $name = $self->name;

  my ($mailbox, $priv_group) = Spread::connect({
    spread_name => $name,
    private_name => $id,
    group_membership => 0,
  });

  if (!$mailbox) {
    throw Messaging::Courier::Error::CouldNotConnect
      text => 'could not connect to spread daemon';
  }

  my $count = Spread::join( $mailbox, $GROUP_NAME );

  if ($count != 1) {
    throw Messaging::Courier::Error::CouldNotJoin
      text => 'could not join courier group';
  }

  $self->mailbox( $mailbox );
  $self->private_group( $priv_group );
}

sub disconnect {
  my $self = shift;
  my $mailbox = $self->mailbox;
  Spread::disconnect($mailbox) if defined $mailbox;
}

sub reconnect {
  my $self = shift;
  $self->disconnect;

  # pretend we're a completely different client
  my $id   = Data::UUID->new->create_str;
  $self->id( $id );

  $self->_connect;
}

1;


=head1 NAME

Messaging::Courier - asynchronous and synchronous access to a message queue.

=head1 SYNOPSIS

  use Messaging::Courier;

  my $c = Messaging::Courier->new();

  $m = $c->receive();
  $c->send($m);

  $m = $c->ask($m);

=head1 DESCRIPTION

C<Messaging::Courier> is an interface into a message queue.  It provides
both synchronous and asynchronous access to the queue.

The message queue that Courier currently uses is Spread
(http://www.spread.org/). This must be installed before using and
testing this module. The module assumes that Spread is installed and
that the spread daemon is running on the local machine.

=head1 INHERITANCE

Messaging::Courier inherits from the EO class.

=head1 CONSTRUCTOR

In addition to the constructor provided by its parent class
Messaging::Courier provides the following constructors:

=over 4

=item new( [Peer => SCALAR [, Port => SCALAR]] )

Provides a connection to the default queue. Peer defaults to 127.0.0.1
(localhost), and Port defaults to 4803 (the default spread port). By
specifiying Peer or Port arguments the queue that Messaging::Courier
connects to can be altered.

  my $c = Messaging::Courier->new();

=back

All constructors can throw two exceptions additional to those thrown
by the default constructor:

=over 2

=item * Messaging::Courier::Error::CouldNotConnect

Thrown when Messaging::Courier cannot connect to the message queue.

=item * Messaging::Courier::Error::CouldNotJoin

Thrown when Messaging::Courier cannot join the correct group on the message queue.

=back

=head1 METHODS

=over 4

=item send( MESSAGE )

Sends a message to the queue.  The message, provided as MESSAGE should
be an object inheriting from Messaging::Courier::Message.  Will throw an
EO::Error::InvalidParameters exception in the case that MESSAGE is not
a Messaging::Courier::Message.

  $c->receive(1);

=item receive( [TIMEOUT[, REPLYING]] )

Receives a message from the queue.  If called without a TIMEOUT or a
TIMEOUT set to zero any call to receive will block.  If a timeout
is specified receive does not block but returns undef in the case that
it does not receive a message.  If REPLYING is specified it should be
a Messaging::Courier::Message object that you are waiting for a reply to. If this
is the case receive will only ever return a message that is in reply
to the message specified by REPLYING.  The receive method will throw
an EO::Error::InvalidParameters object in the case that the parameters
sent do not match this specification.

  my $m = $c->receive(1);

=item ask( MESSAGE[, TIMEOUT] )

Send and receive a message MESSAGE. C<ask()> returns a Messaging::Courier::Message
object unless a TIMEOUT is specified and no message is received in that
period. If this is the case undef is returned instead.

  my $r = $c->ask($m, 1);

=item ask_many( MESSAGE, TIMEOUT )

This sends a message MESSAGE. C<ask_many()> returns all the messages
that are a reply to MESSAGE

  my @received = $c->ask_many($m);

=item id()

returns the id of this Messaging::Courier connection.  The id is appended to all
Frames that are sent on the wire.

=item mailbox()

returns the mailbox of the connection to spread.  This is a spread specific
value and should not be relied apon.

=item name()

returns the name of the connection to Spread

=item private_group()

returns the private group that this connection to spread is a member of. This
is a spread specific value and should not be relied apon.

=item reconnect()

disconnects and reconnects to Spread. This might be useful if your
program sends a lot of messages but does not want to process any.

=back

=head1 SEE ALSO

Messaging::Courier::Message, Messaging::Courier::Frame

=head1 AUTHORS

James A. Duncan <jduncan@fotango.com>, Leon Brocard <lbrocard@fotango.com>

=head1 COPYRIGHT

Copyright 2003-4 Fotango Ltd. All Rights Reserved.

=cut


