#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# The DOCTYPE and the internal subset under the full profile: every
# declaration kind, attribute defaulting and its order, normalisation by
# type (XML 1.0 section 3.3.3), internal entities in content and in
# attribute values, each well-formedness constraint of sections 2.8, 4.1
# and 4.4 with its offset, and each expansion budget at its edge. Under
# strict, all of it is refused at the offset of the <!.

sub full    { my ($b, %o) = @_; file_xml_decode($b, profile => 'full', %o) }
sub refused { my ($b, %o) = @_; my $ok = eval { full($b, %o); 1 }; $ok ? '' : $@ }
sub attrs   { my ($n) = @_; join ' ', map { "$_->[2]=$_->[3]" } @{ $n->attrs } }

# the deliverable: the plan's own sentence
{
    my $xml = <<'XML';
<!DOCTYPE doc [
<!ELEMENT doc (#PCDATA|e)*>
<!ELEMENT e EMPTY>
<!ATTLIST e id ID #IMPLIED
            kind (a|b) "a"
            fixed CDATA #FIXED "yes">
<!ENTITY greeting "Hello, world">
<!ENTITY nested "<e id='x'/>&greeting;">
<!NOTATION gif SYSTEM "viewgif.exe">
]>
<doc>&greeting;! &nested;</doc>
XML
    my $doc = full($xml);
    is($doc->root->text, 'Hello, world! Hello, world', 'internal entities expand in content, nested ones through a frame');
    my ($e) = $doc->root->elements;
    is(attrs($e), 'id=x kind=a fixed=yes', 'the written attribute, then the defaults in declaration order');
    is($doc->doctype->{name}, 'doc', 'doctype: the name');
    ok(!defined $doc->doctype->{system_id} && !defined $doc->doctype->{public_id}, 'no external ID');
    like($doc->doctype->{internal_subset}, qr/^\n<!ELEMENT doc/, 'the subset text as written');
    is($doc->version, '1.0', 'version');
    is($doc->standalone, 0, 'standalone unsaid is 0');
    ok(!eval { file_xml_decode($xml); 1 }, 'strict refuses it');
    like($@, qr/^File::Raw::XML: DOCTYPE and every other declaration are refused; only comments and CDATA may follow <! at byte offset 0 /, 'at offset 0 with the 0.01 message');
    is(full(qq{<?xml version="1.0" standalone="yes"?><!DOCTYPE d><d/>})->standalone, 1, 'standalone="yes" is recorded');
    ok(!defined full('<d/>')->doctype, 'no DOCTYPE: doctype is undef');
    ok(defined full('<!DOCTYPE d []><d/>')->doctype->{internal_subset}, 'an empty subset is "" not undef');
    ok(!defined full('<!DOCTYPE d><d/>')->doctype->{internal_subset}, 'and no subset is undef');
}

# every declaration kind, and what is ignored
{
    my $doc = full(<<'XML');
<!DOCTYPE r [
  <!-- a comment in the subset is not a node -->
  <?pi in the subset is not a node either?>
  <!ELEMENT r ANY>
  <!ELEMENT a (b, (c | d)*, e?)+>
  <!ELEMENT b (#PCDATA)>
  <!ELEMENT mixed (#PCDATA | a | b)*>
  <!ATTLIST r x CDATA #IMPLIED y NMTOKENS #REQUIRED>
  <!ATTLIST r z (one | two) "two">
  <!ATTLIST r z (three) "three">
  <!ENTITY e "first">
  <!ENTITY e "second">
  <!ENTITY % pe "<!ENTITY viaPe 'through a parameter entity'>">
  %pe;
  <!ENTITY ext SYSTEM "x.txt">
  <!ENTITY pic SYSTEM "x.gif" NDATA gif>
  <!NOTATION gif PUBLIC "-//x//gif//EN">
  <!NOTATION jpg SYSTEM "viewjpg">
  <!ATTLIST r n NOTATION (gif | jpg) #IMPLIED>
]>
<r y=" a  b ">&e; &viaPe;</r>
XML
    is(scalar(() = $doc->document->children), 1, 'the subset\'s comment and PI are not children of the document');
    is($doc->root->text, 'first through a parameter entity', 'the first entity declaration binds; a PE between declarations is expanded');
    is(attrs($doc->root), 'y=a b z=two', 'the first attribute definition binds; #REQUIRED and #IMPLIED add nothing');
}

# attribute defaulting and normalisation by type
{
    my $dtd = <<'XML';
<!DOCTYPE r [
<!ATTLIST r cdata CDATA #IMPLIED
            token NMTOKEN #IMPLIED
            tokens NMTOKENS #IMPLIED
            id ID #IMPLIED
            enum (x|y) #IMPLIED
            dflt CDATA "  d  "
            tdflt NMTOKENS "  d   e  ">
]>
XML
    my $r = full($dtd . qq{<r cdata="  a \t b  " token="  a  " tokens="  a \t b   c  " id=" i " enum=" x "/>})->root;
    is($r->attr('cdata'),  '  a   b  ', 'CDATA: literal whitespace to spaces, nothing collapsed');
    is($r->attr('token'),  'a',         'NMTOKEN: trimmed');
    is($r->attr('tokens'), 'a b c',     'NMTOKENS: runs of spaces collapsed, trimmed');
    is($r->attr('id'),     'i',         'ID: trimmed');
    is($r->attr('enum'),   'x',         'an enumeration: trimmed');
    is($r->attr('dflt'),   '  d  ',     'a CDATA default keeps its spaces');
    is($r->attr('tdflt'),  'd e',       'a tokenised default is collapsed too');
    $r = full($dtd . qq{<r tokens="&#x20; a &#9; b&#x20;"/>})->root;
    is($r->attr('tokens'), "a \t b", 'only literal and referenced #x20 collapse; a referenced tab stays (3.3.3)');
    my $doc = full($dtd . qq{<r id="k"/>}, id_attrs => ['id']);
    ok($doc->by_id(id => 'k'), 'a typed ID is indexed by id_attrs like any other');
    is(full('<!DOCTYPE r><r a="  x  "/>')->root->attr('a'), '  x  ', 'an undeclared attribute is CDATA');

    # XML 1.0 section 3.3.3's own table: the three entities and three
    # attribute values, under CDATA and under NMTOKENS
    my $tbl = <<'XML';
<!DOCTYPE r [
<!ENTITY d "&#xD;">
<!ENTITY a "&#xA;">
<!ENTITY da "&#xD;&#xA;">
<!ATTLIST r c1 CDATA #IMPLIED c2 CDATA #IMPLIED c3 CDATA #IMPLIED
            n1 NMTOKENS #IMPLIED n2 NMTOKENS #IMPLIED n3 NMTOKENS #IMPLIED>
]>
XML
    my $v1 = "\n\nxyz";
    my $v2 = '&d;&d;A&a;&a;B&da;';
    my $v3 = '&#xd;&#xd;A&#xa;&#xa;B&#xd;&#xa;';
    $r = full($tbl . qq{<r c1="$v1" c2="$v2" c3="$v3" n1="$v1" n2="$v2" n3="$v3"/>})->root;
    is($r->attr('c1'), "  xyz",              '3.3.3 table: two literal line feeds, CDATA');
    is($r->attr('n1'), "xyz",                'and NMTOKENS');
    is($r->attr('c2'), "  A  B  ",           'whitespace through entities, CDATA');
    is($r->attr('n2'), "A B",                'and NMTOKENS');
    is($r->attr('c3'), "\r\rA\n\nB\r\n",     'character references, CDATA');
    is($r->attr('n3'), "\r\rA\n\nB\r\n",     'and NMTOKENS: nothing to collapse, since none is #x20');
}

# a defaulted xmlns is a namespace declaration
{
    my $doc = full(<<'XML');
<!DOCTYPE r [
<!ATTLIST r xmlns CDATA "urn:default">
<!ATTLIST p:e xmlns:p CDATA #FIXED "urn:p">
]>
<r><p:e/></r>
XML
    is($doc->root->ns, 'urn:default', 'a defaulted xmlns binds the default namespace');
    my ($e) = $doc->root->elements;
    is($e->ns, 'urn:p', 'a #FIXED xmlns:p binds the prefix of the element it is declared on');
    is($doc->root->c14n, '<r xmlns="urn:default"><p:e xmlns:p="urn:p"></p:e></r>', 'and both render as declarations');
    is(scalar @{ $e->attrs }, 0, 'and neither is an attribute');
}

# entities in attribute values
{
    my $doc = full(<<'XML');
<!DOCTYPE r [
<!ENTITY q '"quoted"'>
<!ENTITY amp2 "&amp;&#38;#38;">
<!ENTITY ws "a&#10;b
c">
<!ATTLIST r d CDATA "&q;">
]>
<r a="&q;" b="&amp2;" c="&ws;"/>
XML
    my $r = $doc->root;
    is($r->attr('a'), '"quoted"', 'a quote inside an entity does not end the value (4.4.5)');
    is($r->attr('b'), '&&', 'a predefined reference in an entity is expanded when the entity is; &#38;#38; is section 4.5\'s own double escape');
    like(refused(qq{<!DOCTYPE r [<!ENTITY bare "&#38;">]><r a="&bare;"/>}), qr/expected a name at byte offset 29 /,
         'and a lone &#38; leaves a bare & in the replacement text, ill-formed when included, as 4.5 warns');
    is($r->attr('c'), "a b c", 'a line feed in the replacement text, referenced or literal, is a space when the entity is used (3.3.3 step 3, the entity case)');
    is($r->attr('d'), '"quoted"', 'a default value expands its references');
    is($r->c14n, qq{<r a="&quot;quoted&quot;" b="&amp;&amp;" c="a b c" d="&quot;quoted&quot;"></r>}, 'canonical form over the result');
}

# each well-formedness constraint, with its offset
{
    my $pre = "<!DOCTYPE r [\n";
    like(refused("<!DOCTYPE r><r>&x;</r>"), qr/undeclared entity at byte offset 15 /, 'WFC: Entity Declared, with a DTD');
    like(refused("<r>&x;</r>"), qr/undeclared entity \(there is no DOCTYPE, so only the five predefined exist\) at byte offset 3 /, 'and without one, the full profile\'s sibling of the strict message');
    like(refused($pre . q{<!ENTITY a "&b;"><!ENTITY b "&a;">]><r>&a;</r>}), qr/refers to itself.*No Recursion.* at byte offset 43 near "&a;/, 'WFC: No Recursion, at the reference inside the entity');
    like(refused($pre . q{<!ENTITY a "&a;">]><r>&a;</r>}), qr/No Recursion.* at byte offset 26 /, 'directly');
    like(refused($pre . q{<!ENTITY a "<x">]><r>&a;</r>}), qr/unterminated start tag at byte offset 26 /, 'WFC: Parsed Entity: a tag that opens in an entity must close in it, reported inside the entity');
    like(refused($pre . q{<!ENTITY a "<x>">]><r>&a;</r>}), qr/opened inside an entity must close inside it.* at byte offset 36 /, 'an element opened in an entity and not closed there, at the reference');
    like(refused($pre . q{<!ENTITY a "</r>">]><r>&a;</r>}), qr/must not close an element opened outside it at byte offset 26 /, 'an end tag in an entity for an element opened outside it');
    like(refused($pre . q{<!ENTITY a "<!-- x ">]><r>&a;--></r>}), qr/unterminated comment at byte offset 26 /, 'a comment must close inside its entity');
    like(refused($pre . q{<!ENTITY a "<">]><r x="&a;"/>}), qr/must not contain < at byte offset 26 /, 'WFC: No < in Attribute Values, through an entity, at the < in its text');
    ok(full($pre . q{<!ENTITY a "&lt;">]><r x="&a;"/>})->root->attr('x') eq '<', 'but &lt; in the entity is a < in the value');
    like(refused($pre . q{<!ENTITY a SYSTEM "a.txt">]><r x="&a;"/>}), qr/must not refer to an external entity.*No External Entity References.* at byte offset 48 /, 'WFC: No External Entity References');
    like(refused($pre . q{<!ENTITY a SYSTEM "a.txt">]><r>&a;</r>}), qr/external entity cannot be read without a resolver; the resolve option .* at byte offset 45 /, 'an external entity in content names the resolver');
    like(refused($pre . q{<!ENTITY a SYSTEM "a.gif" NDATA gif>]><r>&a;</r>}), qr/unparsed entity.*Parsed Entity.* at byte offset 55 /, 'an unparsed entity in content');
    like(refused($pre . q{<!ENTITY a "x">]><r>&a</r>}), qr/malformed entity reference at byte offset 34 /, 'a reference without its ;');
    like(refused($pre . q{<!ENTITY a "x">%a;]><r/>}), qr/undeclared parameter entity at byte offset 29 /, 'a parameter entity reference to a general entity');
    like(refused($pre . q{<!ENTITY % p "x"><!ENTITY a "%p;">]><r/>}), qr/PEs in Internal Subset.* at byte offset 43 /, 'WFC: PEs in Internal Subset, in an entity value');
    like(refused($pre . q{<!ENTITY % p "x"><!ELEMENT r %p;>]><r/>}), qr/PEs in Internal Subset.* at byte offset 43 /, 'in a declaration');
    like(refused($pre . q{<!ENTITY % p SYSTEM "p.dtd">%p;]><r/>}), qr/external entity cannot be read without a resolver.* at byte offset 42 /, 'an external parameter entity between declarations');
    like(refused($pre . q{<![INCLUDE[ <!ELEMENT r ANY> ]]>]><r/>}), qr/conditional section is allowed only in the external subset at byte offset 14 /, 'a conditional section');
    like(refused($pre . q{<!ENTITY % p "]">%p;]><r/>}), qr/must not close the internal subset at byte offset 28 /, 'a ] inside a parameter entity, reported in the entity');
    like(refused(q{<!DOCTYPE r SYSTEM "r.dtd"><r/>}), qr/external subset cannot be read without a resolver; the resolve option .* at byte offset 19 near "\\x22r\.dtd\\x22/, 'an external subset is refused at its system literal');
    like(refused(q{<!DOCTYPE r PUBLIC "-//x//r//EN" "r.dtd"><r/>}), qr/external subset cannot be read without a resolver.* at byte offset 33 /, 'a PUBLIC one at its system literal');
    like(refused(q{<r/><!DOCTYPE r>}), qr/DOCTYPE must precede the root element at byte offset 4 /, 'a DOCTYPE after the root');
    like(refused(q{<!DOCTYPE r><!DOCTYPE r><r/>}), qr/one DOCTYPE, before the root element at byte offset 12 /, 'a second DOCTYPE');
    like(refused(q{<r><!ELEMENT r ANY></r>}), qr/only a DOCTYPE, a comment or CDATA may follow <! here at byte offset 3 /, 'a declaration in content');
    like(refused($pre . q{<!ELEMENT r (a|b,c)>]><r/>}), qr/choice or a sequence, not both at byte offset 30 /, 'a content model group mixing | and ,');
    like(refused($pre . q{<!ELEMENT r (#PCDATA|a)>]><r/>}), qr/must end in \)\* at byte offset 37 /, 'mixed content naming elements without the *');
    like(refused($pre . q{<!ELEMENT r ()>]><r/>}), qr/expected a name at byte offset 27 /, 'an empty group');
    like(refused($pre . q{<!ATTLIST r a CDATA>]><r/>}), qr/expected whitespace before the default declaration at byte offset 33 /, 'an attribute definition with no default');
    like(refused($pre . q{<!ATTLIST r a NOTATION(x) #IMPLIED>]><r/>}), qr/expected whitespace after NOTATION at byte offset 36 /, 'NOTATION run into its parenthesis');
    like(refused($pre . q{<!ENTITY a "x"]><r/>}), qr/unterminated ENTITY declaration at byte offset 14 /, 'a declaration missing its >');
    like(refused($pre . q{<!NOTATION n "x">]><r/>}), qr/expected SYSTEM or PUBLIC at byte offset 27 /, 'a notation with no external ID');
    like(refused($pre . q|<!NOTATION n PUBLIC "a{b">]><r/>|), qr/not a public ID character at byte offset 36 /, 'a public ID character outside section 2.3');
    like(refused($pre . q{<!ENTITY a "x&#1;">]><r/>}), qr/non-XML character at byte offset 27 /, 'a character reference to a non-Char in an entity value');
    like(refused($pre . q{<!ENTITY a "&b">]><r/>}), qr/malformed entity reference at byte offset 26 /, 'a bypassed reference must still be a reference');
    like(refused($pre . q{<!ENTITY a "x">]}), qr/unterminated DOCTYPE at byte offset 0 /, 'a DOCTYPE missing its >');
    like(refused($pre . q{<!ENTITY a "x">}), qr/unterminated internal subset at byte offset 12 /, 'a subset missing its ]');
    like(refused(q{<!DOCTYPE r [ <!ENTITY %a "x"> ]><r/>}), qr/PEs in Internal Subset.* at byte offset 23 /, '% run into a name in an entity declaration is a reference, refused');
    ok(full($pre . q{<!ENTITY lt "&#60;"><!ENTITY amp "&#38;">]><r>&lt;&amp;</r>})->root->text eq '<&', 'redeclaring lt and amp as 4.6 allows changes nothing');
}

# the root element under validate
{
    ok(full('<!DOCTYPE a><b/>'), 'the DOCTYPE name is not checked against the root by default: it is a validity constraint');
    like(refused('<!DOCTYPE a><b/>', validate => 1), qr/root element is not the one the DOCTYPE names \(VC: Root Element Type\) at byte offset 12 /, 'and is under validate');
    # under validate every element type must be declared too, so the
    # document that passes has to declare the one it uses
    ok(full('<!DOCTYPE a [<!ELEMENT a EMPTY>]><a/>', validate => 1), 'which passes when they match');
    like(refused('<!DOCTYPE a><a/>', validate => 1), qr/the element type is not declared \(VC: Element Valid\)/,
         'and a DOCTYPE that declares nothing leaves its root undeclared');
}

# XML 1.1 in the subset: the erratum on NEL and LS
{
    my $doc = full(qq{<?xml version="1.1"?><!DOCTYPE r [\x{c2}\x{85}<!ENTITY e "a\x{c2}\x{85}b">\x{e2}\x{80}\xa8]><r>&e;</r>});
    is($doc->root->text, "a\nb", 'a NEL in an entity value is a line end, and NEL and LS between declarations are whitespace');
}

# the budgets, each at its edge, each proven to be the one that fired
{
    my $dtd = '<!DOCTYPE r [<!ENTITY a "0123456789">]>';
    my $ten = $dtd . '<r>' . ('&a;' x 10) . '</r>';
    ok(full($ten, max_expansion_bytes => 100), '100 bytes under a 100 byte budget');
    like(refused($ten, max_expansion_bytes => 99), qr/exceeds max_expansion_bytes at byte offset 69 /, '100 under 99 fails at the tenth reference');
    my $chain = '<!DOCTYPE r [' . join('', map { qq{<!ENTITY e$_ "&e@{[$_+1]};">} } 1 .. 4) . '<!ENTITY e5 "x">]><r>&e1;</r>';
    ok(full($chain, max_entity_depth => 5), 'a chain of five under a depth of five');
    like(refused($chain, max_entity_depth => 4), qr/nested deeper than max_entity_depth at byte offset 83 /, 'and refused under four, at the fifth reference inside the fourth entity');
    my $ratio = $dtd . '<r>' . ('&a;' x 30) . '</r>';   # 300 bytes pushed over 139 bytes of input
    ok(full($ratio, max_expansion_ratio => 2), 'a ratio of 2.16 rounds down to 2 and passes at 2');
    like(refused($ratio, max_expansion_ratio => 1), qr/exceeds max_expansion_ratio times the input at byte offset 123 /, 'and fails at 1, at the reference that crossed it');
    for my $o (qw(max_entity_depth max_expansion_bytes max_expansion_ratio)) {
        ok(!eval { file_xml_decode('<r/>', $o => 1); 1 }, "$o is refused under strict");
        like($@, qr/options of profile => 'full'/, 'naming full');
    }
    ok(!eval { file_xml_decode('<r/>', validate => 1); 1 }, 'so is validate');
}

# canonical form: defaults are attributes, entities are text
{
    my $doc = full(<<'XML');
<!DOCTYPE doc [
<!ATTLIST e a CDATA "1" b CDATA #IMPLIED>
<!ENTITY t "<e b='2'/>">
]>
<doc>&t;<e a="3"/></doc>
XML
    is($doc->c14n, '<doc><e a="1" b="2"></e><e a="3"></e></doc>', 'a defaulted attribute sorts with the written ones; the entity is gone');
    is($doc->c14n(mode => 'inclusive'), '<doc><e a="1" b="2"></e><e a="3"></e></doc>', 'under inclusive');
    is($doc->c14n(mode => 'inclusive-1.1'), '<doc><e a="1" b="2"></e><e a="3"></e></doc>', 'and 1.1');
}

done_testing;
