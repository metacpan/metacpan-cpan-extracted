#!/usr/bin/perl -w
#-----------------------------------------------------------------
# service_unit_tester.pl
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: service_unit_tester.pl,v 1.2 2009/02/12 19:29:47 kawas Exp $
#
# BETA
#
# This script goes ahead an asks a registry what services exist
# and then goes ahead and extracts their signature urls.
#
# The signature urls are then parsed into services and any service
# with a valid unit test is tested and the data stored in an XML file.
#
# Configurable options:
# 	TIMEOUT 		- the timeout in seconds to wait for each service
#	CATEGORIES		- the moby service categories to test
#	URL				- the registry endpoint <optional>
#	URI				- the registry namespace <optional>
#   DIRECTORY		- the place to store details between jobs <optional>
#
# IMPORTANT NOTES:
#    This script doesn't fork yet, so as more and more services provide
#    unit tests, this script will take longer and longer to complete.
#
# This script works on windows/unix/linux. Other machines have not been
# tested, but they may well work just fine since we don't do any black
# magic.
#-----------------------------------------------------------------

use strict;
use warnings;

use MOBY::Config;
use MOBY::Client::Central;
use MOBY::RDF::Parsers::ServiceParser;
use SOAP::Lite;
use XML::LibXML;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use MOBY::Async::Service;

use Data::Dumper;

######-------USER CONFIGURABLE PARAMETERS-------######
# how long in seconds to wait for a service to respond
my $TIMEOUT = 20;

# the categories of services to unit test
my @CATEGORIES = qw / moby cgi moby-async /;

######-------------------------------------------######

# the registry to query
my $URL = $ENV{MOBY_SERVER} || 'http://moby.ucalgary.ca/moby/MOBY-Central.pl';
my $URI = $ENV{MOBY_URI}    || 'http://moby.ucalgary.ca/MOBY/Central';

# The directory to store the job details
my $CONF = MOBY::Config->new;
my $DIRECTORY = $CONF->{mobycentral}->{service_tester_path} || '/tmp/';

# hashes whose key is the service provider and the value is an array of service names
my %RESULTS  = ();
my $FILENAME = 'unitTestStats.xml';

print "saving results to $DIRECTORY/$FILENAME (if possible)\n";

# a hash of signature urls that we have found and will process
my %signature_urls = ();

# this is just to test if I'm going to have permissions
# right now, rather than an hour from now...  Arghghg!
open( OUT, ">>$DIRECTORY/$FILENAME" )
  || die("Cannot Open File '$DIRECTORY/$FILENAME' $!");
close OUT;

# create the central client and get all service providers once
my $central =
  MOBY::Client::Central->new(
							  Registries => {
											  mobycentral => {
															   URL => $URL,
															   URI => $URI
											  }
							  }
  );
my @providers = $central->retrieveServiceProviders();

# get the signature urls for all services that we are interested in
foreach my $cat (@CATEGORIES) {
	foreach my $authURI (@providers) {
		my ( $second, $minute, $hour, @whatever ) = localtime();
		$hour   = "0$hour"   if $hour <= 9;
		$second = "0$second" if $second <= 9;
		$minute = "0$minute" if $minute <= 9;

		print
"Retrieving signature urls for services registered by '$authURI' as '$cat' @ $hour:$minute:$second\n";
		my ( $services, $reg ) =
		  $central->findService(
								 Registry => "mobycentral",
								 category => $cat,
								 authURI  => $authURI
		  );
		( $second, $minute, $hour, @whatever ) = localtime();
		$hour   = "0$hour"   if $hour <= 9;
		$second = "0$second" if $second <= 9;
		$minute = "0$minute" if $minute <= 9;
		print "Services found "
		  . scalar @$services
		  . "... processing @ $hour:$minute:$second \n";

		my $count = 0;
		print "\tservice count: " . scalar(@$services) . "\n";
		foreach (@$services) {

			# no sig url, then nothing to test
			next unless $_->signatureURL;

			# ignore test services or sig urls we have already processed
			next
			  if $_->authority eq 'samples.jmoby.net'
				  or $signature_urls{ $_->signatureURL };

			# add the sig url to the hash
			$signature_urls{ $_->signatureURL } = 1;
		}

		( $second, $minute, $hour, @whatever ) = localtime();
		$hour   = "0$hour"   if $hour <= 9;
		$second = "0$second" if $second <= 9;
		$minute = "0$minute" if $minute <= 9;
		print
"Retrieved signature urls for '$cat' services from '$authURI' ... completed @ $hour:$minute:$second \n";
	}
}

# now get the services from the signature URL and test them
my $parser = MOBY::RDF::Parsers::ServiceParser->new();
foreach my $sigurl ( keys %signature_urls ) {

	# get the services from the URL
	my $service_arrayref = $parser->getServices($sigurl);
	# call their unit tests
	foreach my $serv ( @{$service_arrayref} ) {
		my $tests = $serv->unitTests;
		next unless $tests;
		foreach my $test (@$tests) {
			if ( $test->xpath or $test->regex or $test->example_input ) {
				my $name  = $serv->name;
				my $auth  = $serv->authority;
				my $url   = $serv->URL;
				my $cat   = $serv->category;
				my $out   = undef;
				my $input = $test->example_input || _empty_input();
				print "\tTesting the service $name from $auth ($cat)...\n";

				# add the authority if not yet in the hash
				$RESULTS{$auth} = ()
				  if not exists $RESULTS{$auth};
				do {
					my $soap =
					  SOAP::Lite->uri("http://biomoby.org/")
					  ->proxy( $url, timeout => $TIMEOUT )->on_fault(
						sub {
							my $soap = shift;
							my $res  = shift;
	
							# record that the service failed the test ...
							push @{ $RESULTS{$auth}{$name} },
							  {
								name   => $name,
								xpath  => 'false',
								regex  => 'false',
								output => 'false'
							  };
							exit(0);
						}
					  );
	
					$out =
					  $soap->$name( SOAP::Data->type( 'string' => "$input" ) )
					  ->result;
				} if $cat eq 'moby';
	
				# test cgi services
				do {
					my $ua = LWP::UserAgent->new;
					$ua->timeout($TIMEOUT);
					my $req = POST $url, [ data => $input ];
					$req = $ua->request($req);
					$out = $req->content if $req->is_success;
					do {
	
						# record that the service failed the test ...
						push @{ $RESULTS{$auth}{$name} },
						  {
							name   => $name,
							xpath  => 'false',
							regex  => 'false',
							output => 'false'
						  };
					} unless $req->is_success;
				} if $cat eq 'cgi';
	
				# test async services
				do {
					
					my $WSDL = $central->retrieveService($serv);
					my $async = MOBY::Async::Service->new(service => $WSDL);
					eval {$out = $async->raw_execute($input);};
					# record that we have an error if we failed the test
					push @{ $RESULTS{$auth}{$name} },
						  {
							name   => $name,
							xpath  => 'false',
							regex  => 'false',
							output => 'false'
						  } if $@;
				} if $cat eq 'moby-async';
	
				# nothing to test unless we have some output
				next unless $out;
	
				# perform the unit tests
				my %unit;
				$unit{name} = $name;
	
				# test regex
				if ( $test->regex ) {
					$unit{regex} = $test->test_regex($out) ? 'true' : 'false';
				}
	
				# test xpath
				if ( $test->xpath ) {
					$unit{xpath} = $test->test_xpath($out) ? 'true' : 'false';
				}
	
				# semantically compare XML
				if ( $test->expected_output ) {
					$unit{output} = $test->test_output_xml($out) ? 'true' : 'false';
				}
				push @{ $RESULTS{$auth}{$name} }, \%unit;
			}
		}
	}
}

# create the XML file that contains our information
my $doc = XML::LibXML::Document->new( "1.0", "UTF-8" );
my $root = $doc->createElement('Services');
$doc->setDocumentElement($root);

# authorities
for my $auth ( sort keys %RESULTS ) {
	my $element = $doc->createElement('authority');
	$element->setAttribute( 'id', $auth );
	my %services = %{ $RESULTS{$auth} };
	next unless %services;
	# service names
	foreach my $service (sort keys %services) {
		my @tests = @{ $services{$service} };
		next unless @tests;
		my $child = $doc->createElement('service');
		$child->setAttribute( 'id', $service );
		my $unitTests = $doc->createElement('UnitTests');
		#array of unit tests
		foreach my $s (@tests) {
			next unless $s;
			my $test =  $doc->createElement('unitTest');
			# sets values to true/false
			$test->setAttribute( 'xpath',  $s->{xpath} )  if $s->{xpath};
			$test->setAttribute( 'regex',  $s->{regex} )  if $s->{regex};
			$test->setAttribute( 'output', $s->{output} ) if $s->{output};
			# add the test to unittests
			$unitTests->appendChild($test);
		}
		# add the unittests to $child
		$child->appendChild($unitTests);
		# append this child
		$element->appendChild($child);
	}
	$root->appendChild($element);
}

# save our XML file
open( OUT, ">$DIRECTORY/$FILENAME" )
  || die("Cannot Open File $DIRECTORY/$FILENAME $!");
print OUT $doc->toString(1);
close OUT;

# empty input for those services that dont consume anything
sub _empty_input {
	return <<'END_OF_XML';
<?xml version="1.0" encoding="UTF-8"?>
<moby:MOBY xmlns:moby="http://www.biomoby.org/moby">
  <moby:mobyContent>
    <moby:mobyData/>
  </moby:mobyContent>
</moby:MOBY>
END_OF_XML
}

