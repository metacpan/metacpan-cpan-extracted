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
use Test::More 'no_plan'; #skip_all => "Skipped for development"; #'no_plan'; # perldoc Test::More for details
use strict;
use MOBY::Client::OntologyServer;
use MOBY::Client::Central;
BEGIN { use_ok('MOBY::Client::OntologyServer');
      # initialize with a couple of useless things that we can guarantee to find
       my $C = MOBY::Client::Central->new();

      my %Namespace = ( namespaceType => 'Rub1',
                        authURI       => 'your.authority.URI',
                        description   => "human readable description of namespace",
                        contactEmail  => 'your@address.here'
                      );
      my $r = $C->registerNamespace( %Namespace );
      %Namespace = ( namespaceType => 'Rub2',
                        authURI       => 'your.authority.URI',
                        description   => "human readable description of namespace",
                        contactEmail  => 'your@address.here'
                      );
      $r = $C->registerNamespace( %Namespace );
      my %ServiceType = ( serviceType   => "Rub1",
                          description   => "a human-readable description of the service",
                          contactEmail  => 'your@email.address',
                          authURI       => "test.suite.com",
                          Relationships => { ISA => ['Service'] }
                        );
      $r = $C->registerServiceType( %ServiceType );
      %ServiceType = ( serviceType   => "Rub2",
                          description   => "a human-readable description of the service",
                          contactEmail  => 'your@email.address',
                          authURI       => "test.suite.com",
                          Relationships => { ISA => ['Service'] }
                        );
      $r = $C->registerServiceType( %ServiceType );
	  };
  	  

END {
  # Define cleanup of registry, to return it to its 'pristine' state, 
  # so that later attempts to run tests don't run into problems caused 
  # by failure of these tests, or abortion of the test script.
  # Reconnect to MOBY Central here, since other connections 
  # will have gone out of scope by the time we get to this END block.
  # Also can't use %Obj, 
  my $C = MOBY::Client::Central->new();
  my $r = $C->deregisterNamespace( namespaceType => 'Rub1' );
  $r = $C->deregisterNamespace( namespaceType => 'Rub2' );
  $r = $C->deregisterServiceType( serviceType => 'Rub1' );
  $r = $C->deregisterServiceType( serviceType => 'Rub2' );

};


my @autoload = qw/host proxy/;
my @API = (@autoload, qw/new getUserAgent
objectExists serviceExists namespaceExists /);

my $os = MOBY::Client::OntologyServer->new();
diag "\n\nUsing Ontology Server at:  ", $os->host, "\n\n";
if (defined $ENV{TEST_VERBOSE} && $ENV{TEST_VERBOSE} == 1) {
  print STDERR <<END;
    This is the MOBY Client OntologyServer test suite.
    By default this connects to the server at mobycentral.icapture.ubc.ca
    (or whatever the default server is set to in the code)
		
    If you want to test a different server you must set the following
    environment variable:
    MOBY_ONTOLOGYSERVER='http://your.server.name/path/to/OntologyServer.cgi'

    For the following tests I will be using the server at:
END

  print STDERR "\t",$os->host,"\n\n\n";
}

foreach (@autoload) {eval{$os->$_};} # Call all AUTOLOAD methods, to create them.
can_ok("MOBY::Client::OntologyServer", @API)
  or diag("OntologyServer doesn't implement full API");

# Check that accessor methods work correctly;
my ($old_host, $old_proxy) = ($os->host(), $os->proxy());
my ($new_host, $new_proxy) = ("foo.cgi", "bar"); 
is($os->host($new_host), $new_host) or diag("Couldn't set new host");
is($os->host(), $new_host) or diag("Couldn't get host");
is($os->host($old_host), $old_host) or diag("Couldn't return host to previous value");
  is($os->proxy($new_proxy), $new_proxy) or diag("Couldn't set proxy to new value");
  is($os->proxy(), $new_proxy) or diag("Couldn't get proxy");
TODO: {
  local $TODO = "How come I cant' set proxy back to its original value?";
  is($os->proxy($old_proxy), $old_proxy) or diag("Couldn't return proxy to previous value");
}

# Start fresh....
$os = MOBY::Client::OntologyServer->new();

my ($success, $msg, $existingURI);
my @check_ns = qw/Rub1 Rub2/; # These seem pretty solid
foreach (@check_ns) {
 ($success, $msg, $existingURI) = $os->namespaceExists( term => $_);
  is($success, 1)
    or diag("Namespace '$_' reported erroneously as non-existent.");
}

# Could get these allowed datatypes from MOBY::Config,
# except that module only works when you've got a local registry set up.
my @check_obj = qw/ Object String Integer Float DateTime/; # At least we can be confident that primitive types will always be valid
foreach (@check_obj) {
  ($success, $msg, $existingURI) = $os->objectExists(term => $_);
  is($success, 1)
    or diag("Object '$_' reported erroneously as non-existent.");
}

my @check_servicetype = qw/Rub1 Rub2/; # Service types don't change much, but who knows....
foreach (@check_servicetype) {
  ($success, $msg, $existingURI) = $os->serviceExists(term => $_);
  is($success, 1)
    or diag("Service type '$_' reported erroneously as non-existent.");
}

SKIP: {
  skip "relationshipExists not implemented", 5 
    unless MOBY::Client::OntologyServer->can("relationshipExists");

  can_ok("MOBY::Client::OntologyServer", "relationshipExists")
    or diag("OntologyServer should be able to tell whether a relationship exists");
  my @check_rel = qw/ISA HASA HAS/; # There should only be very few valid relationship types.
  foreach (@check_rel) {
    ($success, $msg, $existingURI) = $os->relationshipExists(term => $_, ontology => 'object');
    is($success, 1)
      or diag("Relationship '$_' reported erroneously as non-existent.");
  }
  my @check_rel2 = qw/ISA/; # There should only be very few valid relationship types.
  foreach (@check_rel2) {
    ($success, $msg, $existingURI) = $os->relationshipExists(term => $_, ontology => 'service');
    is($success, 1)
      or diag("Relationship '$_' reported erroneously as non-existent.");
  }
  
  my $invalid_rel = "HA";
  ($success, $msg, $existingURI) = $os->relationshipExists(term => $invalid_rel, ontology => 'service');
  is($success, 0)
    or diag("Relationship '$invalid_rel' reported erroneously as existent.");
  ($success, $msg, $existingURI) = $os->relationshipExists(term => $invalid_rel, ontology => 'object');
  is($success, 0)
    or diag("Relationship '$invalid_rel' reported erroneously as existent.");
}


######### CHECK THAT *IN*VALID STUFF FAILS CORRECTLY ###############
#
# Literal invalid names are OK here, since there's no obvious way to generate them
# and guarantee that they'll be invalid.
#
my $invalid_ns = "InvalidNS";
($success, $msg, $existingURI) = $os->namespaceExists( term => $invalid_ns);
is($success, 0)
  or diag("Namespace '$invalid_ns' reported erroneously as existent.");

my $invalid_obj = "InvalidObject";
($success, $msg, $existingURI) = $os->objectExists(term => $invalid_obj);
is($success, 0)
  or diag("Object '$invalid_obj' reported erroneously as existent.");

my $invalid_st = "InvalidServiceType";
($success, $msg, $existingURI) = $os->serviceExists(term => $invalid_st);
is($success, 0)
  or diag("Service type '$invalid_st' reported erroneously as existent.");

