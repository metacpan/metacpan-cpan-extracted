#!/usr/bin/perl -w
#-----------------------------------------------------------------
# authority.pl
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: authority.pl,v 1.3 2008/03/13 15:03:58 kawas Exp $
#-----------------------------------------------------------------

use strict;
use warnings;

use MOBY::lsid::authority::MobyMetadataResolver;

use LS::ID;

use LS::Service::Fault;
use LS::Service::Response;
use LS::Service::Authority;
use LS::Service::Namespace;
use LS::Service::DataService;
use LS::Service::AdvancedDataService;

use LS::HTTP::Service;
use LS::RDF::SimpleDocument;

#
# The SOAP service will travel over HTTP to this mod_perl based
# authority where all of the SOAP messages are decoded and
# passed up the SOAP stack until they reach this framework
#
# UNTESTED: The package defaults to HTTP:CGI which works in most
#           cases.
#
#use LS::SOAP::Service transport=> 'HTTP::Apache';
use LS::SOAP::Service transport => 'HTTP::CGI';

##############

# serve wsdl documents on request if they exist and are readable ...
# obtain them from the INC
if($ENV{'REQUEST_URI'} && ($ENV{'REQUEST_URI'} =~ /^\/authority\/(\w+)\.wsdl/)) {
  my $wsdl_location = undef;
  for my $dir (@INC) {
    my $ls_module = "LS/Authority/WSDL/$1.wsdl";
    $wsdl_location = "$dir/$ls_module" if -e "$dir/$ls_module";
  }
  if ($wsdl_location and -e $wsdl_location and -r $wsdl_location) {
    my $parser = XML::LibXML->new();
    my $doc = undef;
    eval {
      $doc    = $parser->parse_file( "$wsdl_location" );
      my $doc = $doc->toString();
      print "Content-type: text/xml\n\n$doc" if $doc;
    }
  }
}

my $location = 'http://';

# TODO get this from the mobyconfig file
if ( $ENV{'HTTP_HOST'} ) {

	$location .= $ENV{'HTTP_HOST'};
}
else {

	# Set this to the default hostname for the authority
	$location .= 'localhost:8080';
}

# Create the authority service
my $authority = LS::Service::Authority->new(
	name                 => 'BioMOBY',
	authority            => 'biomoby.org',
	location             => $location,
	getAvailableServices => \&dynamic_ops
);

#
# Add two ports to the authority:
#
# 1. A HTTP Location for the metadata
#
# 2. A SOAP location for the metadata
#
# 3. A HTTP Location for the data
#
# 4. A SOAP location for the data
#

my $port;

#$port = LS::Authority::WSDL::Simple::MetadataPort->newMetadata(
#	portName=> 'BioMOBYSoapPort',
#	endpoint=> "$location/authority/metadata",
#	protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
#  );
#$authority->addPort(serviceName=> 'BioMOBYSoapMeta', port=> $port);

$port = LS::Authority::WSDL::Simple::MetadataPort->newMetadata(
	portName=> 'BioMOBYHttpPort',
	endpoint=> "$location/authority/metadata",
	protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
  );
$authority->addPort(serviceName=> 'BioMOBYHttpMeta', port=> $port);

#data ports
$port = LS::Authority::WSDL::Simple::DataPort->newData(
        portName=> 'BioMOBYHttpPort',
        endpoint=> "$location/authority/data",
        protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
  );

#$authority->addPort(serviceName=> 'BioMOBYSoapData', port=> $port);
#$port = LS::Authority::WSDL::Simple::DataPort->newData(
#        portName=> 'BioMOBYSoapPort',
#        endpoint=> "$location/authority/data",
#        protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
#  );
#$authority->addPort(serviceName=> 'BioMOBYSoapData', port=> $port);


# Add the metadata service with namespaces

# we will handle 4 namespaces ... namespacetype, serviceinstance, servicetype and objectclass.
#TODO add the other predicates ...
my $metadata = LS::Service::DataService->new();
$metadata->addNamespace( MobyNamespaceType->new() );
$metadata->addNamespace( MobyServiceInstance->new() );
$metadata->addNamespace( MobyServiceType->new() );
$metadata->addNamespace( MobyObjectClass->new() );

my $moby_authority_service = LS::SOAP::Service->new();

$moby_authority_service->metadata_service($metadata);
$moby_authority_service->data_service($metadata);
$moby_authority_service->authority_service($authority);

#
# Create a HTTP service and instruct the SOAP service to
# accept HTTP queries
#
my $moby_http_service = LS::HTTP::Service->new();
$moby_http_service->dispatch_authority_to($authority);
$moby_http_service->dispatch_metadata_to($metadata);

$moby_authority_service->http_server($moby_http_service);

$moby_authority_service->dispatch();

#
# This adds a HTTP/CGI metadata port to the returned WSDL for each valid
# LSID
#
sub dynamic_ops {

# if the namespace is serviceinstance, get the signatureURL and add it as a location
	my ( $lsid, $wsdl ) = @_;
	my %valid_namespaces = (
		"namespacetype"   => 1,
		"serviceinstance" => 1,
		"objectclass"     => 1,
		"servicetype"     => 1
	);
	my $namespace = $lsid->namespace();
	my $object    = $lsid->object();

	return LS::Service::Fault->fault('Unknown LSID')
	  unless ( $valid_namespaces{$namespace} );

# need to decide whether or not i should check exisitence here as well as in the MobyMetadataResolver.pm ...
	my $port;

	do {
		my $length = length($object);
		# some error conditions
		if ( $length > 0 and index( $object, ',' ) > 0 ) {
			my $servicename =
			  substr( $object, index( $object, ',' ) + 1, $length );
			my $authURI = substr( $object, 0, index( $object, ',' ) );

			my $moby = MOBY::Client::Central->new();
			my ( $services, $RegObject ) = $moby->findService(
				authURI     => $authURI,
				serviceName => $servicename
			);
			foreach my $SI (@$services) {
				#should only be one of them ...
				$port = LS::Authority::WSDL::Simple::MetadataPort->newMetadata(
					portName => 'HTTPMetadata',
					endpoint => $SI->signatureURL,
					protocol => $LS::Authority::WSDL::Constants::Protocols::HTTP,
				);
				$wsdl->addPort(
					serviceName => 'ServiceProviderMetadataHTTPPort',
					port        => $port
				);
			}
		}
	} if ( $namespace eq 'serviceinstance' );
	return $wsdl;
}
__END__
