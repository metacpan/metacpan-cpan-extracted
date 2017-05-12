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
use MOBY::Client::SimpleArticle;
#Is the client-code even installed?
BEGIN { use_ok('MOBY::Client::SimpleArticle') };
 
END {
  # Clean up after yourself, in case tests fail, or the interpreter is interrupted partway though...
};

my @autoload = qw/articleName objectType objectLSID namespaces id
  XML XML_DOM isSimple isCollection isSecondary/;
my @API = (@autoload, qw/new addNamespace value /); # createFrom[XML|DOM] are not meant to be public

my $smpl = MOBY::Client::SimpleArticle->new();
foreach (@autoload) {eval{$smpl->$_};} # Call all AUTOLOAD methods, to create them.
can_ok("MOBY::Client::SimpleArticle", @API)
  or diag("SimpleArticle doesn't implement full API");

#my $smpl = MOBY::Client::SimpleArticle->new();
is($smpl->isSimple, 1)     or diag("SimpleArticle must return isSimple=1");
is($smpl->isSecondary, 0)  or diag("SimpleArticle cannot be Secondary");
is($smpl->isCollection, 0) or diag("SimpleArticle cannot be Collection");

my $aName = 'my Article';
is($smpl->articleName($aName), $aName) or diag("Couldn't set articleName");
is($smpl->articleName(), $aName) or diag("Couldn't get articleName");

my $obj_type = 'String';
is($smpl->objectType($obj_type), $obj_type) or diag("Couldn't set objectType");
is($smpl->objectType(), $obj_type) or diag("Couldn't get objectType");

my $obj_lsid = 'String';
is($smpl->objectLSID($obj_lsid), $obj_lsid) or diag("Couldn't set objectLSID");
is($smpl->objectLSID(), $obj_lsid) or diag("Couldn't get objectLSID");

my @ns = qw/SGD FB GO/;
eq_array($smpl->namespaces(\@ns), \@ns) or diag("Couldn't set namespaces");
eq_array($smpl->namespaces(), \@ns) or diag("Couldn't get namespaces");

my $new_ns = 'NCBI_gi';
# Order is critical in this test: FIRST get existing namespaces, THEN add one, and CHECK
eq_array( [@{$smpl->namespaces()}, $new_ns ], $smpl->addNamespace($new_ns))
  or diag("Couldn't add new namespace ('$new_ns')");

# Check XML-generation code.
# In reality, (XML, createFromXML) and (XML_DOM, createFromDOM) should behave the same.
# Let's not assume that though.

my ($artName, $ns, $id, $obj, $lsid) 
  = ('my Article', 'SGD', 'S0005111', 'Object', 'urn:foo:bar:my_lsid');
my $xml_smpl = <<XML;
<Simple lsid='$lsid' articleName='$artName'>
<Object namespace='$ns' id='$id'/>
</Simple>
XML

$smpl = MOBY::Client::SimpleArticle->new( XML => $xml_smpl);

is($smpl->objectLSID(), $lsid)
  or diag("SimpleArticle not correctly built from XML (LSID wrong)");

is($smpl->articleName(), $artName)
  or diag("SimpleArticle not correctly built from XML (articleName wrong)");

is($smpl->objectType(), $obj) 
  or diag("SimpleArticle not correctly built from XML (objectType wrong)");

eq_array($smpl->namespaces(), [$ns])
  or diag("SimpleArticle not correctly built from XML (namespace wrong)");

is($smpl->id(), $id) 
  or diag("SimpleArticle not correctly built from XML (id wrong)");

sub XML_maker { # Turn XML text into DOM.
  my $XML = shift;
  my $parser = XML::LibXML->new();
  my $doc;
  eval { $doc = $parser->parse_string( $XML ); };
  return '' if ( $EVAL_ERROR ); #("Couldn't parse '$XML' because:\n\t$EVAL_ERROR") 
  return $doc->getDocumentElement();
}


$smpl = MOBY::Client::SimpleArticle->new( XML_DOM => XML_maker($xml_smpl));

is($smpl->objectLSID(), $lsid)
  or diag("SimpleArticle not correctly built from XML_DOM (LSID wrong)");

is($smpl->articleName(), $artName)
  or diag("SimpleArticle not correctly built from XML_DOM (articleName wrong)");

is($smpl->objectType(), $obj) 
  or diag("SimpleArticle not correctly built from XML_DOM (objectType wrong)");

eq_array($smpl->namespaces(), [$ns])
  or diag("SimpleArticle not correctly built from XML_DOM (namespace wrong)");

is($smpl->id(), $id) 
  or diag("SimpleArticle not correctly built from XML_DOM (id wrong)");


TODO: {
  local $TODO = <<TODO;
When I call SimpleArticle->new()->XML(\$xml), 
I expect that the XML will be *parsed*, to modify the object, 
not that the attribute 'XML' will be set, and the rest left unchanged."
TODO

  $smpl = MOBY::Client::SimpleArticle->new();
  $smpl->XML($xml_smpl);
  is($smpl->objectLSID(), $lsid)
    or diag("Couldn't create SimpleArticle from autoloaded method XML(): LSID wrong");

  is($smpl->articleName, $artName) 
    or diag("Couldn't create SimpleArticle from autoloaded method XML(): articleName wrong");

  is($smpl->objectType(), $obj) 
    or diag("Couldn't create SimpleArticle from autoloaded method XML(): objectType wrong");

  eq_array($smpl->namespaces(), [$ns])
    or diag("Couldn't create SimpleArticle from autoloaded method XML(): namespaces wrong");

  is($smpl->id(), $id) 
    or diag("Couldn't create SimpleArticle from autoloaded method XML(): id wrong");
}
