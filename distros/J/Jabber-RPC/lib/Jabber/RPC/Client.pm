# Jabber-RPC: Client Functions
# (c) DJ Adams 2001

# $Id: Client.pm,v 1.1.1.1 2001/09/24 11:23:02 dj Exp $

=head1 NAME

Jabber::RPC::Client - Jabber-RPC Client

=head1 SYNOPSIS

  use Jabber::RPC::Client;

  # Client connects as Jabber client
  my $client = new Jabber::RPC::Client(
    server    => 'myserver.org',
    identauth => 'user:password',
    endpoint  => 'jrpc.myserver.org/rpc-server',
  );  

  my $result = $client->call('examples.getStateName', 5);
  print "getStateName: ", $result || $client->lastfault, "\n";

  # Switch endpoints
  $client->endpoint('another@endpoint.org/resource');
  
  # This time the call will go to the new endpoint
  my $result = $client->call('examples.getStateList', [12,13,14]);
  print "getStateList: ", $result || $client->lastfault, "\n";

=head1 DESCRIPTION

Jabber::RPC::Client is an implementation of a Jabber-RPC client.
A Jabber-RPC client sends XML-RPC-encoded calls carried over
Jabber to an endpoint that is a Jabber::RPC::Server. 

It uses the Frontier::RPC2 XML-RPC implementation to make the
encoding and decoding calls.

The endpoint can either be a Jabber component or a Jabber client
(see the SYNOPSIS examples for Jabber::RPC::Server) - specify the
JID of the endpoint appropriately.

You can change the endpoint with the endpoint() function. 

If you don't specify any value for a 'resource' argument, a default
of 'jrpc-client' will be used. Bear in mind that if you haven't 
specified a value for the 'resource' argument when starting the
Jabber::RPC::Server, a default of 'jrpc-server' will be used there.
Hence the endpoint of 'jrpc.myserver.org/rpc-server' in the 
synopsis example above.

=head1 VERSION

early

=head1 AUTHOR

DJ Adams

=head1 SEE ALSO

Jabber::RPC::Server, Jabber::Connection

=cut

package Jabber::RPC::Client;

use Frontier::RPC2;
use Jabber::Connection;
use Jabber::NodeFactory;
use Jabber::NS qw(:all);

use constant RESOURCE => 'jrpc-client';

use vars qw/$AUTOLOAD/;

use strict;

sub new {

  # to be supplied
  # server : jabber server:port e.g. merlix:5222
  # identauth : user:password e.g. dj:secret
  # endpoint : target Jabber-RPC responder
  # resource: the resource to connect with (optional)
 
  my $class = shift; my %args = @_;
  my $self = {};

  # My (the client's) host/port and Identity
  $self->{server} = $args{server};
  ($self->{id}, $self->{pass}) = split(':', $args{identauth});

  # Target XMLRPC server
  $self->{endpoint} = $args{endpoint};

  # Connect to Jabber
  $self->{connection} = new Jabber::Connection(
    server    => $self->{server},
#   log       => 1,
#   debug     => 1,
  );

  $self->{connection}->connect
      or  die "oops: ".$self->{connection}->lastError;

  $self->{connection}->auth($self->{id}, $self->{pass}, $args{resource} || RESOURCE);

  # XMLRPC server
  $self->{RPC2} = new Frontier::RPC2;

  # Node factory
  $self->{nf} = new Jabber::NodeFactory;

  bless $self, $class;
  return $self;
 
}

sub call {

  my $self = shift;

  # Clear last fault info, results and results
  delete $self->{lastfault};

  # Create XML call payload
  my $request = $self->{RPC2}->encode_call(@_);
  $request =~ s/^<\?[^>]+>\n//; # remove XML declaration

  # Create an IQ
  my $set = $self->{nf}->newNode('iq');
  $set->attr('type', IQ_SET);
  $set->attr('to', $self->{endpoint});
  $set->insertTag('query', NS_RPC)->rawdata($request);

  # Send it
  my $result = $self->{connection}->ask($set);

  # Check for error 
  if ($result->attr('type') eq IQ_ERROR) {
    my $error = $result->getTag('error');
    $self->{lastfault} = $error->data." (".$error->attr('code').")";
    return;
  }

  # Extract the response
  my $response = $result->getTag('query', NS_RPC)->getTag('methodResponse');

  my $struct = $self->{RPC2}->decode($response->toStr);
  return $struct->{'value'}[0];

}


sub endpoint {

  my $self = shift;
  $self->{endpoint} = $_[0] if $_[0];
  return $self->{endpoint};

}


sub DESTROY {
  my $self = shift;
  $self->{connection}->disconnect;
}

sub AUTOLOAD {
  # Not sure I really want this...
  my $self = shift;
  $AUTOLOAD =~ s/^.*:://;
  return if $AUTOLOAD eq "DESTROY"; # bzzt!

  my %functions = (
    'base64'    => 'Base64',
    'boolean'   => 'Boolean',
    'double'    => 'Double',
    'int'       => 'Integer',
    'string'    => 'String',
    'date_time' => 'DateTime',
  );

  return unless defined($functions{$AUTOLOAD});

  my $retval;
  eval "\$retval = new Frontier::RPC2::".$functions{$AUTOLOAD}."(\@_)";

  return $retval;
}


sub lastfault {

  my $self = shift;
  return $self->{'lastfault'};

}

1;
