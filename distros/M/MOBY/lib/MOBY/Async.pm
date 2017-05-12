=pod

=head1 NAME

MOBY::Async - a set of tools for Asynchronous MOBY Services

=head1 SYNOPSIS

This is a set of tools for providing and invoking Asynchronous MOBY Services.

=head1 FORMER AUTHORS

Enrique de Andres Saiz (enrique.deandres@pcm.uam.es) -
INB GNHC-1 (Madrid Science Park, Spain).

=head1 MAINTAINERS

Jose Manuel Rodriguez Carrasco (jmrodriguez@cnio.es) -
INB GN-2 (Centro Nacional de Investigaciones Oncologicas, Spain).

Jose Maria Fernandez Gonzalez (jmfernandez@cnio.es) -
INB GN-2 (Centro Nacional de Investigaciones Oncologicas, Spain).

=head1 DESCRIPTION

MOBY::Async package provides a set of modules for working with Asynchronous MOBY
Services, both from client and server side. It consists of the following modules:

=over

=item MOBY::Async::SimpleServer

It provides a simple class that can be extended to build file based asynchronous
services.

=item MOBY::Async::Service

It provides a class to invoke asynchronous services.

=item MOBY::Async::LSAE

It provides functionalities to work with LSAE analysis event blocks.

=item MOBY::Async::WSRF

It extends L<WSRF::Lite> perl module and provides everything required for
L<MOBY::Async::SimpleServer> class.

=back

=head1 EXAMPLE

The following example implements the classic "Hello World" service with a delay
of 60 seconds.

From the server side, an asynchronous service is very similar to the traditional
synchronous BioMOBY services. It is composed by a cgi (dispatcher.cgi) and a
Perl module wich extends L<MOBY::Async::SimpleServer> class (HelloWorld.pm).

B<dispatcher.cgi>

  #!/usr/bin/perl
  use lib "/path/to/my/libs";
  use strict;
  use SOAP::Transport::HTTP;
  use MOBY::Async::WSRF;
  use MOBY::Async::SimpleServer;
  use HelloWorld;

  my $server = new SOAP::Transport::HTTP::CGI;
  $server->serializer(WSRF::Serializer->new);
  $server->deserializer(WSRF::Deserializer->new);
  $server->on_action(sub{});
  $server->dispatch_with({
    $WSRF::Constants::MOBY.'#sayHello'        => 'HelloWorld',
    $WSRF::Constants::MOBY.'#sayHello_submit' => 'HelloWorld',
    $WSRF::Constants::WSRPW.'/GetResourceProperty/GetResourcePropertyRequest' => 'MOBY::Async::SimpleServer',
    $WSRF::Constants::WSRPW.'/GetMultipleResourceProperties/GetMultipleResourcePropertiesRequest' => 'MOBY::Async::SimpleServer',
    $WSRF::Constants::WSRLW.'/ImmediateResourceTermination/DestroyRequest' => 'MOBY::Async::SimpleServer',
  });
  $server->handle();

B<HelloWorld.pm>

  package HelloWorld;
  use strict;
  use MOBY::CommonSubs qw(:all);
  use MOBY::Async::SimpleServer;
  use base qw(MOBY::Async::SimpleServer);

  # This environment variable must be set - it is used internally
  # by MOBY::Async::SimpleServer class
  $ENV{AUTHURI} = 'your.auth.com';

  # This variable is a subroutine which carries out the core of the service
  my $sayHello = sub {
    my ($caller, $data) = @_;
    my $response = '';

    my @queries = getInputs($data);
    return responseHeader($ENV{AUTHURI}).responseFooter() unless (scalar(@queries));

    foreach my $query (@queries) {
      my $queryID = getInputID($query);
      $response .= simpleResponse('Hello, Asynchronous BioMOBY world!!!', 'message', $queryID);
      sleep 60;
    }

    return SOAP::Data->value(responseHeader($ENV{AUTHURI}).$response.responseFooter())->type('string');
  };

  # This is the method which answers to synchronous requests
  sub sayHello {
    my $self = shift @_;
    # Here you can choose between sync or error
    return $self->sync($sayHello, 180, @_);
    #return $self->error(@_);
  }

  # This is the method which answers to asynchronous requests
  sub sayHello_submit {
    my $self = shift @_;
    return $self->async($sayHello, @_);
  }

  1;  

A client which wishes to run an asynchronous service as HelloWorld must carry out
the following steps:

1. First we have a sayHello_submit (servicename_submit) invocation, which
returns an EPR, that it is a "ticket" unique for all the async services of
the service provider (or at least in that particular server).
sayHello_submit is called with a normal BioMOBY input but it returns an EPR
which will be included into the SOAP header of all the subsequent calls (to
say which batch-call).

2. After this, a polling is done by invocating GetMultipleResourceProperties
operation. GetMultipleResourceProperties retrieve the content of one or several
properties. In this case, as we are trying to determine if a batch-call has
finished, we ask all status properties (status_queryID). The status returned
for each status property is in LSAE format. Unless all status properties
represent that execution for its respective query identifier is finished, we
sleep a time and we retry the polling again.

3. Once all status properties represent a finished execution, there is another
GetMultipleResourceProperties invocation asking for the result properties.
The content of the returned result properties are in BioMOBY format.

4. The client also explicitly calls the WSRF Destroy operation to clean the
results at the service side.

To do this, a client relies on MOBY::Async::Service class, whose use is very
similar to MOBY::Client::Service class available for synchronous services:

  # By default, silent is true, then no messages about the progress are reported
  my $S = MOBY::Async::Service->new(service => $wsdl);
  $S->silent(0); 
  my $response = $S->execute(XMLinputlist => [
    ['myArtName00', '<String namespace="" id=""><![CDATA[Hey No. 0 !!!]]></String>'],
    ['myArtName01', '<String namespace="" id=""><![CDATA[Hey No. 1 !!!]]></String>']
  ]);
  print "$response\n";

Additionally, MOBY::Async::Service class provides methods to carry out
individually the steps previously described:

  my $S = MOBY::Async::Service->new(service => $wsdl);
  my ($EPR, @queryIDs) = $S->submit(XMLinputlist => [
    ['myArtName00', '<String namespace="" id=""><![CDATA[Hey No. 0 !!!]]></String>'],
    ['myArtName01', '<String namespace="" id=""><![CDATA[Hey No. 1 !!!]]></String>']
  ]);
  #...
  my @status = $S->poll($EPR, @queryIDs);
  #...
  my @response = $S->result($EPR, @queryIDs);
  #...
  $S->destroy($EPR);

=head1 FURTHER READING

L<MOBY::Async::SimpleServer>, L<MOBY::Async::Service>, L<MOBY::Async::LSAE> and
L<MOBY::Async::WSRF> Perl modules documentation.

Asynchronous BioMOBY Services Specification:
L<http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Docs/asyncDocs/BioMOBY%20Asynchronous%20Service%20Specification%20v2.4.2.pdf>

WSRF Specifications:
L<http://www.oasis-open.org/committees/tc_home.php?wg_abbrev=wsrf#technical>

=cut
