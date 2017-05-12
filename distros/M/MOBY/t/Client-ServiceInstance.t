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
use MOBY::Client::ServiceInstance;
#Is the client-code even installed?
BEGIN { use_ok('MOBY::Client::ServiceInstance') };
 
END {
  # Clean up after yourself, in case tests fail, or the interpreter is interrupted partway though...
};


TODO: {
  local $TODO = "Everything.";
}

my @API = (qw/new authority name type input output
	   secondary category description registry 
	   XML authoritative URL contactEmail LSID/);

my $si = MOBY::Client::ServiceInstance->new();
foreach (@API) {eval{$si->$_};} # Call all AUTOLOAD methods, to create them.
can_ok("MOBY::Client::ServiceInstance", @API)
  or diag("ServiceInstance doesn't implement full API");

