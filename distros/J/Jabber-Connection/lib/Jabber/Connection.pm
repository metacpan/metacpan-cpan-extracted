package Jabber::Connection;

# $Id: Connection.pm,v 1.7 2002/05/06 16:53:11 dj Exp $

=head1 NAME

Connection - Simple connectivity functions for Jabber

=head1 SYNOPSIS

  # client connection:
  my $c = new Jabber::Connection(
    server => 'jabber.org',
    log    => 1,
  );
  
  # component connection:
  # my $c = new Jabber::Connection(
  #   server    => 'localhost:5700',
  #   localname => 'comp.localhost',
  #   ns        => 'jabber:component:accept',
  #   log       => 1,
  #   debug     => 1,
  # );
  
  die "oops: ".$c->lastError unless $c->connect();
  
  $c->register_beat(10, \&every_10_seconds);
  
  $c->register_handler('presence',\&presence);
  $c->register_handler('iq',\&handle_iq_conference);
  $c->register_handler('iq',\&handle_iq_browse);
    
  $c->auth('qmacro','password','myresource'); # client auth
  # $c->auth('secret'); # component auth

  $c->send('<presence/>');

  $c->start;
  
=head1 DESCRIPTION

The Jabber::Connection package provides basic functions
for connecting clients and components to a Jabber server. 

=cut

use strict;
use XML::Parser;
use IO::Socket::INET;
use IO::Select;
use Digest::SHA1 qw(sha1_hex);
use Carp;

use Jabber::NS qw(:all);
use Jabber::NodeFactory;

use constant BEAT => 5;

use vars qw($VERSION);

$VERSION = '0.04';

my $id = 1;

=head1 METHODS

=over 4

=item new()

The connection constructor. Returns a new Jabber::Connection object.
The parameters are specified in a 

  param => value

list.

For a basic client connection, you can specify the minimum

  my $c = new Jabber::Connection(server => 'jabber.org');

If no port is specified, the default 5222 will be used.
There are other parameters that can be passed:

=over 4

=item ns

the namespace that qualifies the connection stream. If
left unspecified, this will default to 'jabber:client'.
For a TCP socket-based component, specify
'jabber:component:accept'. [ *** These are the only two
stream namespaces supported now *** ]

=item localname

the name of the component in a component connection.

=item ssl

whether the connection should use SSL
[ *** not supported yet! *** ]

=back

See the SYNOPSIS for examples of new().

=cut

sub new {

  my ($class, %args) = @_;
  my $self = {};

  # poss. keys in %args: server, namespace, localname, ssl (?)

  croak "No host specified" unless $args{server};
  ($self->{host}, $self->{port}) = split(":", $args{server});
  $self->{port} ||= 5222;

  $self->{ns} = $args{ns} || NS_CLIENT;
  $self->{localname} = $args{localname};
  $self->{debug} = $args{debug};
  $self->{log} = $args{log};
  
  $self->{parser} = new XML::Parser
    (
      Handlers => {
                     Start => sub { $self->_startTag(@_) },
                     End   => sub { $self->_endTag(@_) },
                     Char  => sub { $self->_charData(@_) },
                  }
    )->parse_start();
  
  $self->{nf} = Jabber::NodeFactory->new();
  $self->{beatcount} = 0;
  $self->{connected} = 0;
  $self->{streamerror} = 0;
  return bless $self, $class;

}


=item connect()

Use this to establish the stream to the Jabber server. There
are no parameters required. If a problem occurs, the function
returns 0, and the error reason is available by calling
C<lastError()>. 

Example:

  $c->connect();

=cut

sub connect {

  my $self = shift;
  $self->{socket} = new IO::Socket::INET
    (
      PeerAddr => $self->{host},
      PeerPort => $self->{port},
      Proto    => 'tcp',
    );
  
  unless ($self->{socket}) {
    $self->{errortext} = "Can't establish socket connection";
    return 0;
  }

  $self->{select} = new IO::Select($self->{socket});

  $self->_write($self->_stream_header());
  $self->_read();
  if ($self->{streamerror}) {
    return 0;
  }
  else {
    return $self->{connected} = 1;
  }

}


=item disconnect()

Use this to terminate the stream and end the connection.

Example:

  $c->disconnect();

=cut

sub disconnect {

  my $self = shift;

  # send unavailable presence?
  $self->_write("</stream:stream>");

}


=item process()

Call this function to look for incoming fragments on the stream.
You can specify an optional argument which is the number of seconds
to wait while looking. If no argument is given, a value of 0 is
assumed.

An incoming fragment is parsed and assembled into a Node object which
is dispatched to any handlers that have been registered for the Node
object's tag name.

Examples:

  $c->process();   # look for any fragments but don't
                   # wait around if there aren't any

  $c->process(5);  # wait for up to 5 seconds for fragments
                   # to come in on the stream


=cut

sub process {

  my $self = shift;
  my $timeout = shift || 0;

  if ($self->{select}->can_read($timeout)) {
    return $self->_read();
  }

  return 1;


}

sub _getID {

  $id++;

}


=item auth()

Perform authorization. This function takes either one or three 
arguments, depending on what type of connection has been made.
If you have made a I<component> connection, the secret must be
specified here as the single argument. If you have made a 
I<client> connection, the username, password and resource must
be specified.

Example:

  $c->auth('secret'); # component auth
  $c->auth('user','password','resource'); # client auth

For a component authorization, the <handshake/> based process
is used. For a client authorization, the JSM is queried for the
supported authentication methods, and then one is picked, 
degrading gracefully through zero-k, digest and plaintext
methods.

=cut

sub auth {

  my $self = shift;
  my ($user, $pass, $resource, %args, $secret);

  $self->_checkConnected;

  if ($self->{ns} eq NS_CLIENT) {

    ($user, $pass, $resource, %args) = @_;
    croak "Supply user/pass/resource" unless $user and $pass and $resource;

    my $auth_node = $self->{nf}->newNode('iq');
    $auth_node->attr('type', IQ_GET);
    my $query = $auth_node->insertTag('query');
    $query->attr('xmlns', NS_AUTH);
    $query->insertTag('username')->data($user);
  
    my $get_result = $self->ask($auth_node);

    # Assume we can authenticate and prepare a set
    $auth_node->attr('type', IQ_SET);
    $auth_node->attr('id', $self->_getID());

    # Zero-k?
    if ($get_result->getTag('query')->getTag('token')) {
      $self->_debug("auth: zerok supported");
      my $hash = sha1_hex($pass);
      my $seq  = $get_result->getTag('query')->getTag('sequence')->data;
      $hash = sha1_hex($hash.$get_result->getTag('query')->getTag('token')->data);
      $hash = sha1_hex($hash) while $seq--;
      $query->insertTag('hash')->data($hash);
    }
  
    # digest?
    elsif ($get_result->getTag('query')->getTag('digest')) {
      $self->_debug("auth: digest supported");
      $query->insertTag('digest')->data(sha1_hex($self->{streamid}.$pass));
    }
  
    # plaintext?
    elsif ($get_result->getTag('query')->getTag('password')) {
      $self->_debug("auth: plaintext supported");
      $query->insertTag('password')->data($pass);
    }
  
    else {
  
      croak "No authentication methods available";
  
    }
  
    # abort to do
  
    # Add resource (common to all auth methods)
    $query->insertTag('resource')->data($resource);
  
    # Auth attempt
    my $set_result = $self->ask($auth_node);
  
#   XXX todo: perhaps return undef/0 instead of croaking?

    unless ($set_result->attr('type') eq IQ_RESULT) {
      croak "auth failed"; }
  }


  elsif ($self->{ns} eq NS_ACCEPT) {
    ($secret) = @_;

    my $handshake = $self->{nf}->newNode('handshake');
    $handshake->data(sha1_hex($self->{streamid}.$secret));

    my $result = $self->ask($handshake);

#   XXX todo: will barf with stream:error if bad secret. 
#   XXX       need to catch.

  }

}


sub _stream_header {

  my $self = shift;
  my $to = defined($self->{localname}) ? $self->{localname} : $self->{host};
  my $hdr = qq[<?xml version='1.0'?><stream:stream xmlns='$self->{ns}' xmlns:stream='http://etherx.jabber.org/streams' to='$to'];
# $hdr .= qq[ from='$self->{localname}'] if $self->{ns} eq NS_ACCEPT;
  $hdr .= qq[>];
  return $hdr;
}


=item send()

Send data across the stream with this function. You can send either 
XML in string form, or send a Node object. 

Examples:

  $c->send('<presence/>');

  my $msg = $nf->newNode('message')->insertTag('body')->data('hello');
  $msg->attr('to','qmacro@jabber.org');
  $c->send($msg);

=cut

sub send {

  my $self = shift;

  $self->_checkConnected;

  my $what = shift;
  if (ref($what) eq 'Jabber::NodeFactory::Node') {
    $what = $what->toStr();
  }
  $self->_write($what);

}


sub _write {

  my $self = shift;
  my $data = shift;
  $self->_log("SEND: ".$data);

  $self->{socket}->send($data);
  
}

sub _read {

  my $self = shift;
  my $data;
  my $received;

  while (defined $self->{socket}->recv($data, 1024)) {   # or POSIX::BUFSIZ?
    $received .= $data;
    last if length($data) != 1024;
  }
  $self->_log("RECV: ".$received);
  $self->{parser}->parse_more($received);

  return $received;
}


sub _log {

  my $self = shift;
  my $string = shift;

  if ($self->{log}) {
    print STDERR $string, "\n";
  }

}



sub _debug {

  my $self = shift;
  my $string = shift;

  if ($self->{debug}) {
    print STDERR $string, "\n";
  }

}

  
sub _startTag {

  my ($self, $expat, $tag, %attr) = @_;
  if ($tag eq "stream:stream") {
    $self->{confirmedhost} = $attr{from};
    $self->{streamid} = $attr{id};
  }
  else {
    $self->{depth} += 1;

    # Top level fragment
  	if ($self->{depth} == 1) {

      # Check it's not an error
      if ($tag eq 'stream:error') {
        $self->{streamerror} = 1;
      }
      # Not an error - create Node
      else {
        $self->_debug("startTag: creating new node for $tag");
        $self->{node} = Jabber::NodeFactory::Node->new($tag);
        $self->{node}->attr($_, $attr{$_}) foreach keys %attr;
        $self->{currnode} = $self->{node};
      }
    }

    # Some node within a fragment
    else {
      my $kid = $self->{currnode}->insertTag($tag);
      $kid->attr($_, $attr{$_}) foreach keys %attr;
      $self->{currnode} = $kid;
    }
  }
}

sub _endTag {

  my ($self, $expat, $tag) = @_;

  # Don't bother to do anything if there's an error
  return if $self->{streamerror};

  if ($self->{depth} == 1) {
    $self->_dispatch($self->{currnode});
  }
  else {
    $self->{currnode} = $self->{currnode}->parent();
  }

  $self->{depth} -= 1;

}

sub _charData {

  my ($self, $expat, $data) = @_;
  
  # Die if we get an error mid-stream
  if ($self->{streamerror}) {
    $self->{errortext} = $data;
    croak "stream error: $data" if $self->{connected};
  }

  # Otherwise append the data to the current node
  else {
    $self->{currnode}->data($self->{currnode}->data().$data);
  }
}


=item lastError()

Returns the last error that occured. This will usually be the
text from a stream error. 

=cut

sub lastError {
  my $self = shift;
  $self->{errortext};
}


sub _dispatch {

  my ($self, $node) = @_;
  $self->_debug("dispatching ".$node->name);

  # Expecting an answer?
  if ($self->{askID}) {
    $self->{askID} = undef;
    $self->{answer} = $node;
    return;
  }

  # Otherwise call the handlers
  my $parcel = undef;
  foreach my $handler (@{$self->{handlers}->{$node->name}}) {
    $parcel = $handler->($node, $parcel) || $parcel;
    last if defined $parcel and $parcel eq r_HANDLED;
  }

}


=item ask()

Send something and wait for a response relating to what was sent. This
relation is established using an id attribute in the top level tag of
the node being sent. If there is no id attribute, one is inserted with
a value automatically assigned.

=cut

sub ask {

  my ($self, $node) = @_;
  $self->_debug("ask: ".$node->name);

  # Add id if needed and remember
  unless ($self->{askID} = $node->attr('id')) {
    $self->_debug("ask: no ID - getting one");
    $self->{askID} = $node->attr('id',$self->_getID());
  }
  $self->_debug("ask: id=".$self->{askID});

  # Send
  $self->_write($node->toStr());

  # Wait for response
  while (not defined $self->{answer}) {
    $self->_debug("ask: waiting on answer");
    $self->process(1);
  }

  my $answer = $self->{answer};
  $self->{answer} = undef;

  $self->_debug("ask: got answer: ".$answer->toStr());

  return $answer;
}


=item register_handler()

When a fragment is received and turned into a Node object, a dispatching
process is started which will call handlers (callbacks) that you can set
using this function.

The function takes two arguments. The first is used to identify the node
type (the element) - e.g. 'message', 'presence' or 'iq'. The second is
a reference to a subroutine.

You can register as many handlers as you wish. Each of the handlers 
registered for a specific node type will be called in turn (in the
order that they were registered). Each of the handlers are passed two
things - the node being dispatched, and a 'parcel' which can be used to
share data between the handlers being called. The parcel value passed
to the first handler in the call sequence is undef. Whatever value 
is returned by a particular handler is then passed onto the next 
handler. 

If a handler returns nothing (e.g. by simply the C<return> statement),
then the parcel data remains unaffected and is passed on intact to the
next handler.

(You don't have to do anything with the parcel; it's there just in
case you want to pass something along the call sequence.)

If a handler returns the special value represented by the constant
C<r_HANDLED>, the call sequence is ended - no more handlers in the
list are called in the dispatch for that node.

Examples:

  $c->register_handler(
         message => sub {
                          ...
                        }
  );

  $c->register_handler('iq', \&handle_version);
  $c->register_handler('iq', \&handle_time);
  $c->register_handler('iq', \&handle_browse);

=cut

sub register_handler {

  my $self = shift;
  my ($tag, $handler) = @_;
  $self->_debug("registering handler $handler");
  push @{$self->{handlers}->{$tag}}, $handler;
  
}


=item register_beat()

You can register subroutines to be called on a regular basis using
the C<heartbeat> feature. The first argument is the number of seconds
('every N seconds'), the second is a subroutine reference.

Example:

  $c->register_beat(1800, \&getRSS);

This example registers a subroutine getRSS() to be called every
half an hour.

Note: the heart doesn't start beating until the start() function
is called.

=cut

sub register_beat {

  my $self = shift;
  my ($secs, $handler) = @_;
  $self->_debug("registering beat $handler");
  push @{$self->{heartbeats}->{$secs}}, $handler;

}


=item start()

Start a process loop. This has a similar effect to something
like

  while (1) { $c->process(1) }

except that it also maintains a heartbeat (see 
register_beat()).

=cut

sub start {

  my $self = shift;
  $SIG{ALRM} = sub { $self->_heartbeat(); alarm BEAT; };
  alarm BEAT ;
  1 while $self->process(1);
}


sub connected {

  my $self = shift;
  $self->{connected};

}


sub _checkConnected {

  my $self = shift;
  croak "No connection/stream established!" unless $self->connected;

}


sub _heartbeat {

  my $self = shift;
  $self->{beatcount} += BEAT;
  foreach my $beat (keys %{$self->{heartbeats}}) {
    if ($self->{beatcount} % $beat == 0) {
      $_->() foreach @{$self->{heartbeats}->{$beat}};
    }
  }
}

=back

=head1 SEE ALSO

Jabber::NodeFactory, Jabber::NS

=head1 AUTHOR

DJ Adams

=head1 VERSION

early

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
1;
