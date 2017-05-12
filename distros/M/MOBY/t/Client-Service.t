# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# Note added by Frank Gibbons.
# Tests should, as far as possible, avoid the use of literals.
# If you register a service with authURI => mysite.com,
# and you want to test a retrieved description of the service,
# don't test that the service returns authURI eq "mysite.com",
# test so that it returns the same value as you used to register it in the first place.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use SOAP::Lite +trace;
use Test::More 'no_plan'; # perldoc Test::More for details
use strict;
use English;
use Data::Dumper;
use MOBY::Client::Service;
use MOBY::Client::Central; # Just to find WSDL for services
#Is the client-code even installed?
BEGIN { use_ok('MOBY::Client::Service') };
 
END {
  # Define cleanup of registry, to return it to its 'pristine' state, 
  # so that later attempts to run tests don't run into problems caused 
  # by failure of these tests, or abortion of the test script.
  # Reconnect to MOBY Central here, since other connections 
  # will have gone out of scope by the time we get to this END block.
  # Also can't use %Obj, 
  my $C = MOBY::Client::Central->new();
  my $r = $C->deregisterService( serviceName  => 'myfirstservice',
			      authURI      => 'test.suite.com' );
};


my @autoload = qw/serviceName service uri smessageVersion _soapService/;
my @API = (@autoload, qw/new execute/);
my $service = MOBY::Client::Service->new();
is($service, undef)
  or diag("Created a new service without supplying any WSDL - it ain't right, I tell you!"); # Can't do nothing without WSDL

# Find a service at MOBY Central, try to create a local instance.
my $C = MOBY::Client::Central->new();
my %RegSmpl = ( serviceName  => "myfirstservice",
		serviceType  => "Retrieval",
		authURI      => "test.suite.com",
		contactEmail => 'your@mail.address',
		description  => "this is my first service",
		category     => "moby",
		URL          => "http://illuminae/cgi-bin/service.pl",
		input        => [
				 ['articleName1', [Object => []]], # Simple
				],
		output       => [
				 ['articleName2', [String => []]], # Simple
				],
	      );

# Service name can't start with numeric
my $r = $C->registerService( %RegSmpl );
my ($s, $err) = $C->findService( authURI => 'test.suite.com',
			       name => 'myfirstservice' );
ok($s) or diag("Couldn't retrieve service details from MOBY Central");
ok($$s[0]) or diag("Just registered service, but not found on findService");
my $wsdl = $C->retrieveService($$s[0]);
ok($wsdl =~ /WSDL/) or diag("retrieveService didn't return a WSDL file");
$service = MOBY::Client::Service->new (service => $wsdl);
isa_ok($service, "MOBY::Client::Service")
  or diag("Expected new to return MOBY::Client::Service");

foreach (@autoload) { eval{$service->$_()}; } # Call all autoloads, to create them.
can_ok("MOBY::Client::Service", @API) 
  or diag("MOBY::Client::Service doesn't implement full API.");

# Empty WSDL should cause 'undef' to be returned, rather than empty Service object.
my $emptyWSDL = "";
is(MOBY::Client::Service->new ( service => $emptyWSDL), undef)
  or diag("Expected new to return undef when passed empty WSDL file");


