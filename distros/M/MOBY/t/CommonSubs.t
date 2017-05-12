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
use Test::More 'no_plan'; #skip_all => "Turned off for development"; #'no_plan';
use strict;

use FindBin qw ($Bin);
use lib "$Bin/../lib/";

use English;
use Data::Dumper;
#Is the client-code even installed?
BEGIN { use_ok('MOBY::CommonSubs') };
use MOBY::CommonSubs qw/:all/;
use XML::LibXML;
use MOBY::MobyXMLConstants;

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
};


my @must_implement = qw/
  serviceInputParser
  serviceResponseParser
  simpleResponse
  collectionResponse
  complexResponse
  isCollectionArticle
  isSecondaryArticle
  isSimpleArticle
  extractRawContent
  getCrossReferences
  getNodeContentWithArticle
  getServiceNotes
  responseFooter
  responseHeader
  validateNamespaces
  validateThisNamespace
  whichDeepestParentObject
/;

can_ok('MOBY::CommonSubs', @must_implement)
  or diag("CommonSubs doesn't implement all the methods that it should");


########   EXTRACT CONTENTS    #########
#my @query_ids = (1, 'a', 23, 24);
#my $msg = <<EOF; # All possible types of input block: (moby:|)(queryInput|mobyData)
#<mobyData queryID='$query_ids[2]'/>
#<moby:mobyData queryID='$query_ids[3]'>foo</moby:mobyData>
#EOF
#
#my @inputs = getInputs(responseHeader() . $msg . responseFooter());
#is(scalar @inputs, scalar @query_ids)
#  or diag("Wrong number of inputs returned from getInputs");
#for (my $i = 0; $i < @query_ids; $i++) {
#  is(getInputID($inputs[$i]), $query_ids[$i])  
#    or diag("Wrong input ID returned for queryID $i: $inputs[$i]");
#}
# This message contains two articles: Collection, and Parameter
# The Collection, of course, contains some Simple Articles, but they are not top-level articles.



my $moby_msg = <<ARTICLES;
<MOBY><mobyContent>
<mobyData queryID="query1">
    <Simple articleName='simple1'>
      <String namespace='firstnamespace' id='mystring'>CONTENT</String>
    </Simple>
    <Collection articleName='collection1'>
      <Simple>
       <Object namespace="blah" id="blah"/>
      </Simple>
      <Simple>
       <Object namespace="blah" id="blah"/>
      </Simple>
    </Collection>
    <Parameter articleName='e value cutoff'>
       <default>10</default>
    </Parameter>
</mobyData></mobyContent></MOBY>
ARTICLES

my $responses = serviceResponseParser($moby_msg); # returns MOBY objects
isa_ok ($responses, "HASH", "response parser returned a HASH" ) or die "serviceResponseParser didn't return a hashref\n";
my @ids = keys %{$responses};
ok (scalar(@ids) == 1) or die "serviceResponseParser didn't find right number of invocation messages\n";
ok ($ids[0] eq "query1") or die "service4ResponseParser didn't find the query1 query id\n";

my $this_invocation = $responses->{$ids[0]};
ok ($this_invocation->{'simple1'}) or die "parser didn't find simple article in message\n";
ok ($this_invocation->{'collection1'}) or die "parser didn't find collection article in message\n";
ok ($this_invocation->{'e value cutoff'}) or die "parser didn't find secondary parameter article in message\n";
  
my $simple = $this_invocation->{'simple1'};
my $collection = $this_invocation->{'collection1'};
my $secondary = $this_invocation->{'e value cutoff'};

isa_ok($simple, "MOBY::Client::SimpleArticle") or die "retrieved Simple isn't a MOBY::Client::SimpleArticle object\n";
isa_ok($collection, "MOBY::Client::CollectionArticle") or die "retrieved Collection isn't a MOBY::Client::CollectionArticle Object\n";
isa_ok($secondary, "MOBY::Client::SecondaryArticle") or die "retrieved Secondary isn't a MOBY::Client::SecondaryArticle object\n";
# other tests of the MOBY::Client::*Article should be done in their own test suite

# Test getInputArticles with one, and with more  than one mobyData block.
my $two_mobyDatas = <<INP_ART;
<MOBY xmlns:moby="http://www.biomoby.org/moby">
    <moby:mobyContent>
      <moby:mobyData queryID="first">
          <Simple>
            <Object namespace="blah" id="blah"/>
          </Simple>
      </moby:mobyData>
      <moby:mobyData moby:queryID="second">
          <Simple>
            <Object namespace="blah" id="blah"/>
          </Simple>
      </moby:mobyData>
    </moby:mobyContent>
    </MOBY>
INP_ART

$responses = serviceResponseParser($two_mobyDatas); # returns MOBY objects
isa_ok ($responses, "HASH", "response parser returned a HASH" ) or die "serviceResponseParser didn't return a hashref for multiple input test\n";
@ids = keys %{$responses};
ok (scalar(@ids) == 2) or die "serviceResponseParser didn't find right number of invocation messages when two were passed\n";
ok ($ids[0] eq "first") or die "serviceResponseParser didn't find the first query id\n";
ok ($ids[1] eq "second") or die "serviceResponseParser didn't find the second query id that included a moby: namespace\n";

# pass 2 invalid messages ... should not parse
$two_mobyDatas = <<INP_ART;
<MOBY xmlns:moby="http://www.local/namespace">
    <moby:mobyContent>
      <moby:mobyData queryID="first">
          <Simple>
            <Object namespace="blah" id="blah"/>
          </Simple>
      </moby:mobyData>
      <moby:mobyData moby:queryID="second">
          <Simple>
            <Object namespace="blah" id="blah"/>
          </Simple>
      </moby:mobyData>
    </moby:mobyContent>
    </MOBY>
INP_ART

$responses = serviceResponseParser($two_mobyDatas); # returns MOBY objects
print Dumper($responses);
isa_ok ($responses, "HASH", "response parser returned a HASH" ) or die "serviceResponseParser didn't return a hashref for multiple input test\n";
@ids = keys %{$responses};
ok (scalar(@ids) == 0) or die "serviceResponseParser didn't find right number of invocation messages when two invalid ones were passed\n";



my $sequence = "TAGCTGATCGAGCTGATGCTGA";
my $articlename = "SequenceString";
my $tag = "String";
my $simple_node_with_article = responseHeader() 
  . "<$tag articleName=\"$articlename\">$sequence</$tag>"
  . responseFooter();

TODO: {
# If no articleName is specified, should return root node.
  local $TODO = "getNodeContentWithArticle() with articleName=''";
}
my @nodes = getNodeContentWithArticle(XML_maker($simple_node_with_article),
				      $tag, $articlename);
is(scalar @nodes, 1) or diag("Couldn't find right number of nodes");
is($nodes[0], $sequence) or diag("Couldn't get node content.");

my $servicenotes = "You can put all kinds of useful info here.";
my $servicenotes_msg = <<ARTICLES;
<mobyData>
    <Collection articleName='name1'>
      <Simple>
       <Object namespace="blah" id="blah"/>
       <CrossReference>
         <Object namespace='Global_Keyword' id='bla'/>"
</CrossReference>
foo
      </Simple>
    </Collection>
    <Parameter articleName='e value cutoff'>
       <default>10</default>
    </Parameter>
<serviceNotes><Notes>$servicenotes</Notes></serviceNotes>
</mobyData>
ARTICLES

is(getServiceNotes(responseHeader() . $servicenotes_msg . responseFooter()),
   $servicenotes)
  or diag("Couldn't get services notes from message");

#what we encode we should be able to decode again
my @ex1=(
-exceptionmessage=>"hello",
-severity=>"warning",
-exceptioncode=>999,
-refelement=>1,
-refqueryid=>"input1");

my @ex2=(
-exceptionmessage=>"hello2",
-severity=>"warning2",
-exceptioncode=>111,
-refelement=>2,
-refqueryid=>"input2");


my @except=getExceptions(responseHeader(-authority=>"illuminae.com",
					-notes=>$servicenotes,
					-exception=>encodeException(@ex1).
					encodeException(@ex2)).
			responseFooter());
is (scalar (@except),2) or diag("Could not extract all exceptions");
is ($except[0]->{exceptionMessage}.$except[0]->{severity}.$except[0]->{exceptionCode}.
		$except[0]->{refQueryID}.$except[0]->{refElement},
		"hellowarning999input11") or diag("Could not extract complete exceptions");


my $xref_msg = <<XREF;
<Simple>
   <String namespace="taxon" id="foo">
   <CrossReference>
     <Object namespace='Global_Keyword' id='bla'/>"
   </CrossReference>
   <CrossReference>
     <Object namespace='Global_Keyword' id='bar'/>"
   </CrossReference>
   foo
</String>
</Simple>
XREF

is (scalar getCrossReferences($xref_msg), 2)
  or diag("Couldn't extract CrossReferences.");

is (scalar getCrossReferences(XML_maker($xref_msg)), 2)
  or diag("Couldn't extract CrossReferences (XML mode).");

####### TEST IDENTITY & VALIDATE   #########
# Since allowed inputs are both XML text, and XML::DOM elements,
# we need to test on both.
# Wrap messages as response so that namespaces are properly defined.

sub XML_maker { # Turn XML text into DOM.
  my $XML = shift;
  my $parser = XML::LibXML->new();
  my $doc;
  eval { $doc = $parser->parse_string( $XML ); };
  if ($EVAL_ERROR) {
    my ($package, $filename, $line) = caller;
    die "XML_maker called from line $line:Couldn't parse '$XML' because:\n\t"
      . "$EVAL_ERROR";
  }
  return $doc->getDocumentElement();
}

# Check simple text format: No namespaces allowed (i.e., no "moby:" prefix)
my @simples = ("<Simple/>", "<Simple>foo</Simple>");
foreach (@simples) { 
  is(isSimpleArticle($_), 1) or diag("Not a SimpleArticle ($_)");
  is(isSimpleArticle(XML_maker($_)), 1) or diag("Not XML for SimpleArticle");
}

my @collections = ("<Collection/>", "<Collection>foo</Collection>");
foreach (@collections) { 
  is(isCollectionArticle($_), 1) or diag("Not a CollectionArticle ($_)");
  is(isCollectionArticle(XML_maker($_)), 1) or diag("Not XML for CollectionArticle");
}

my @parameters = ("<Parameter/>", "<Parameter>foo</Parameter>");
foreach (@parameters) {
  is(isSecondaryArticle($_), 1) or diag("Not a SecondaryArticle ($_)");
  is(isSecondaryArticle(XML_maker($_)), 1) or diag("Not XML for SecondaryArticle");
}

# Now check that other messages fail each of those tests:
# We should test for the empty string, for various misspellings of valid parameters, 
# and for completely fictitious parameters.
# Examples here should be syntactically correct (namespace should be correct)
# just wrong article-types.
my @not_articles = ("<Param/>", "<Paramater>foo</Paramater>",
		   "<Colection/>", "<Single/>", "<Colletion/>");
for my $a (@not_articles) {
  for my $test (\&isSimpleArticle, \&isCollectionArticle, \&isSecondaryArticle) {
    isnt($test->($a), 1) or diag("Non-article '$a' passed as valid article");
    isnt($test->(XML_maker($a)), 1) 
      or diag("Non-article XML '$a' passed as valid article");
  }
}
# Check that bona-fide namespaces are valid, regardless of position in the list of valid namespaces
my @ns = ('Rub1', 'Rub2');
foreach (@ns) {
  ok (validateThisNamespace($_, @ns), "Validate namespace")
    or diag("Namespace ($_) not in list of namespaces");
  ok (validateThisNamespace($_, \@ns), "Validate namespace")
    or diag("Namespace ($_) not in listref of namespaces");
}

# Check that bogus namespaces are not valid.
ok(!validateThisNamespace('Non-existent namespace', @ns))
  or diag("Invalid namespace was incorrectly validated (list of namespaces)");

ok(!validateThisNamespace('Non-existent namespace', \@ns))
  or diag("Invalid namespace was incorrectly validated (listref of namespaces)");

# Check that bona-fide namespaces have an LSID,
# and that bogus ones do NOT.
my @LSIDs = validateNamespaces('bogus-ns', @ns, 'other bogus-ns');
foreach ($LSIDs[0], $LSIDs[-1]) {
  is($_, undef,"validate namespace lsids") or diag("Bogus namespace ($LSIDs[0]) got an LSID");
}
foreach (@LSIDs[1..-2]) {
  isnt($_, undef, "validate namespace lsids2") or diag("Bona fide namespace ($_) had no LSID");
}

######## GENERATE RESPONSE    #########

# Simple response should be mobyData containing Simple, 
my ($data, $articleName, $qID) = ('my response', 'foo', 1);
my $sresp = XML_maker(responseHeader() # Need header for namespace def
		      . simpleResponse($data, $articleName, $qID)
		      . responseFooter());
$sresp = $sresp->getElementsByTagName('moby:mobyData');
#  || $sresp->getElementsByTagName('mobyData');
is($sresp->size(), 1,"response size OK")
  or diag("SimpleResponse should contain only a single mobyData element.");
my $mobyData = $sresp->get_node(1);
is($mobyData->getAttribute('moby:queryID') || $mobyData->getAttribute('queryID'), 
   $qID)
  or diag("SimpleResponse didn't contain right queryID");

my $count_elements = 0;
foreach ($mobyData->childNodes->get_nodelist) { 
  if ($_->nodeType == ELEMENT_NODE) { $count_elements++ }
}
is($count_elements, 1)
  or diag("SimpleResponse's mobyData should have only a single child element:");
#ok($simple->nodeName =~ /(moby\:|)Simple/)
#  or diag("SimpleResponse's only child must be (moby:)Simple");

# Check for correct behavior with empty simpleResponse() too.
$sresp = simpleResponse('', '', $qID);
ok($sresp =~ /\<moby\:mobyData moby\:queryID='$qID'\/>/)
  or diag("SimpleResponse not correctly formed (articleName/data deliberately missing, should give empty mobyData).");

TODO: {
  local $TODO = "Need tests for collectionResponse and complexResponse";
# complexResponse takes two arguments: $data, $qID
# $data is arrayref, elements can also be arrayref, or string.
#my $data = '';

}
{
  # collectionResponse takes 3 args: $data, $articlename, $qID
  # $data is a arrayref of MOBY OBjects as raw XML.
  my ($qID, $aname, $ns, $id, $string) = ("23", "my_artIcLe", "taxon", "foo", "some_text");
  my $simple = "<String namespace='$ns' id='$id'>$string</String>";
  my $data = [$simple, $simple, $simple];
  my $coll_resp = collectionResponse($data, $aname, $qID);

   # Regular expressions are not the best way (!) to validate XML, but it's worth a quick check.
  ok($coll_resp =~ /^\s* \<moby\:mobyData \s+ 
moby\:queryID \s* = \s* ['"]$qID['"] \s* \> # Top-level tag should be mobyData
\s* \<moby\:Collection \s+ moby\:articleName \s* = \s* ['"]$aname['"] \s* \>
.* # Don't worry too much about the innermost details - we'll get them with DOM.
\s* \<\/moby\:Collection\>
\s* \<\/moby\:mobyData\> \s* $/sx) 
    # In above regexpt, 's' allows matching in multiline strings;
    # 'x' ignores comments and literal whitespace in regexp
    # Because we attempt to return 'pretty' XML, we need to allow for whitespace between all tags,
    # which explains why the regexp is peppered with '\s*'
    or diag("collectionResponse should have mobyData as outermost tag: got '$coll_resp'");
  # Now parse the XML, and make sure it checks out according to DOM
  my $coll_resp_dom = XML_maker(responseHeader() . $coll_resp . responseFooter());
  my $mData = $coll_resp_dom->getElementsByLocalName('mobyData');
  is($mData->size(), 1,"collection response size is correct")
    or diag("CollectionResponse should contain only a single mobyData element.");
  $mData = $mData->get_node(1);
  is($mData->getAttribute('moby:queryID') || $mData->getAttribute('queryID'),
     $qID)
    or diag("CollectionResponse's mobyData element didn't contain correct queryID");
  my $colls = $mData->getElementsByLocalName("Collection");
  is ($colls->size(), 1,"collection has wrong number of children")
    or diag("CollectionResponse should have only a single child: Collection.");
  my $Coll = $colls->get_node(1);
  is($Coll->getAttribute('moby:articleName') || $Coll->getAttribute('articleName'),
     $aname)
    or diag("CollectionResponse didn't contain correct articleName");
  my $simples = $Coll->getElementsByTagName("moby:Simple")
    || $Coll->getElementsByTagName("Simple");
  is(scalar @{$simples}, scalar @{$data})
    or diag("CollectionResponse contains wrong number of Simples");

  #  # Finally, parse the sucker with the tools in CommonSubs: it should be able to understand its own creations!
  my $inputs = serviceInputParser(responseHeader() . $coll_resp . responseFooter() );

ok (scalar(keys %{$inputs}) == 1) or diag("can't eat my own dogfood!");

# Test response when one or more simples are empty/undef. 
# They should result in empty Simple tags, but the total response should NOT be empty.
  $coll_resp = collectionResponse([], $aname, $qID);
  ok($coll_resp =~ /^\s*\<moby\:mobyData\s+moby\:queryID\s*=['"]$qID['"]\s*\/\>$/)
    or diag("CollectionResponse should be empty mobyData tag when empty data supplied");
  $data = [undef, $simple, $simple];
  $coll_resp = collectionResponse($data, $aname, $qID);
  ok( !($coll_resp =~ /^\s*\<moby\:mobyData\s+moby\:queryID\s*=['"]$qID['"]\s*\/\>$/sx))
    or diag("CollectionResponse should not be empty "
	    . "just because first element evaluates to false");
}

#------------------
# Check header/footer
# How can we parse incomplete XML for correctness....?
my ($authURI, $service_notes) = ("your.site.here", 
				 "This message brought to you by our sponsors.");
my $header = responseHeader(-authority => $authURI,
			    -note => $service_notes);
ok( $header =~ /^<\?xml version='1.0' encoding='UTF-8'\?><moby\:MOBY xmlns\:moby='http\:\/\/www.biomoby.org\/moby' xmlns='http\:\/\/www.biomoby.org\/moby'><moby\:mobyContent moby\:authority='$authURI'><moby\:serviceNotes>.*<\/moby\:serviceNotes>$/)
  or diag("responseHeader incorrect ($header)");

my $footer = responseFooter();
ok ($footer =~ /^\s*<\/moby\:mobyContent>\s*<\/moby\:MOBY>\s*$/m )
  or diag("responseFooter incorrect");

# Put header and footer together, should be valid XML.
#ok($header . $footer)

