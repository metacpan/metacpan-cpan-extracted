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
use MOBY::Client::CollectionArticle;
#Is the client-code even installed?
BEGIN { use_ok('MOBY::Client::CollectionArticle') };
 
END {
  # Clean up after yourself, in case tests fail, or the interpreter is interrupted partway though...
};


my @autoload = qw/articleName Simples isSimple isCollection isSecondary XML XML_DOM/;

my @API = (@autoload, qw/new createFromXML createFromDOM addSimple/);
my $coll = MOBY::Client::CollectionArticle->new();
foreach (@autoload) {eval{$coll->$_};} # Call all AUTOLOAD methods, to create them.
can_ok("MOBY::Client::CollectionArticle", @API)
  or diag("CollectionArticle doesn't implement full API");

is($coll->isSimple, 0) or diag("CollectionArticle cannot be Simple");
is($coll->isSecondary, 0) or diag("CollectionArticle cannot be Secondary");
is($coll->isCollection, 1) or diag("CollectionArticle must return isCollection=1");

my $aName = 'my Article';
# Check XML-generation code.
# In reality, (XML, createFromXML) and (XML_DOM, createFromDOM) should behave the same.
# Let's not assume that though.

my ($artName, $ns, $id, $obj, $lsid) 
  = ('my Simple Article', 'SGD', 'S0005111', 'Object', 'urn:foo:bar:my_lsid');
my ($collArtName) = "my Collection";
my $xml_coll = <<XML;
<Collection articleName='$collArtName'>
<Simple lsid='$lsid' articleName='$artName'>
<Object namespace='$ns' id='$id'/>
</Simple>
<Simple lsid='$lsid' articleName='$artName'>
<Object namespace='$ns' id='$id'/>
</Simple>
</Collection>
XML

$coll = MOBY::Client::CollectionArticle->new( XML => $xml_coll);

is($coll->articleName(), $collArtName)
  or diag("CollectionArticle not correctly built from XML (articleName wrong)");

is(scalar @{$coll->Simples()}, 2) 
  or diag("CollectionArticle didn't return correct number of Simples");

TODO: {
  local $TODO  = "We should ideally check the contents of the Simples that are returned....";
}

sub XML_maker { # Turn XML text into DOM.
  my $XML = shift;
  my $parser = XML::LibXML->new();
  my $doc;
  eval { $doc = $parser->parse_string( $XML ); };
  return '' if ( $EVAL_ERROR ); #("Couldn't parse '$XML' because:\n\t$EVAL_ERROR") 
  return $doc->getDocumentElement();
}


$coll = MOBY::Client::CollectionArticle->new( XML_DOM => XML_maker($xml_coll));

is($coll->articleName(), $collArtName)
  or diag("CollectionArticle not correctly built from XML_DOM (articleName wrong)");



TODO: {
  local $TODO = <<TODO;
When I call CollectionArticle->new()->XML(\$xml), 
I expect that the XML will be *parsed*, to modify the object, 
not that the attribute 'XML' will be set, and the rest left unchanged."
TODO

  $coll = MOBY::Client::CollectionArticle->new();
  $coll->XML($xml_coll);
  is($coll->articleName, $collArtName) 
    or diag("Couldn't create CollectionArticle from autoloaded method XML(): articleName wrong");

}
