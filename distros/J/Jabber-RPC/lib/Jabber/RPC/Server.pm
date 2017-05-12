# Jabber-RPC: Server Functions
# (c) DJ Adams 2001

# $Id: Server.pm,v 1.1.1.1 2001/09/24 11:23:02 dj Exp $

=head1 NAME

Jabber::RPC::Server - Jabber-RPC Server

=head1 SYNOPSIS

  use Jabber::RPC::Server;

  sub function1 {
    ...
  }

  sub function2 {
    ...
  }

  # Server as Jabber component
  my $server = new Jabber::RPC::Server(
    server         => 'myserver.org:5702',
    identauth      => 'jrpc.myserver.org:secret',
    connectiontype => 'component',
    methods        => { 
                        'rpc.function1' => \&function1,
                        'rpc.function2' => \&function2,
                      } 
  );  

  # or ...

  # Server as Jabber client
  my $server = new Jabber::RPC::Server(
    server    => 'myserver.org',
    identauth => 'id:secret',
    resource  => 'jrpc-server',
    methods   => { 
                   'rpc.function1' => \&function1,
                   'rpc.function2' => \&function2,
                 } 
  );  


  $server->start;

  
=head1 DESCRIPTION

Jabber::RPC::Server is an implementation of a Jabber-RPC server.
A Jabber-RPC server receives XML-RPC-encoded calls carried over
Jabber and responds to them.

You can have your Jabber::RPC::Server connect as a Jabber component
or as a Jabber client - see the differences in the SYNOPSIS example
above. (One difference is that you need to specify connectiontype =>
'component' for a Jabber component connection - the default assumption
is that you want to connect as a Jabber client.)

If you don't specify a value for the 'resource' argument (in the 
SYNOPSIS example, a value is specified for the Jabber client 'flavour'
but not for the Jabber component 'flavour') then the default of
'jrpc-server' will be used.

=head1 VERSION

early

=head1 AUTHOR

DJ Adams

=head1 SEE ALSO

Jabber::RPC::Client, Jabber::Connection

=cut

package Jabber::RPC::Server;

use Frontier::RPC2;
use Jabber::Connection;
use Jabber::NS qw(:all);

use constant RESOURCE => 'jrpc-server';

use strict;

sub new {
  my $class = shift; my %args = @_;
  my $self = {};

  # to supply:
  # server: jabber server/port
  # identauth: jabber identity/password
  # connectiontype: component (optional, defaults to client)
  # methods: hashref of methods and handlers
  
  # Host/port and Identity
  $self->{server} = $args{server};
  ($self->{id}, $self->{pass}) = split(':', $args{identauth});
  $self->{methods} = $args{methods};
  $self->{connectiontype} = lc $args{connectiontype} || 'client';

  # Connect as Component ?
  if ($self->{connectiontype} eq 'component') {

    _debug("Component connection requested");

    $self->{connection} = new Jabber::Connection(
      server    => $self->{server},
      localname => $self->{id},
      ns        => NS_ACCEPT,
      log       => 1,
      debug     => 1,
    );

    $self->{connection}->connect
        or  die "oops: ".$self->{connection}->lastError;

    $self->{connection}->auth($self->{pass});

  } 

  # Default: Connect as Client
  else {

    _debug("Client connection requested");

    $self->{connection} = new Jabber::Connection(
      server    => $self->{server},
      log       => 1,
      debug     => 1,
    );

    $self->{connection}->connect
        or  die "oops: ".$self->{connection}->lastError;

    $self->{connection}->auth($self->{id}, $self->{pass}, $args{resource} || RESOURCE);

  }

  # XMLRPC server
  $self->{RPC2} = new Frontier::RPC2;

  # Set up request handler
  $self->{connection}->register_handler(

     'iq' => sub {

      my $node = shift;
      _debug("rpc_handler received: ", $node->toStr);

      my $request = $node->getTag('query', NS_RPC)->getTag('methodCall');
      my $response = $self->{RPC2}->serve($request->toStr, $self->{methods});
      $response =~ s/^<\?[^>]+>\n//;
      $node->attr('type', IQ_RESULT);

      my $from = $node->attr('from');

      # Must set 'from' ourselves if we're a component
      if ($self->{connectiontype} eq 'component') {
        $node->attr('from', $node->attr('to'));
      }
      else {
        $node->attr('from', '');
      }

      $node->attr('to', $from);
      $request->hide;
      $node->getTag('query')->rawdata($response);
      $self->{connection}->send($node);

    }

  );
  _debug("Request handler set up");

  bless $self, $class;
  return $self;
 
}

# Start the service
sub start {

  my $self = shift;

  _debug("Starting process...");

  # Go!
  $self->{connection}->start;

}


sub _debug {

  print STDERR "DEBUG: @_\n";

}

1;

