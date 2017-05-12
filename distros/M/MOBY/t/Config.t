# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# Note added by Frank Gibbons.
# Tests should, as far as possible, avoid the use of literals.
# If you register a service with authURI => mysite.com,
# and you want to test a retrieved description of the service, 
# don't test that the service returns authURI eq "mysite.com",
# test so that it returns the same value as you used 
# to register it in the first place.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use SOAP::Lite +trace;
use Test::More skip_all => "Required only when you have your own local MOBY Central"; #'no_plan'; # perldoc Test::More for details
use strict;
use Data::Dumper;
#Is the client-code even installed?
BEGIN { use_ok('MOBY::Config') };
 
END {
  # Clean up after yourself, in case tests fail, or the interpreter is interrupted partway though...
};

my @autoload = qw/mobycentral mobyobject mobynamespace mobyservice
mobyrelationship valid_secondary_datatypes primitive_datatypes /;
# MOBY Config file is environment variable MOBY_CENTRAL_CONFIG
my $config = MOBY::Config->new();
foreach (@autoload) {$config->$_()} # Call autoload functions to create them.
my @API = qw/new getDataAdaptor @autoload/;
can_ok("MOBY::Config", @API) or diag("Didn't implement full API");

eq_array( $config->valid_secondary_datatypes,
	  [qw/String Integer DateTime Float/] )
  or diag("Valid secondary datatypes incorrect.");
eq_array( $config->primitive_datatypes, 
	  [qw/String Integer DateTime Float Boolean/])
  or diag("Primitive datatypes incorrect.");

TODO: {
  local $TODO = "Check stuff dealing with environment variable (for local MOBY Central): MOBY_CENTRAL_CONFIG";

}
