#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# Canonical XML 1.0 (W3C Recommendation, 15 March 2001), section 3, the
# examples transcribed from the Recommendation's text - input and expected
# output byte for byte. Where an example carries a document type
# declaration this parser refuses it by design; those are asserted as
# refusals, and where the declaration contributed nothing to the output a
# variant without it is run too, with the derivation stated.

sub c14n {
    my ($xml, %o) = @_;
    my $doc = file_xml_decode($xml);
    return $doc->c14n(mode => 'inclusive', %o);
}
sub refused { my $ok = eval { file_xml_decode($_[0]); 1 }; $ok ? '' : $@ }

# 3.1 PIs, Comments, and Outside of Document Element
{
    my $input = <<'XML';
<?xml version="1.0"?>

<?xml-stylesheet   href="doc.xsl"
   type="text/xsl"   ?>

<!DOCTYPE doc SYSTEM "doc.dtd">

<doc>Hello, world!<!-- Comment 1 --></doc>

<?pi-without-data     ?>

<!-- Comment 2 -->

<!-- Comment 3 -->
XML
    like(refused($input), qr/DOCTYPE/, '3.1 as published carries a DOCTYPE and is refused by design');

    # The declaration names an external DTD a non-validating processor does
    # not read, so removing that one line changes nothing the Recommendation
    # renders. The expected outputs are the Recommendation's, verbatim.
    (my $no_dtd = $input) =~ s/^<!DOCTYPE doc SYSTEM "doc.dtd">\n\n//m;
    my $uncommented = <<'XML';
<?xml-stylesheet href="doc.xsl"
   type="text/xsl"   ?>
<doc>Hello, world!</doc>
<?pi-without-data?>
XML
    my $commented = <<'XML';
<?xml-stylesheet href="doc.xsl"
   type="text/xsl"   ?>
<doc>Hello, world!<!-- Comment 1 --></doc>
<?pi-without-data?>
<!-- Comment 2 -->
<!-- Comment 3 -->
XML
    chomp for $uncommented, $commented;
    is(c14n($no_dtd), $uncommented, '3.1 canonical form (uncommented)');
    is(c14n($no_dtd, comments => 1), $commented, '3.1 canonical form (commented)');
}

# 3.2 Whitespace in Document Content
{
    my $input = <<'XML';
<doc>
   <clean>   </clean>
   <dirty>   A   B   </dirty>
   <mixed>
      A
      <clean>   </clean>
      B
      <dirty>   A   B   </dirty>
      C
   </mixed>
</doc>
XML
    my $expected = <<'XML';
<doc>
   <clean>   </clean>
   <dirty>   A   B   </dirty>
   <mixed>
      A
      <clean>   </clean>
      B
      <dirty>   A   B   </dirty>
      C
   </mixed>
</doc>
XML
    chomp $expected;
    is(c14n($input), $expected, '3.2 whitespace in document content is preserved');
}

# 3.3 Start and End Tags
{
    my $input = <<'XML';
<!DOCTYPE doc [<!ATTLIST e9 attr CDATA "default">]>
<doc>
   <e1   />
   <e2   ></e2>
   <e3    name = "elem3"   id="elem3"    />
   <e4    name="elem4"   id="elem4"    ></e4>
   <e5 a:attr="out" b:attr="sorted" attr2="all" attr="I'm"
       xmlns:b="http://www.ietf.org"
       xmlns:a="http://www.w3.org"
       xmlns="http://example.org"/>
   <e6 xmlns="" xmlns:a="http://www.w3.org">
       <e7 xmlns="http://www.ietf.org">
           <e8 xmlns="" xmlns:a="http://www.w3.org">
               <e9 xmlns="" xmlns:a="http://www.ietf.org"/>
           </e8>
       </e7>
   </e6>
</doc>
XML
    like(refused($input), qr/DOCTYPE/, '3.3 as published carries a DOCTYPE and is refused by design');

    # Without the declaration, e9 has no defaulted attr: the expected output
    # is the Recommendation's with attr="default" removed from e9 and
    # nothing else changed. (The Recommendation's HTML shows a stray space
    # after </e5>; the input has none after its />, so none is expected.)
    (my $no_dtd = $input) =~ s/^<!DOCTYPE[^\n]*\n//;
    my $expected = <<'XML';
<doc>
   <e1></e1>
   <e2></e2>
   <e3 id="elem3" name="elem3"></e3>
   <e4 id="elem4" name="elem4"></e4>
   <e5 xmlns="http://example.org" xmlns:a="http://www.w3.org" xmlns:b="http://www.ietf.org" attr="I'm" attr2="all" b:attr="sorted" a:attr="out"></e5>
   <e6 xmlns:a="http://www.w3.org">
       <e7 xmlns="http://www.ietf.org">
           <e8 xmlns="">
               <e9 xmlns:a="http://www.ietf.org"></e9>
           </e8>
       </e7>
   </e6>
</doc>
XML
    chomp $expected;
    is(c14n($no_dtd), $expected, '3.3 start and end tags: empty elements, whitespace, declaration and attribute order, superfluous declarations');
}

# 3.4 Character Modifications and Character References
{
    my $input = <<'XML';
<!DOCTYPE doc [
<!ATTLIST normId id ID #IMPLIED>
<!ATTLIST normNames attr NMTOKENS #IMPLIED>
]>
<doc>
   <text>First line&#x0d;&#10;Second line</text>
   <value>&#x32;</value>
   <compute><![CDATA[value>"0" && value<"10" ?"valid":"error"]]></compute>
   <compute expr='value>"0" &amp;&amp; value&lt;"10" ?"valid":"error"'>valid</compute>
   <norm attr=' &apos;   &#x20;&#13;&#xa;&#9;   &apos; '/>
   <normNames attr='   A   &#x20;&#13;&#xa;&#9;   B   '/>
   <normId id=' &apos;   &#x20;&#13;&#xa;&#9;   &apos; '/>
</doc>
XML
    like(refused($input), qr/DOCTYPE/, '3.4 as published carries a DOCTYPE and is refused by design');

    # The declaration types normNames and normId, and their normalisation
    # depends on it, so those two elements are left out; the five that
    # remain are typed CDATA with or without a declaration, and their
    # expected lines are the Recommendation's, verbatim.
    my $subset = <<'XML';
<doc>
   <text>First line&#x0d;&#10;Second line</text>
   <value>&#x32;</value>
   <compute><![CDATA[value>"0" && value<"10" ?"valid":"error"]]></compute>
   <compute expr='value>"0" &amp;&amp; value&lt;"10" ?"valid":"error"'>valid</compute>
   <norm attr=' &apos;   &#x20;&#13;&#xa;&#9;   &apos; '/>
</doc>
XML
    my $expected = <<'XML';
<doc>
   <text>First line&#xD;
Second line</text>
   <value>2</value>
   <compute>value&gt;"0" &amp;&amp; value&lt;"10" ?"valid":"error"</compute>
   <compute expr="value>&quot;0&quot; &amp;&amp; value&lt;&quot;10&quot; ?&quot;valid&quot;:&quot;error&quot;">valid</compute>
   <norm attr=" '    &#xD;&#xA;&#x9;   ' "></norm>
</doc>
XML
    chomp $expected;
    is(c14n($subset), $expected, '3.4 character references, CDATA, and attribute value escaping');
}

# 3.5 Entity References: a DTD declares the entities; refused by design
{
    my $input = <<'XML';
<!DOCTYPE doc [
<!ATTLIST doc attrExtEnt ENTITY #IMPLIED>
<!ENTITY ent1 "Hello">
<!ENTITY ent2 SYSTEM "world.txt">
<!ENTITY entExt SYSTEM "earth.gif" NDATA gif>
<!NOTATION gif SYSTEM "viewgif.exe">
]>
<doc attrExtEnt="entExt">
   &ent1;, &ent2;!
</doc>
XML
    like(refused($input), qr/DOCTYPE/, '3.5 entity references need a DTD and are refused by design');
    like(refused("<doc>&ent1;</doc>"), qr/undeclared entity/, 'and without the DTD the entity is undeclared');
}

# 3.6 UTF-8 Encoding: the input is declared ISO-8859-1; refused by design
{
    like(refused(qq{<?xml version="1.0" encoding="ISO-8859-1"?>\n<doc>&#169;</doc>\n}),
         qr/only the UTF-8 encoding is accepted/, '3.6 an ISO-8859-1 input is refused by design');
    is(c14n("<doc>&#169;</doc>"), "<doc>\xC2\xA9</doc>", '3.6 the character reference renders as the two UTF-8 octets C2 A9');
}

# 3.7 Document Subsets: a DTD and an XPath subset; refused by design, and
# the subset omits an intermediate element, which `without` cannot express
{
    my $input = <<'XML';
<!DOCTYPE doc [
<!ATTLIST e2 xml:space (default|preserve) 'preserve'>
<!ATTLIST e3 id ID #IMPLIED>
]>
<doc xmlns="http://www.ietf.org" xmlns:w3c="http://www.w3.org">
   <e1>
      <e2 xmlns="">
         <e3 id="E3"/>
      </e2>
   </e1>
</doc>
XML
    like(refused($input), qr/DOCTYPE/, '3.7 as published carries a DOCTYPE and is refused by design');
}

# Under the full profile the declarations are read, and the examples
# produce the Recommendation's bytes as published, with no derivation.
{
    my $full = sub { my ($xml, %o) = @_; file_xml_decode($xml, profile => 'full')->c14n(mode => 'inclusive', %o) };

    # 3.3 as published: e9 gains attr="default" from the ATTLIST
    my $in33 = <<'XML';
<!DOCTYPE doc [<!ATTLIST e9 attr CDATA "default">]>
<doc>
   <e1   />
   <e2   ></e2>
   <e3    name = "elem3"   id="elem3"    />
   <e4    name="elem4"   id="elem4"    ></e4>
   <e5 a:attr="out" b:attr="sorted" attr2="all" attr="I'm"
       xmlns:b="http://www.ietf.org"
       xmlns:a="http://www.w3.org"
       xmlns="http://example.org"/>
   <e6 xmlns="" xmlns:a="http://www.w3.org">
       <e7 xmlns="http://www.ietf.org">
           <e8 xmlns="" xmlns:a="http://www.w3.org">
               <e9 xmlns="" xmlns:a="http://www.ietf.org"/>
           </e8>
       </e7>
   </e6>
</doc>
XML
    my $out33 = <<'XML';
<doc>
   <e1></e1>
   <e2></e2>
   <e3 id="elem3" name="elem3"></e3>
   <e4 id="elem4" name="elem4"></e4>
   <e5 xmlns="http://example.org" xmlns:a="http://www.w3.org" xmlns:b="http://www.ietf.org" attr="I'm" attr2="all" b:attr="sorted" a:attr="out"></e5>
   <e6 xmlns:a="http://www.w3.org">
       <e7 xmlns="http://www.ietf.org">
           <e8 xmlns="">
               <e9 xmlns:a="http://www.ietf.org" attr="default"></e9>
           </e8>
       </e7>
   </e6>
</doc>
XML
    chomp $out33;
    is($full->($in33), $out33, '3.3 as published under full: the defaulted attribute on e9');

    # 3.4 as published: normNames is NMTOKENS and normId is ID, so both
    # collapse, and their lines are the Recommendation's
    my $in34 = <<'XML';
<!DOCTYPE doc [
<!ATTLIST normId id ID #IMPLIED>
<!ATTLIST normNames attr NMTOKENS #IMPLIED>
]>
<doc>
   <text>First line&#x0d;&#10;Second line</text>
   <value>&#x32;</value>
   <compute><![CDATA[value>"0" && value<"10" ?"valid":"error"]]></compute>
   <compute expr='value>"0" &amp;&amp; value&lt;"10" ?"valid":"error"'>valid</compute>
   <norm attr=' &apos;   &#x20;&#13;&#xa;&#9;   &apos; '/>
   <normNames attr='   A   &#x20;&#13;&#xa;&#9;   B   '/>
   <normId id=' &apos;   &#x20;&#13;&#xa;&#9;   &apos; '/>
</doc>
XML
    my $out34 = <<'XML';
<doc>
   <text>First line&#xD;
Second line</text>
   <value>2</value>
   <compute>value&gt;"0" &amp;&amp; value&lt;"10" ?"valid":"error"</compute>
   <compute expr="value>&quot;0&quot; &amp;&amp; value&lt;&quot;10&quot; ?&quot;valid&quot;:&quot;error&quot;">valid</compute>
   <norm attr=" '    &#xD;&#xA;&#x9;   ' "></norm>
   <normNames attr="A &#xD;&#xA;&#x9; B"></normNames>
   <normId id="' &#xD;&#xA;&#x9; '"></normId>
</doc>
XML
    chomp $out34;
    is($full->($in34), $out34, '3.4 as published under full: the typed attributes collapse');

    # 3.5 as published needs ent2 from world.txt, an external entity, which
    # no parse reads without a resolver; the refusal names it.
    # With ent2 declared internally as the text the Recommendation says
    # world.txt holds, the output is the Recommendation's.
    my $in35 = <<'XML';
<!DOCTYPE doc [
<!ATTLIST doc attrExtEnt ENTITY #IMPLIED>
<!ENTITY ent1 "Hello">
<!ENTITY ent2 SYSTEM "world.txt">
<!ENTITY entExt SYSTEM "earth.gif" NDATA gif>
<!NOTATION gif SYSTEM "viewgif.exe">
]>
<doc attrExtEnt="entExt">
   &ent1;, &ent2;!
</doc>
XML
    ok(!eval { file_xml_decode($in35, profile => 'full'); 1 }, '3.5 as published refers to an external entity');
    like($@, qr/external entity cannot be read without a resolver/, 'which needs a resolver');
    (my $in35i = $in35) =~ s/<!ENTITY ent2 SYSTEM "world.txt">/<!ENTITY ent2 "world">/;
    my $out35 = <<'XML';
<doc attrExtEnt="entExt">
   Hello, world!
</doc>
XML
    chomp $out35;
    is($full->($in35i), $out35, '3.5 with ent2 internal: entity references become their text, the ENTITY attribute is a value');

    # 3.6 as published: the ISO-8859-1 input is transcoded, and the
    # character reference renders as the two UTF-8 octets
    is($full->(qq{<?xml version="1.0" encoding="ISO-8859-1"?>\n<doc>&#169;</doc>\n}), "<doc>\xC2\xA9</doc>", '3.6 as published under full');

    # 3.7 as published: e2's xml:space is defaulted, and the Recommendation's
    # subset keeps e3 without e2, so e3 inherits xml:space from an ancestor
    # outside the output. The subset omits an intermediate element, which
    # `without` cannot express, so the assertion is over e3 as an apex:
    # its rendering carries the inherited default exactly as the
    # Recommendation's output shows it on e3.
    my $in37 = <<'XML';
<!DOCTYPE doc [
<!ATTLIST e2 xml:space (default|preserve) 'preserve'>
<!ATTLIST e3 id ID #IMPLIED>
]>
<doc xmlns="http://www.ietf.org" xmlns:w3c="http://www.w3.org">
   <e1>
      <e2 xmlns="">
         <e3 id="E3"/>
      </e2>
   </e1>
</doc>
XML
    my $doc37 = file_xml_decode($in37, profile => 'full');
    my ($e1) = $doc37->root->elements;
    my ($e2) = $e1->elements;
    my ($e3) = $e2->elements;
    is($e2->attr_ns('http://www.w3.org/XML/1998/namespace', 'space'), 'preserve', '3.7: e2 carries the defaulted xml:space');
    is($e3->c14n(mode => 'inclusive'), '<e3 xmlns:w3c="http://www.w3.org" id="E3" xml:space="preserve"></e3>',
       '3.7: e3 as an apex inherits the defaulted xml:space, as the Recommendation renders it');
    is($e1->c14n(mode => 'inclusive', without => [$e2]), qq{<e1 xmlns="http://www.ietf.org" xmlns:w3c="http://www.w3.org">\n      \n   </e1>},
       '3.7: without e2 drops e3 with it, which is why the published subset is not expressible');
}

# inclusive namespace rendering beyond the Recommendation's examples
{
    is(c14n('<r xmlns:p="urn:p"><a><p:b/></a></r>'),
       '<r xmlns:p="urn:p"><a><p:b></p:b></a></r>',
       'a prefix declared on an ancestor renders once, where it was declared');
    is(c14n('<r xmlns:p="urn:p"><a/></r>'),
       '<r xmlns:p="urn:p"><a></a></r>',
       'a declared and unused prefix is rendered anyway: that is inclusive');
    is(c14n('<r xmlns="urn:a"><b xmlns="urn:a"/><c xmlns="urn:b"/></r>'),
       '<r xmlns="urn:a"><b></b><c xmlns="urn:b"></c></r>',
       'a redeclaration with the same value is superfluous; a different one is kept');
    is(c14n('<r><a xmlns=""/></r>'),
       '<r><a></a></r>',
       'xmlns="" with no default above is not rendered');
    is(c14n('<r xmlns="urn:a"><a xmlns=""><b/></a></r>'),
       '<r xmlns="urn:a"><a xmlns=""><b></b></a></r>',
       'xmlns="" under a non-empty default is rendered, once');
    is(c14n('<r xml:lang="en"/>'), '<r xml:lang="en"></r>', 'the xml prefix is never declared');

    # an element apex renders every in-scope binding
    my $doc = file_xml_decode('<r xmlns:p="urn:p" xmlns:q="urn:q" xmlns="urn:d"><a><p:b/></a></r>');
    my ($a) = $doc->root->elements;
    is($a->c14n(mode => 'inclusive'), '<a xmlns="urn:d" xmlns:p="urn:p" xmlns:q="urn:q"><p:b></p:b></a>',
       'an element apex renders every in-scope binding, sorted with the default first');
    my ($pb) = $a->elements;
    is($pb->c14n(mode => 'inclusive'), '<p:b xmlns="urn:d" xmlns:p="urn:p" xmlns:q="urn:q"></p:b>',
       'even the ones it does not use');
}

# without
{
    my $doc = file_xml_decode('<r><a>1</a><b>2<c>3</c></b><d/></r>');
    my ($a, $b, $d) = $doc->root->elements;
    my ($c) = $b->elements;
    is($doc->root->c14n(mode => 'inclusive', without => [$b]), '<r><a>1</a><d></d></r>', 'without an inner node drops its subtree');
    is($doc->root->c14n(mode => 'inclusive', without => [$a, $d]), '<r><b>2<c>3</c></b></r>', 'without two nodes');
    is($doc->root->c14n(mode => 'inclusive', without => [$c]), '<r><a>1</a><b>2</b><d></d></r>', 'without a leaf inside a kept element');
    is($b->c14n(mode => 'inclusive', without => [$a]), '<b>2<c>3</c></b>', 'a without node outside the apex subtree excludes nothing');
    is($b->c14n(mode => 'inclusive', without => [$b]), '', 'without the apex renders nothing');
    is($doc->c14n(mode => 'inclusive', without => [$doc->root]), '', 'without the root of a document apex renders nothing');
    my $other = file_xml_decode('<x/>');
    ok(!eval { $doc->root->c14n(without => [$other->root]); 1 }, 'a without node from another document croaks');
    like($@, qr/belongs to another document/, 'saying so');
}

# options
{
    my $doc = file_xml_decode('<r/>');
    ok(!eval { $doc->root->c14n(mode => 'sideways'); 1 }, 'an unknown mode croaks');
    like($@, qr/mode must be 'exclusive', 'inclusive' or 'inclusive-1.1'/, 'naming the three');
    ok(!eval { $doc->root->c14n(bogus => 1); 1 }, 'an unknown option croaks');
    like($@, qr/c14n: unknown option 'bogus'/, 'naming it');
    ok(!eval { $doc->root->c14n(without => 'x'); 1 }, 'without must be an arrayref');
    ok(!eval { $doc->root->c14n(prefix_list => 'x'); 1 }, 'prefix_list must be an arrayref');
    ok(!eval { $doc->root->c14n('odd'); 1 }, 'an odd option tail croaks');
    is($doc->root->c14n(mode => 'inclusive', prefix_list => ['x']), '<r></r>', 'prefix_list is accepted and ignored by the inclusive modes');
    ok(!utf8::is_utf8($doc->root->c14n), 'the output is bytes with no character flag');
    is(file_xml_decode("<r>\xC3\xA9</r>")->root->c14n, "<r>\xC3\xA9</r>", 'and non-ASCII comes out as its UTF-8 octets');
}

done_testing;
