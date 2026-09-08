#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# Canonical XML 1.1 (W3C Recommendation, 2 May 2008). For a whole document
# it is Canonical XML 1.0; the two differ only in what an element apex
# inherits from its omitted ancestors, section 2.4. The join-URI-References
# examples of section 2.4 are transcribed from the Recommendation's text
# and run through the join directly.

sub inc10 { my ($xml) = @_; file_xml_decode($xml)->c14n(mode => 'inclusive') }
sub inc11 { my ($xml) = @_; file_xml_decode($xml)->c14n(mode => 'inclusive-1.1') }
sub join_ { File::Raw::XML::_join_base(@_) }

# whole documents: identical under both
for my $xml (
    "<doc>\n   <clean>   </clean>\n   <dirty>   A   B   </dirty>\n</doc>",
    '<r xmlns="urn:a" xml:lang="en" xml:base="x/"><b xmlns="" xml:id="i" xml:space="preserve"/></r>',
    "<?pi x?><!-- c --><r/><!-- d -->",
) {
    is(inc11($xml), inc10($xml), "a whole document is the same under 1.0 and 1.1: $xml");
}

# section 2.4: join-URI-References, the Recommendation's own examples
is(join_('abc/', '../'), '',       '2.4: "abc/" and "../" should result in ""');
is(join_('../', '../'),  '../../', '2.4: "../" and "../" are combined as "../../"');
is(join_('..', '..'),    '../../', '2.4: ".." and ".." are combined as "../../"');
# the a/b/c/d example: b (..) and c (..) removed, d (x) kept: the values are
# reduced innermost first, join("..", "x") then join("..", that)
is(join_('..', join_('..', 'x')), '../../x', '2.4: the sample document gives d the base "../../x"');
# and the values the 3.8 example reduces to
is(join_('bar/', 'foo'), 'bar/foo', 'join("bar/", "foo")');
is(join_('something/else', 'bar/foo'), 'something/bar/foo', 'join("something/else", "bar/foo"): the 3.8 value');
# ordinary RFC 3986 behaviour is kept
is(join_('http://a/b/c/d;p?q', 'g'),     'http://a/b/c/g',   'RFC 3986 5.4.1: g');
is(join_('http://a/b/c/d;p?q', '../g'),  'http://a/b/g',     'RFC 3986 5.4.1: ../g');
is(join_('http://a/b/c/d;p?q', '/g'),    'http://a/g',       'RFC 3986 5.4.1: /g');
is(join_('http://a/b/c/d;p?q', '//g'),   'http://g',         'RFC 3986 5.4.1: //g');
is(join_('http://a/b/c/d;p?q', '?y'),    'http://a/b/c/d;p?y', 'RFC 3986 5.4.1: ?y');
is(join_('http://a/b/c/d;p?q', ''),      'http://a/b/c/d;p?q', 'RFC 3986 5.4.1: the empty reference');
is(join_('http://a/b/c/d;p?q', 'g#s'),   'http://a/b/c/g',   'the fragment is dropped, as 2.4 says');
is(join_('http://a/b/c/d;p?q', 'g:h'),   'g:h',              'a reference with a scheme stands alone');
is(join_('a//b/', 'c'), 'a/b/c', 'runs of / collapse to one');

# 3.8 Document Subsets and XML Attributes, as far as a subtree apex can
# express it. The Recommendation's subset keeps e1 and e3 and omits e2
# between them; `without` omits subtrees only, so the apex is where the
# omitted ancestors are. The input is the Recommendation's with its DTD
# removed and the attribute the DTD defaulted written out on e2.
{
    my $xml = <<'XML';
<doc xmlns="http://www.ietf.org" xmlns:w3c="http://www.w3.org" xml:base="something/else">
   <e1>
      <e2 xmlns="" xml:id="abc" xml:base="bar/" xml:space="preserve">
         <e3 id="E3" xml:base="foo"/>
      </e2>
   </e1>
</doc>
XML
    my $doc  = file_xml_decode($xml);
    my ($e1) = $doc->root->elements;
    my ($e2) = $e1->elements;
    my ($e3) = $e2->elements;

    # e3 as the apex: its omitted ancestors are e2 and doc, whose xml:base
    # values join with its own to the value the Recommendation shows on e3
    is($e3->c14n(mode => 'inclusive-1.1'),
       '<e3 xmlns:w3c="http://www.w3.org" id="E3" xml:base="something/bar/foo" xml:space="preserve"></e3>',
       '1.1: e3 inherits xml:space simply, joins xml:base to something/bar/foo, and never xml:id');
    # 1.0 section 2.4: "remove any that are in E's attribute axis", so e3's
    # own xml:base="foo" stands and only xml:id and xml:space are copied
    is($e3->c14n(mode => 'inclusive'),
       '<e3 xmlns:w3c="http://www.w3.org" id="E3" xml:base="foo" xml:id="abc" xml:space="preserve"></e3>',
       '1.0: e3 copies the nearest of every xml: attribute it lacks, xml:id included, and keeps its own xml:base');

    # e1 as the apex: only doc is omitted above it
    is($e1->c14n(mode => 'inclusive-1.1', without => [$e2]),
       qq{<e1 xmlns="http://www.ietf.org" xmlns:w3c="http://www.w3.org" xml:base="something/else">\n      \n   </e1>},
       '1.1: e1 inherits the omitted doc\'s xml:base as it is');
}

# xml:id: copied by 1.0, never by 1.1
{
    my $doc = file_xml_decode('<r xml:id="a" xml:lang="en"><e/></r>');
    my ($e) = $doc->root->elements;
    is($e->c14n(mode => 'inclusive'),     '<e xml:id="a" xml:lang="en"></e>', '1.0 copies xml:id and xml:lang onto the apex');
    is($e->c14n(mode => 'inclusive-1.1'), '<e xml:lang="en"></e>',            '1.1 copies xml:lang and not xml:id');
    is($e->c14n(mode => 'exclusive'),     '<e></e>',                          'exclusive copies nothing');
}

# nearest wins; the apex's own value wins over any ancestor
{
    my $doc = file_xml_decode('<r xml:lang="en" xml:space="default"><m xml:lang="fr"><e xml:space="preserve"/></m></r>');
    my ($m) = $doc->root->elements;
    my ($e) = $m->elements;
    is($e->c14n(mode => 'inclusive-1.1'), '<e xml:lang="fr" xml:space="preserve"></e>', '1.1: the nearest xml:lang, the apex\'s own xml:space');
    is($e->c14n(mode => 'inclusive'),     '<e xml:lang="fr" xml:space="preserve"></e>', '1.0: the same here');
}

# xml:base: joined only when an omitted ancestor had one; empty is not rendered
{
    my $doc = file_xml_decode('<r><m><e xml:base="x"/></m></r>');
    my ($m) = $doc->root->elements;
    my ($e) = $m->elements;
    is($e->c14n(mode => 'inclusive-1.1'), '<e xml:base="x"></e>', 'no ancestor xml:base: the apex\'s own value stands');

    $doc = file_xml_decode('<r xml:base="abc/"><e xml:base="../"/></r>');
    ($e) = $doc->root->elements;
    is($e->c14n(mode => 'inclusive-1.1'), '<e></e>', 'a join that reduces to "" renders no xml:base');
    is($e->c14n(mode => 'inclusive'), '<e xml:base="../"></e>', '1.0 keeps the apex\'s own xml:base as written');

    $doc = file_xml_decode('<r xml:base="a/b"><e/></r>');
    ($e) = $doc->root->elements;
    is($e->c14n(mode => 'inclusive-1.1'), '<e xml:base="a/b"></e>', 'an apex with no xml:base takes the omitted ancestor\'s');
}

# other xml: attributes are ordinary under 1.1 and inherited under 1.0
{
    my $doc = file_xml_decode('<r xmlns:x="urn:x" xml:foo="1"><e/></r>');
    my ($e) = $doc->root->elements;
    is($e->c14n(mode => 'inclusive'),     '<e xmlns:x="urn:x" xml:foo="1"></e>', '1.0 copies every xml: attribute');
    is($e->c14n(mode => 'inclusive-1.1'), '<e xmlns:x="urn:x"></e>',             '1.1 copies only lang, space and base');
}

done_testing;
