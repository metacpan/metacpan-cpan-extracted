#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# The four attributes the XML family gives meaning to without a DTD:
# xml:id in the ID index under full and not under strict, xml:base through
# the RFC 3986 join seeded by the document's own URI, xml:lang and
# xml:space inherited and overridden.

sub full { my ($b, %o) = @_; file_xml_decode($b, profile => 'full', %o) }
sub refused { my ($b, %o) = @_; my $ok = eval { full($b, %o); 1 }; $ok ? '' : $@ }

# xml:id
{
    my $doc = full('<r xmlns:xml="http://www.w3.org/XML/1998/namespace"><a xml:id="one"/><b xml:id="two"><c/></b></r>');
    is($doc->by_id(id => 'two')->local, 'b', 'xml:id is an ID under full with no id_attrs');
    is($doc->by_id(id => 'one')->local, 'a', 'for every element that carries one');
    ok(!defined $doc->by_id(id => 'three'), 'and only for those');

    my $strict = file_xml_decode('<r><a xml:id="one"/></r>');
    ok(!defined $strict->by_id(id => 'one'), 'under strict it is an ordinary attribute, as in 0.01');
    my ($sa) = $strict->root->elements;
    is($sa->attr_ns('http://www.w3.org/XML/1998/namespace', 'id'), 'one', 'readable as an attribute all the same');
    is(file_xml_decode('<r><a xml:id="one"/><b xml:id="one"/></r>')->root->local, 'r',
       'and a duplicate is not even noticed under strict');

    like(refused('<r><a xml:id="dup"/><b xml:id="dup"/></r>'), qr/two elements carry the same ID value/,
         'under full a duplicate xml:id is refused as id_attrs refuses one');
    like(refused('<r><a xml:id="not a name"/></r>'), qr/an xml:id value must be an NCName/, 'the value must be an NCName');
    like(refused('<r><a xml:id="has:colon"/></r>'), qr/an xml:id value must be an NCName/, 'which has no colon');
    like(refused('<r><a xml:id=""/></r>'), qr/an xml:id value must be an NCName/, 'and is not empty');
    ok(full('<r><a xml:id="_x.y-1"/></r>'), 'an NCName may hold underscore, dot, hyphen and digits');

    # it lives beside id_attrs, not instead of it
    my $both = full('<r><a xml:id="x"/><b ID="y"/></r>', id_attrs => ['ID']);
    is($both->by_id(id => 'x')->local, 'a', 'xml:id indexed');
    is($both->by_id(ID => 'y')->local, 'b', 'and the named attribute too');
}

# xml:base
{
    my $doc = full(<<'XML', base => 'http://example.org/a/doc.xml');
<r xml:base="/top/">
  <mid xml:base="sub/">
    <leaf xml:base="deep/x.xml"/>
    <rel/>
  </mid>
  <plain/>
</r>
XML
    my ($mid, $plain) = $doc->root->elements;
    my ($leaf, $rel)  = $mid->elements;
    is($doc->root->base_uri, 'http://example.org/top/', 'the root joins its xml:base onto the document URI');
    is($mid->base_uri, 'http://example.org/top/sub/', 'a relative xml:base joins onto its parent\'s');
    is($leaf->base_uri, 'http://example.org/top/sub/deep/x.xml', 'through three levels');
    is($rel->base_uri, 'http://example.org/top/sub/', 'an element with none takes its parent\'s');
    is($plain->base_uri, 'http://example.org/top/', 'and so does one under the root');
    is($doc->document->base_uri, 'http://example.org/a/doc.xml', 'the document node is the document URI');

    is(full('<r/>')->root->base_uri, '', 'with no document URI and no xml:base it is empty');
    is(full('<r xml:base="http://other.example/x"/>', base => 'http://example.org/a/doc.xml')->root->base_uri,
       'http://other.example/x', 'an absolute xml:base replaces the document URI');
    is(full('<r xml:base="/at/root"/>', base => 'http://example.org/a/b/doc.xml')->root->base_uri,
       'http://example.org/at/root', 'a rooted path keeps the authority');
    is(full('<r xml:base="../up/"/>', base => 'http://example.org/a/b/doc.xml')->root->base_uri,
       'http://example.org/a/up/', 'and dot segments are removed');
}

# xml:lang
{
    my $doc = full('<r xml:lang="en"><a><b xml:lang="fr"><c/></b></a><d xml:lang=""/></r>');
    my ($a, $d) = $doc->root->elements;
    my ($b) = $a->elements;
    my ($c) = $b->elements;
    is($doc->root->lang, 'en', 'xml:lang on the element itself');
    is($a->lang, 'en', 'inherited');
    is($b->lang, 'fr', 'overridden');
    is($c->lang, 'fr', 'and inherited from the override');
    is($d->lang, undef, 'the empty value says no language (section 2.12)');
    is(full('<r/>')->root->lang, undef, 'and none at all is undef');
}

# xml:space
{
    my $doc = full('<r xml:space="preserve"><a><b xml:space="default"><c/></b></a></r>');
    my ($a) = $doc->root->elements;
    my ($b) = $a->elements;
    my ($c) = $b->elements;
    is($doc->root->space, 'preserve', 'xml:space on the element');
    is($a->space, 'preserve', 'inherited');
    is($b->space, 'default', 'overridden back to default');
    is($c->space, 'default', 'and inherited from the override');
    is(full('<r/>')->root->space, 'default', 'nothing said is default');
    is(full('<r xml:space="odd"/>')->root->space, 'default', 'and anything but preserve reads as default');
}

# the accessors follow an edit, because nothing is cached
{
    my $doc = full('<r><a/></r>', base => 'http://example.org/d.xml');
    my ($a) = $doc->root->elements;
    is($a->base_uri, 'http://example.org/d.xml', 'before the edit');
    $doc->root->set_attr('http://www.w3.org/XML/1998/namespace', 'xml:base', 'sub/');
    is($a->base_uri, 'http://example.org/sub/', 'and after one, without a stale cache');
    $doc->root->set_attr('http://www.w3.org/XML/1998/namespace', 'xml:lang', 'de');
    is($a->lang, 'de', 'the same for lang');
}

done_testing;
