# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# Note added by Frank Gibbons.
# Tests should, as far as possible, avoid the use of literals.
# If you register a service with authURI => mysite.com,
# and you want to test a retrieved description of the service, don't test that the service returns authURI eq "mysite.com",
# test so that it returns the same value as you used to register it in the first place.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use SOAP::Lite +trace;
use Test::More 'no_plan'; # perldoc Test::More for details
use strict;
use Data::Dumper;
#Is the client-code even installed?
BEGIN { use_ok('MOBY::CrossReference') };
 
END {
  # Clean up after yourself, in case tests fail, or the interpreter is interrupted partway though...
};

my @autoload = qw//; # There are none
my @API = qw/ new Object type namespace id authURI
  serviceName evidence_code xref_type /;
can_ok("MOBY::CrossReference", @API) or diag("Full API not implemented");

is(MOBY::CrossReference->new(), undef)
  or diag("Must provide at least type, namespace, and id for CrossReference");

my ($type, $ns, $id) = ("object", "SGD", "S0005111");
my $xref = MOBY::CrossReference->new( type      => $type,
				      namespace => $ns,
				      id        => $id);
isa_ok($xref, "MOBY::CrossReference") or diag("Something's wrong with new()");

is($xref->type(), $type) or diag("CrossReference returned wrong type");
my $new_type = "xref";
isnt($xref->type($new_type), $new_type) or diag("Couldn't set type");
is($xref->type(), $new_type) or diag("Couldn't get type");
my $invalid_type = "neither_object_nor_xref";
isnt($xref->type($invalid_type), $invalid_type)
  or diag("Shouldn't have been allowed to set type to '$invalid_type'");
isnt($xref->type($invalid_type), $invalid_type) 
  or diag("Shouldn't have been allowed to set type to '$invalid_type'");

is($xref->namespace(), $ns) or diag("CrossReference returned wrong namespace");

is($xref->id(), $id) or diag("CrossReference returned wrong id");
my $new_id = "S0002211";
isnt($xref->id($new_id), $new_id) or diag("Couldn't set id");
is($xref->id(), $new_id) or diag("Couldn't get id");

my ($xref_type, $serviceName, $evidence_code, $authURI)
  = qw/ object myLameService 1 www.mylameaddress.com /;
isnt($xref->xref_type($xref_type), $xref_type) or diag("Couldn't set xref_type");
is($xref->xref_type(), $xref_type) or diag("Couldn't get xref_type");
isnt($xref->serviceName($serviceName), $serviceName)
  or diag("Couldn't set serviceName");
is($xref->serviceName(), $serviceName) or diag("Couldn't get serviceName");
isnt($xref->evidence_code($evidence_code), $evidence_code)
  or diag("Couldn't get evidence_code");
is($xref->evidence_code(), $evidence_code)
  or diag("Couldn't get evidence_code");
isnt($xref->authURI($authURI), $authURI) or diag("Couldn't set authURI");
is($xref->authURI(), $authURI) or diag("Couldn't get  authURI");

# We've screwed around with $xref a lot - let's make it afresh.
$xref = MOBY::CrossReference->new( type      => $type,
				   namespace => $ns,
				   id        => $id);
ok($xref->Object() =~ /^\s*\<moby\:Object\s+moby\:namespace\s*=\s*'$ns'\s+moby\:id\s*=\s*'$id'\s*\/\>/) 
  or diag("Object() returned malformed string." . $xref->Object());

