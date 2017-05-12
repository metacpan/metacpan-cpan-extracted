# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# !!!!STOP!!!!
# This test file is for the MOBY::Central module.
# As a regular Perl user, you probably intend to use MOBY::Client::Central,
# which is discouragingly similarly named, and has many similarly named methods, 
# but quite different functionality.
# This code runs on the server side, responding to incoming requests, 
# and constructing XML messages that communicate the results of those requests.

# Note added by Frank Gibbons.
# Tests should, as far as possible, avoid the use of literals.
# If you register a service with authURI => mysite.com,
# and you want to test a retrieved description of the service, don't test that the service returns authURI eq "mysite.com",
# test so that it returns the same value as you used to register it in the first place.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use SOAP::Lite +trace;
use Test::More 'no_plan';
use strict;
#Is the client-code even installed?
BEGIN { 
  my $missing_modules = <<CLIENT_ONLY;


It appears you are missing one or more modules required to host
your own MOBY Central registry (these are primarily required 
for connecting to a database).

Most likely, you are interested in building a client-side application,
in which case this doesn't matter, and you should ignore this test. 
Other tests should still pass - if not, you need to resolve them.

On the other hand, if you want to build your own local MOBY Central registry,
you should install the missing modules, and re-run the tests.

CLIENT_ONLY

  $ENV{MOBY_CENTRAL_CONFIG} = "./t/mobycentral.config";
# Test that modules required ONLY for local MOBY Central are installed.
  require_ok( "DBI" ) or diag($missing_modules);
  require_ok( "DBD::mysql" ) or diag($missing_modules);
  use_ok('MOBY::Central') or diag("Did you get 'MOBY::Central'? I can' find it.") 
};
END {};

############           ENFORCE REGISTRY API        ###############

# First, mandatory methods for all registries. 
# Notice: new() is NOT defined here, since it is deprecated.
my @API = qw/Registration
registerObjectClass _registerObjectPayload
deregisterObjectClass _deregisterObjectPayload
_testObjectTypeAgainstPrimitives
registerServiceType _registerServiceTypePayload
deregisterServiceType _deregisterServiceTypePayload
retrieveNamespaces _registerNamespacePayload
deregisterNamespace _deregisterNamespacePayload
registerService _registerServicePayload
_getServiceInstanceRDF _registerArticles
deregisterService _deregisterServicePayload
findService _findServicePayload
_extractObjectTypes registerServiceWSDL
_extract_ids
_searchForServicesWithArticle _searchForSimple _searchForCollection
_extractObjectTypesAndNamespaces
retrieveService _retrieveServicePayload
retrieveResourceURLs retrieveServiceProviders retrieveServiceNames
retrieveServiceTypes retrieveRelationshipTypes retrieveObjectNames
retrieveObjectDefinition retrieveNamespaces
retrieveObject _retrieveObjectPayload
Relationships DUMP_MySQL _ISAPayload/;

can_ok("MOBY::Central", @API)
  or diag("MOBY::Central failed to implement full API");

################## MOBY Registration Tests #################

##################    OBJECT REGISTRATION    #############
# Test 3  inherits from two isas - should fail
my %Obj = ( objectType    => "Rubbish",
	    description   => "a human-readable description of the object",
	    contactEmail  => 'your@email.address',
	    authURI       => "test.suite.com",
	    Relationships => {
			      ISA => [
				      ['Object', 'article1'],
				      ['Object', 'articleName2']],
			      HASA => [
				       ['Object', 'articleName3']]
			     }
	  );

