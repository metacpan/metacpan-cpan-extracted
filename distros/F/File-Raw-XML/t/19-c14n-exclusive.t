#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# Exclusive XML Canonicalization Version 1.0 (W3C Recommendation, 18 July
# 2002), sections 2.1 and 2.2, transcribed from the Recommendation's text.
# It shows each canonical form "except for line wrapping to fit this
# document": the start tags below are on one line, as canonical XML puts
# them, and the whitespace text is the input's own.

sub exc { my ($n, %o) = @_; $n->c14n(mode => 'exclusive', %o) }
sub inc { my ($n, %o) = @_; $n->c14n(mode => 'inclusive', %o) }

# 2.1 A Simple Example
{
    my $alone = <<'XML';
   <n1:elem1 xmlns:n1="http://b.example">
       content
   </n1:elem1>
XML
    my $enveloped = <<'XML';
   <n0:pdu xmlns:n0="http://a.example">
      <n1:elem1 xmlns:n1="http://b.example">
          content
      </n1:elem1>
   </n0:pdu>
XML
    my $alone_doc = file_xml_decode($alone);
    is($alone_doc->c14n(mode => 'inclusive'),
       qq{<n1:elem1 xmlns:n1="http://b.example">\n       content\n   </n1:elem1>},
       '2.1: the first document is in canonical form');

    my ($elem1) = file_xml_decode($enveloped)->root->elements;
    is(inc($elem1),
       qq{<n1:elem1 xmlns:n0="http://a.example" xmlns:n1="http://b.example">\n          content\n      </n1:elem1>},
       '2.1: Canonical XML of the enveloped elem1 includes n0 from its context');
    is(exc($elem1),
       qq{<n1:elem1 xmlns:n1="http://b.example">\n          content\n      </n1:elem1>},
       '2.1: exclusive canonicalisation of the enveloped elem1 does not');
}

# 2.2 General Problems with re-Enveloping
{
    my $first = <<'XML';
   <n0:local xmlns:n0="foo:bar"
             xmlns:n3="ftp://example.org">
      <n1:elem2 xmlns:n1="http://example.net"
                xml:lang="en">
          <n3:stuff xmlns:n3="ftp://example.org"/>
      </n1:elem2>
   </n0:local>
XML
    my $second = <<'XML';
   <n2:pdu xmlns:n1="http://example.com"
           xmlns:n2="http://foo.example"
           xml:lang="fr"
           xml:space="retain">
      <n1:elem2 xmlns:n1="http://example.net"
                xml:lang="en">
          <n3:stuff xmlns:n3="ftp://example.org"/>
      </n1:elem2>
   </n2:pdu>
XML
    my ($e_first)  = file_xml_decode($first)->root->elements;
    my ($e_second) = file_xml_decode($second)->root->elements;

    is(inc($e_first),
       qq{<n1:elem2 xmlns:n0="foo:bar" xmlns:n1="http://example.net" xmlns:n3="ftp://example.org" xml:lang="en">\n          <n3:stuff></n3:stuff>\n      </n1:elem2>},
       '2.2: Canonical XML of elem2 in the first document: n0 included, n3 elevated to the apex');
    is(inc($e_second),
       qq{<n1:elem2 xmlns:n1="http://example.net" xmlns:n2="http://foo.example" xml:lang="en" xml:space="retain">\n          <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>\n      </n1:elem2>},
       '2.2: Canonical XML of elem2 in the second: n2 appears, n3 is not elevated, xml:space is imported');

    my $exclusive = qq{<n1:elem2 xmlns:n1="http://example.net" xml:lang="en">\n          <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>\n      </n1:elem2>};
    is(exc($e_first),  $exclusive, '2.2: exclusive canonicalisation of elem2 in the first document');
    is(exc($e_second), $exclusive, '2.2: and in the second, the same octets: the property the algorithm exists for');
}

# section 3: a namespace an ancestor had in scope but never rendered is
# rendered where it is first used, not suppressed by the scope above
{
    my ($e) = file_xml_decode('<r xmlns:n3="urn:n3" xmlns:p="urn:p"><p:a><n3:b/></p:a></r>')->root->elements;
    is(exc($e), '<p:a xmlns:p="urn:p"><n3:b xmlns:n3="urn:n3"></n3:b></p:a>',
       'n3 is rendered on the element that uses it, though the apex had it in scope');
    is(inc($e), '<p:a xmlns:n3="urn:n3" xmlns:p="urn:p"><n3:b></n3:b></p:a>',
       'where inclusive renders it on the apex and not below');
}

# the five namespace cases, each against the inclusive output of the same input
{
    my $doc = file_xml_decode('<r xmlns:p="urn:p" xmlns:q="urn:q"><a><p:b/></a></r>');
    my ($a) = $doc->root->elements;
    is(exc($a), '<a><p:b xmlns:p="urn:p"></p:b></a>', 'a prefix declared on an ancestor renders once, where it is used');
    is(inc($a), '<a xmlns:p="urn:p" xmlns:q="urn:q"><p:b></p:b></a>', 'inclusive renders both on the apex');

    my ($pb) = $a->elements;
    is(exc($pb), '<p:b xmlns:p="urn:p"></p:b>', 'declared and unused (q) is omitted; used (p) is kept');
    is(exc($pb, prefix_list => ['q']), '<p:b xmlns:p="urn:p" xmlns:q="urn:q"></p:b>', 'a prefix in the PrefixList is rendered inclusively');
    is(exc($pb, prefix_list => ['nope']), '<p:b xmlns:p="urn:p"></p:b>', 'a PrefixList entry not in scope renders nothing');

    $doc = file_xml_decode('<r xmlns="urn:d"><a xmlns="urn:d"><b/></a></r>');
    ($a) = $doc->root->elements;
    is(exc($a), '<a xmlns="urn:d"><b></b></a>', 'the default redeclared: rendered on the apex, not again below');

    $doc = file_xml_decode('<r xmlns:p="urn:p"><p:a><p:b><p:c/></p:b></p:a></r>');
    ($a) = $doc->root->elements;
    is(exc($a), '<p:a xmlns:p="urn:p"><p:b><p:c></p:c></p:b></p:a>', 'a child using the apex\'s prefix renders it on the apex only');

    $doc = file_xml_decode('<r xmlns:a="urn:a"><e a:x="1"/></r>');
    my ($e) = $doc->root->elements;
    is(exc($e), '<e xmlns:a="urn:a" a:x="1"></e>', 'a prefix used only by an attribute is visibly utilised');
}

# the default namespace and #default
{
    my $doc = file_xml_decode('<r xmlns="urn:d"><a><p:b xmlns:p="urn:p"/></a></r>');
    my ($a) = $doc->root->elements;
    is(exc($a), '<a xmlns="urn:d"><p:b xmlns:p="urn:p"></p:b></a>', 'an unprefixed apex utilises the default');
    my ($pb) = $a->elements;
    is(exc($pb), '<p:b xmlns:p="urn:p"></p:b>', 'a prefixed apex does not, so the default is not rendered');
    is(exc($pb, prefix_list => ['#default']), '<p:b xmlns="urn:d" xmlns:p="urn:p"></p:b>', 'unless #default is in the PrefixList');

    $doc = file_xml_decode('<r xmlns="urn:d"><a xmlns=""><b/></a></r>');
    ($a) = $doc->root->elements;
    is(exc($a), '<a><b></b></a>', 'xmlns="" on the apex renders nothing: no ancestor rendered a default');
    is(exc($doc->root), '<r xmlns="urn:d"><a xmlns=""><b></b></a></r>', 'and is rendered once where a rendered default is undone');

    $doc = file_xml_decode('<r xmlns="urn:d"><p:a xmlns:p="urn:p"><b/></p:a></r>');
    my ($pa) = $doc->root->elements;
    is(exc($pa), '<p:a xmlns:p="urn:p"><b xmlns="urn:d"></b></p:a>', 'the default is rendered on the first unprefixed element below a prefixed apex');
}

# no xml: inheritance, and comments
{
    my $doc = file_xml_decode('<r xml:lang="en" xml:space="preserve" xml:base="x/"><e/></r>');
    my ($e) = $doc->root->elements;
    is(exc($e), '<e></e>', 'exclusive imports no xml: attribute onto the apex');
    is(inc($e), '<e xml:base="x/" xml:lang="en" xml:space="preserve"></e>', 'inclusive imports them all');
    is(exc(file_xml_decode('<r><!-- c --><e/></r>')->root, comments => 1), '<r><!-- c --><e></e></r>', 'comments are rendered when asked');
}

# without: the enveloped signature under an assertion apex
{
    my $xml = <<'XML';
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <saml:Assertion ID="_a1">
    <saml:Issuer>https://idp.example</saml:Issuer>
    <ds:Signature><ds:SignedInfo/><ds:SignatureValue>x</ds:SignatureValue></ds:Signature>
    <saml:Subject><saml:NameID>jo</saml:NameID></saml:Subject>
  </saml:Assertion>
</samlp:Response>
XML
    my $doc = file_xml_decode($xml, id_attrs => ['ID']);
    my $assertion = $doc->by_id(ID => '_a1');
    my ($sig) = $assertion->find('http://www.w3.org/2000/09/xmldsig#', 'Signature');
    my $expected = qq{<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_a1">\n    <saml:Issuer>https://idp.example</saml:Issuer>\n    \n    <saml:Subject><saml:NameID>jo</saml:NameID></saml:Subject>\n  </saml:Assertion>};
    is(exc($assertion, without => [$sig]), $expected,
       'the assertion without its signature: samlp and ds are not rendered, the signature leaves its whitespace neighbours');

    # the extract-and-reparse property: the same bytes from the assertion in
    # place and from its own canonical output parsed alone
    my $again = file_xml_decode(exc($assertion, without => [$sig]))->root;
    is(exc($again), $expected, 'canonicalising the canonical output gives the same octets');

    # with the signature, and its prefix declared where it is used
    like(exc($assertion), qr{<ds:Signature xmlns:ds="http://www\.w3\.org/2000/09/xmldsig#"><ds:SignedInfo></ds:SignedInfo>}, 'with the signature, ds is declared on the Signature element');
}

# the default mode is exclusive
{
    my ($e) = file_xml_decode('<r xmlns:p="urn:p"><a/></r>')->root->elements;
    is($e->c14n, '<a></a>', 'c14n with no options is exclusive');
    is($e->c14n(mode => 'exclusive'), $e->c14n, 'and says so');
}

done_testing;
