# Jabber-RPC: J-RPC/HTTP Gateway
# (experimental!)
# (c) DJ Adams 2001

# $Id: HTTPgate.pm,v 1.1.1.1 2001/10/14 20:47:51 dj Exp $

=head1 NAME

Jabber::RPC::HTTPgate - An HTTP gateway for Jabber-RPC / XML-RPC

=head1 SYNOPSIS

  use Jabber::RPC::HTTPgate;

  my $gw = new Jabber::RPC::HTTPgate(
    server    => 'myserver.org:5701',
    identauth => 'jrpchttp.localhost:secret',
    httpcomp  => 'http',
  );  

  $gw->start;

=head1 DESCRIPTION

Jabber::RPC::HTTPgate is an experimental gateway that provides
a conduit service between 'traditional' (HTTP-transported) 
XML-RPC encoded requests/responses and Jabber-RPC (XML-RPC
encoded requests/responses transported over Jabber).

The idea is that you can start a gateway, that connects as
a component to the backbone of a Jabber server, and it proxies
Jabber-RPC to HTTP-based XML-RPC endpoints, and vice versa.
That means that your Jabber-RPC client can not only make XML-RPC
encoded calls to a Jabber-RPC endpoint but also to a 'traditional'
HTTP-based XML-RPC endpoint. And it also means that your 
'traditional' HTTP-based XML-RPC client can make XML-RPC encoded
calls to a Jabber-RPC endpoint.

=head2 Jabber -> HTTP

When you create and start up a gateway, it listens for Jabber-RPC
calls, just like a normal Jabber-RPC responder. On receipt of such a
call, the gateway creates an HTTP request and sends this
request on to the HTTP-based XML-RPC endpoint. The response 
received back from this HTTP call is relayed back to the original
Jabber-RPC requester. 

While a Jabber-RPC endpoint address is a Jabber ID (JID), an 
traditional XML-RPC endpoint address is a URL. So all the Jabber-RPC
client needs to do is specify the URL in the I<resource> part of
the gateway's endpoint JID. 

=head2 HTTP -> Jabber

As well as listening for Jabber-RPC calls, a gateway will also 
service incoming HTTP requests that can be made to the HTTP
component that this gateway uses. The HTTP component (called
simply 'http') can be downloaded from the normal Jabber software
repository. 

On receipt of an HTTP request (passed to it by the HTTP component),
the gateway creates a Jabber-RPC request containing the XML-RPC
encoded payload, and sends it on to the Jabber-RPC responder 
endpoint. This endpoint is identified (via a JID) by the I<path>
part of the URL used in the call by the traditional client.

=head2 Diagram

Here's what it all looks like:


                     +---+   2-----------+            3-----------+
 Jabber backbone ----->  l   | http      |<-- HTTP -->| HTTP      |
                     l   l===| component |            | responder |        
     5-----------+   l   l +->           |<- HTTP -+  |           |
     | JabberRPC |   l   l | +-----------+         |  +-----------+
     | responder |===l   l |                       |         
     |(component)|<---+  l +---+                   |  4-----------+
     +-----------+   l|  l     | <route/>          |  | HTTP      |
                     l|<iq/> 3-v---------+         +->| requester |         
     6-----------+   l+----->| HTTPgate  |            |           |
     | JabberRPC |   l|  l===| component |            +-----------+
     | responder |   l| +--->|           |                   
     | (client)  |   l| |l   +-----------+
     +-----------+   l| |l                     
          ^          l| |l                     
          | <iq/>    l| |l                     
          v          l| |l                     
     7-----------+   l| |l                     
     | JSM       |<---+ |l                                   
     | component |===l  |l                                   
     |           |<-----+l                                   
     +-----------+ <iq/> l
          ^          l   l                                     
          | <iq/>    :   :
          v          +---+
     8-----------+   
     | JabberRPC |  
     | requester | 
     | (client)  |
     +-----------+  

The diagram shows all the possible components in the Jabber-RPC and
traditional HTTP-based XML-RPC world. Each box is numbered. Here are
the descriptions:

=over 4

=item 1 HTTPgate component

This is an instance of this module (HTTPgate.pm) and serves as a
gateway between HTTP-based and Jabber-based XML-RPC requests and
responses. On the one side it uses an http component (see #2) to
make and respond to HTTP calls, and on the other side it accepts
and generates <iq/> packets containing XML-RPC encoded payloads.

=item 2 http component

The HTTPgate component uses this http component to make and receive
HTTP calls. HTTP calls and responses are routed between the HTTPgate
component and this component via <route/>s. You need an http
component like this for HTTPgate to work; download the code from
http://download.jabber.org.

=item 3 HTTP responder

This represents a web server on which an XML-RPC responder is 
present.

=item 4 HTTP requester

This represents a traditional HTTP-based XML-RPC requester.

=item 5 Jabber-RPC responder (component)

This is a Jabber-RPC responder that has been attached to the
Jabber backbone as a component. It responds to 
XML-RPC encoded requests carried in <iq/> packets.

=item 6 Jabber-RPC responder (client)

This is a Jabber-RPC responder that is connected to Jabber 
via the JSM (Jabber Session Manager) as a client. It also responds
to XML-RPC encoded requests carried in <iq/> packets.

=item 7 JSM component

This doesn't have anything to do with Jabber-RPC per se, it's
just that Jabber clients connect via the JSM. 

=item 8 Jabber-RPC requester

This is a Jabber-RPC requester, in the form of a Jabber client, 
connected via the JSM.

=head2 Some examples

=over 4

=item 1 Jabber-RPC client makes request directed to an HTTP-based
responder.

The Jabber-RPC requester (#8) connects to Jabber via the JSM and
creates an XML-RPC encoded request and stores it as the query payload
of an IQ packet. The namespace qualifying the query payload is 
jabber:iq:rpc. Normally, if the request were to to go a Jabber-RPC
responder, the JID of that responder (e.g. jrpc.localhost/jrpc-server)
would be specified in the 'to' attribute of the IQ packet. But
in this case, we want to send the request to an HTTP responder (#3),
so we go through the gateway - the HTTPgate component (#3). 

The address of the HTTP responder is a URL, e.g.:

  http://localhost:8000/RPC2

So we need to specify this URL somewhere - and we specify it in the
I<resource> part of the HTTPgate component's JID. So if the HTTPgate
component's basic JID is jrpchttp.localhost, then we specify 

  jrpchttp.localhost/http://localhost:8000/RPC2

as the target JID. 

=item 2 HTTP-based requester makes request directed to a Jabber-RPC
responder.

The HTTP requester (#4) formulates an XML-RPC encoded request and sends
it to the http component (#2). What's the basic URL of the http 
component? Well, you specify a port in the component instance definition
in the jabber.xml configuration file, like this:

  <service id="http">
    <load><http>./http/http.so</http></load>
    <http xmlns="jabber:config:http">
      <listen port="5281">
        <map to="jrpchttp.localhost"/>
      </listen>
      <timeout>60</timeout>
      <dnsrv>http-dns</dnsrv>
    </http>
  </service>

See the README in the http component tarball for more info.

So the basic URL of the http component is e.g.:

  http://localhost:5281

While we need to specify a URL when we call a HTTP-based XML-RPC
responder from Jabber, this time we need to specify a JID when calling
a Jabber-based XML-RPC responder from HTTP.  What we do is extend the
URL by specifying JID as the I<path>, like this:

  http://localhost:5281/jrpc@localhost/jrpc-server

In this example, the Jabber-RPC responder is connected to Jabber as
a client, not a component - you can tell this from the JID by the
existence of an @ sign (user@hostname - users (their sessions) are
managed by the JSM).

=back

=head2 Setting it all up

You need three components to get this working in both directions;
the HTTPgate component itself, the http component, and a helper DNS
resolver component for when the http component wants to make outgoing
HTTP requests. Setting up the latter two components are described in
the http component's README. (The helper DNS resolver is identified
in the example above by the <dnsrv/> tag).

In the HTTPgate's instantiation call, e.g.:

  my $gw = new Jabber::RPC::HTTPgate(
    server    => 'localhost:5701',
    identauth => 'jrpchttp.localhost:secret',
    httpcomp  => 'http',
  );  

there are three arguments required.

=over 4

=item server

This argument specifies the host and port to which the
HTTPgate component will connect. You will need a corresponding
component instance definition in your jabber.xml configuration
file that looks like this:

  <service id='jrpchttp.localhost'>
    <accept>
      <ip>127.0.0.1</ip>
      <secret>secret</secret>
      <port>5701</port>
    </accept>
  </service>

=item identauth

This is the identity and secret for the component, separated by
a colon. The identity refers to the value of the 'id' attribute in
the component instance definition, and the secret refers to the
value of the <secret/> tag. 

=item httpcomp

This is used to specify the name of the http component, and refers
to the value of the 'id' attribute in the http component's instance
definition in jabber.xml - see earlier for an example of this.

=back

=head1 VERSION

early

=head1 AUTHOR

DJ Adams

=head1 SEE ALSO

Jabber::RPC, Jabber::Connection

=cut

package Jabber::RPC::HTTPgate;

use strict;
use URI;
use Jabber::Connection;
use Jabber::NS qw(:all);

use vars qw($VERSION);

$VERSION = '0.01';

sub new {

  my $class = shift;
  my %args = @_;
  my $self = {};
  
  $self->{server} = $args{server};
  $self->{httpcomp} = $args{httpcomp};
  ($self->{id}, $self->{pass}) = split(':', $args{identauth});

  $self->{iq_requests} = { id => 1 };

  $self->{c} = new Jabber::Connection(
    server    => $self->{server},
    localname => $self->{id},
    ns        => NS_ACCEPT,
    log       => 1,
  );

  $self->{c}->register_handler('iq',    sub { $self->_reflect(@_) }      );
  $self->{c}->register_handler('iq',    sub { $self->_relay_result(@_) } );
  $self->{c}->register_handler('route', sub { $self->_handle_http(@_) }  );

  $self->{nf} = new Jabber::NodeFactory;

  $self->{c}->connect or die "Oops: ".$self->{c}->lastError;
  $self->{c}->auth($self->{pass});

  bless $self => $class;
  return $self;

}

sub start {

  my $self = shift;
  $self->{c}->start;

}



sub _reflect {

  my $self = shift;
  my $node = shift;

  # Ignore irrelevant packets. What we want is
  # an IQ-set with a jabber:iq:rpc qualified NS
  return unless $node->attr('type') eq IQ_SET
            and my $query = $node->getTag('query', NS_RPC);

  my $request = $query->getTag('methodCall')->toStr;
# my $request = $node->getTag('query', NS_RPC)->getTag('methodCall')->toStr;

  # We need to create a route packet to the http component
  # that looks like this:
  # 
  # <route type='request' to='http' from='id@component'>
  #   <http type='post' to='www.server.com' port='80' path='/RPC2'>
  #     <body>
  #     the payload
  #     </body>
  #   </http>
  # </route>

  # Store the request addresses
  # (we want to refer to this in handle_response())
  $self->{iq_requests}->{++$self->{iq_requests}->{id}} = {
                                 'from' => $node->attr('from'),
                                 'to'   => $node->attr('to'),
                                 'id'   => $node->attr('id'),
                               };

  my $route = $self->{nf}->newNode('route');
  $route->attr('type', 'request');
  $route->attr('to', $self->{httpcomp});
  $route->attr('from', join('@', $self->{iq_requests}->{id}, $self->{id}));

  # Resource should contain the URL
  my (undef, undef, $r) = _parseJID($node->attr('to'));

  # Split up URL
  my $uri = new URI($r);

  my $http = $route->insertTag('http');
  $http->attr('type', 'post');
  $http->attr('to', $uri->host);
  $http->attr('port', $uri->port) if $uri->port;
  $http->attr('path', $uri->path) if $uri->path;

  # Insert the payload
  $http->insertTag('body')->rawdata($request);

  # Send it along to the http component
  $self->{c}->send($route);

}


sub _relay_result {

  my $self = shift;

  # Relaying the result of a JRPC IQ, via the http
  # component. We need to generate a routed packet
  # that looks like this:
  #
  # <route type="result" to="hashid@http">
  #  <http status="123 Foo">
  #   <head Abc="def"/>
  #   <body>my content</body>
  #  </http>
  # </route>

  my $node = shift;

  # Ignore irrelevant packets. What we
  # want is an IQ result with a NS_JRPC-qualified <query/>
  return unless ($node->attr('type') eq IQ_RESULT
             or $node->attr('type') eq IQ_ERROR)
            and my $query = $node->getTag('query', NS_RPC);
  
  # The resource on the 'to' is the http id
  # to send back to
  (undef, undef, my $httpid) = _parseJID($node->attr('to')); 

  # Create route to send HTTP result back
  my $route = $self->{nf}->newNode('route');
  $route->attr('type', 'result');
  $route->attr('to', $httpid);
  $route->attr('from', $self->{id});

  # Add http element
  my $http = $route->insertTag('http');

  # We need to reflect any IQ-related error
  # (e.g. 502 Internal Timeout) - how ...? 
  # As the HTTP status? Hmmm.
  if ($node->attr('type') eq IQ_ERROR) {
    my $error = $node->getTag('error');
    $http->attr('status', join(' ', $error->attr('code'), $error->data));
  }
  else {
    $http->attr('status', '200 OK');
  }

  # Copy the payload from the IQ
  my $payload = $query->getTag('')->toStr; # usually methodResponse but will
                                           # be methodCall when type='error'

  # Add some headers
  my $header;
  $header = $http->insertTag('head');
  $header->attr('Content-type', 'text/xml');
  $header = $http->insertTag('head');
  $header->attr('Content-length', length($payload));

  $http->insertTag('body')->rawdata($payload);

  $self->{c}->send($route);

}


sub _handle_http {

  my $self = shift;
  my $node = shift;

  # Ignore everything except from the http component
  my (undef, $sending_host, undef) = _parseJID($node->attr('from'));
  return unless $sending_host eq $self->{httpcomp};

  # Either it's a request or a result:
  # A request: an incoming HTTP call to be reflected
  #            to a Jabber-component/client based responder
  # A result:  the result of our making an HTTP call in 
  #            a Jabber-to-HTTP reflection

  if ($node->attr('type') eq 'request') { $self->_handle_http_request($node) }
  if ($node->attr('type') eq 'result')  { $self->_handle_http_result($node) }

  return;

}

sub _handle_http_request {

  my $self = shift;
  my $node = shift;

  # Request will look like this:
  # <route type="request" to="component" from="hashid@http">
  #  <http type="post" path="/foo.xml">
  #   <head header="val"/>
  #   <body var="val">foo</body>
  #  </http>
  # </route>

  my $http = $node->getTag('http');

  # Ignore non-POST requests
  return unless $http->attr('type') eq 'post';

  # Get path - this is the JID of the Jabber-RPC responder
  my $jid = $http->attr('path');
  $jid =~ s|^\/||;  # must remove initial slash
  
  # Get the payload
  my $payload = $http->getTag('body')->getTag('methodCall')->toStr;

  # Construct the request IQ 
  my $iq = $self->{nf}->newNode('iq');
  $iq->attr('type', IQ_SET);
  $iq->attr('from', join('/', $self->{id}, $node->attr('from')));
  $iq->attr('to', $jid);
  $iq->insertTag('query', NS_RPC)->rawdata($payload);

  $self->{c}->send($iq);

}


sub _handle_http_result {

  my $self = shift;
  my $node = shift;

  # Set up response
  my $response = $self->{nf}->newNode('iq');

  # Get the key for our request hash - it's in
  # the user part of the JID
  my ($u, undef, undef) = _parseJID($node->attr('to'));

  # Address the response
  $response->attr('to', $self->{iq_requests}->{$u}->{from});
  $response->attr('from', $self->{iq_requests}->{$u}->{to});

  # Respond with the id from the request
  $response->attr('id', $self->{iq_requests}->{$u}->{id});
  
  # Reflect the type (result|error) from the route
  # into the returning IQ
  $response->attr('type', $node->attr('type'));
  if ($response->attr('type') eq IQ_ERROR) {
    my $error = $response->insertTag('error');
    $error->attr('code', '502');
    $error->data('Remote Server Error');
  }

  # Transfer the payload from the result to our IQ
  # (If it's an error, the HTTP component returns the
  # original payload. This is nice.)
  my $query = $response->insertTag('query', NS_RPC);
  my $payload = $node->getTag('http')->getTag('body')->getTag('');
  $query->rawdata($payload->toStr);

  $self->{c}->send($response);

}


sub _parseJID {

  my $jid = shift;
  my ($user, $host, $resource, $rest);

  # Is there a username part? (an @ before any /)
  if ($jid =~ m[^[^\/]+@]) {
    ($user, $rest) = split("@", $jid, 2);
  }
  else {
    $rest = $jid;
  }

  ($host, $resource) = split('/', $rest, 2);

  return ($user, $host, $resource);

}


1;
