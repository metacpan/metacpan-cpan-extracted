#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# XInclude 1.0 under xinclude => 1: an inclusion tree built from a
# hash-backed resolver, the xml:base fixup of section 4.7.5, fallback on a
# resource error, a loop and the depth budget as fatal errors, parse=text
# with an encoding, xpointer in the element() scheme and as a bare name,
# and every fetch counted against max_fetches.

my $XI = 'http://www.w3.org/2001/XInclude';

my %files;
my @calls;
my $resolver = sub {
    my %r = @_;
    push @calls, $r{system_id};
    die "no such resource: $r{system_id}\n" unless exists $files{ $r{system_id} };
    return $files{ $r{system_id} };
};

sub inc {
    my ($bytes, %o) = @_;
    @calls = ();
    return file_xml_decode($bytes, profile => 'full', xinclude => 1,
                           resolve => $resolver, base => 'http://x.org/a/doc.xml', %o);
}
sub refused { my @a = @_; my $ok = eval { inc(@a); 1 }; $ok ? '' : $@ }

# the deliverable: two included documents, one of which includes a third
{
    %files = (
        'http://x.org/a/one.xml'   => '<one><i/></one>',
        'http://x.org/a/two.xml'   => qq{<two xmlns:xi="$XI"><xi:include href="sub/three.xml"/></two>},
        'http://x.org/a/sub/three.xml' => '<three/>',
    );
    my $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="one.xml"/><xi:include href="two.xml"/></r>});
    my ($one, $two) = $doc->root->elements;
    is($one->local, 'one', 'the first include is replaced by what it names');
    is($two->local, 'two', 'and the second');
    is(scalar(() = $doc->root->descendants(undef, 'three')), 1, 'a document included by an included document is in the tree too');
    is($doc->root->to_string(declaration => 0),
       qq{<r xmlns:xi="$XI"><one xml:base="http://x.org/a/one.xml"><i/></one><two xmlns:xi="$XI" xml:base="http://x.org/a/two.xml"><three xml:base="http://x.org/a/sub/three.xml"/></two></r>},
       'each included root carries an xml:base naming its source (4.7.5), and the bindings in scope where it came from');
        is_deeply(\@calls, ['http://x.org/a/one.xml', 'http://x.org/a/two.xml', 'http://x.org/a/sub/three.xml'],
              'every href resolved against the base of the element that named it');
    my ($three) = $doc->root->descendants(undef, q{three});
    is($three->base_uri, 'http://x.org/a/sub/three.xml', 'and the fixup makes base_uri right afterwards');
    is(scalar(() = $doc->root->descendants($XI, q{include})), 0, 'no xi:include element is left in the result');
    isa_ok($three->doc, q{File::Raw::XML::Document}, 'the imported nodes belong to the including document');
}

# a loop is fatal, fallback or not
{
    %files = (
        'http://x.org/a/loop1.xml' => qq{<l1 xmlns:xi="$XI"><xi:include href="loop2.xml"/></l1>},
        'http://x.org/a/loop2.xml' => qq{<l2 xmlns:xi="$XI"><xi:include href="loop1.xml"/></l2>},
    );
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="loop1.xml"/></r>}),
         qr/names a document already being included: a loop/, 'a loop through two documents is refused');
    %files = ('http://x.org/a/self.xml' => qq{<s xmlns:xi="$XI"><xi:include href="self.xml"><xi:fallback>no</xi:fallback></xi:include></s>});
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="self.xml"/></r>}),
         qr/a loop/, 'and a self-inclusion is refused even with a fallback');
    like(refused(qq{<r xmlns:xi="$XI" xml:id="top"><xi:include xpointer="top"/></r>}),
         qr/names an ancestor of itself: a loop/, 'a same-document include of an ancestor is a loop too');
}

# the depth budget
{
    %files = map {
        my $n = $_;
        ("http://x.org/a/d$n.xml" => $n < 12
            ? qq{<d$n xmlns:xi="$XI"><xi:include href="d@{[$n+1]}.xml"/></d$n>}
            : "<d$n/>")
    } 1 .. 12;
    my $top = qq{<r xmlns:xi="$XI"><xi:include href="d1.xml"/></r>};
    ok(inc($top, max_xinclude_depth => 20), 'a chain of twelve under a depth of twenty');
    like(refused($top, max_xinclude_depth => 3), qr/nested deeper than max_xinclude_depth/, 'and refused under three');
    like(refused($top), qr/nested deeper than max_xinclude_depth/, 'the default of eight stops it too');
    like(refused($top, max_fetches => 4), qr/more external fetches than max_fetches/, 'max_fetches counts the includes');
}

# fallback on a resource error
{
    %files = ('http://x.org/a/there.xml' => '<there/>');
    my $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="missing.xml"><xi:fallback><gone/> text</xi:fallback></xi:include></r>});
    is($doc->root->to_string(declaration => 0), qq{<r xmlns:xi="$XI"><gone/> text</r>},
       'the resolver refusing takes the fallback children, whitespace and all');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="missing.xml"/></r>}),
         qr{no such resource: http://x\.org/a/missing\.xml}, 'and with no fallback it is fatal, with the resolver\'s own message over the resolved URI');

    %files = ('http://x.org/a/bad.xml' => '<not well formed');
    $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="bad.xml"><xi:fallback><ok/></xi:fallback></xi:include></r>});
    is($doc->root->to_string(declaration => 0), qq{<r xmlns:xi="$XI"><ok/></r>}, 'an included document that does not parse is a resource error too');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="bad.xml"/></r>}), qr/unterminated start tag|expected/, 'fatal without a fallback');

    $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="missing.xml"><xi:fallback/></xi:include></r>});
    is($doc->root->to_string(declaration => 0), qq{<r xmlns:xi="$XI"/>}, 'an empty fallback leaves nothing');
}

# parse="text"
{
    %files = (
        'http://x.org/a/t.txt'  => "a < b & c\n",
        'http://x.org/a/l1.txt' => "caf\xE9",
    );
    my $doc = inc(qq{<r xmlns:xi="$XI">[<xi:include href="t.txt" parse="text"/>]</r>});
    is($doc->root->text, "[a < b & c\n]", 'parse=text puts the bytes in as text, never as markup');
    is($doc->root->to_string(declaration => 0), qq{<r xmlns:xi="$XI">[a &lt; b &amp; c\n]</r>}, 'and the writer escapes them');
    $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="l1.txt" parse="text" encoding="ISO-8859-1"/></r>});
    is($doc->root->text, "caf\x{e9}", 'the encoding attribute decodes the text');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="l1.txt" parse="text"/></r>}), qr/not UTF-8|refused/, 'and without it the bytes must be UTF-8');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="t.txt" parse="sideways"/></r>}), qr/parse must be xml or text/, 'parse takes two values');
}

# xpointer: the element() scheme and a bare name
{
    %files = ('http://x.org/a/p.xml' => '<p xml:id="top"><a><b>first</b><b>second</b></a><c xml:id="see"/></p>');
    my $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="p.xml" xpointer="see"/></r>});
    my ($c1) = $doc->root->elements; is($c1->local, q{c}, 'a bare name resolves through the included document\'s ID index');
    $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="p.xml" xpointer="element(/1/1/2)"/></r>});
    my ($s1) = $doc->root->elements; is($s1->text, q{second}, 'an element() child sequence walks from the document element');
    $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="p.xml" xpointer="element(see)"/></r>});
    my ($c2) = $doc->root->elements; is($c2->local, q{c}, 'element() with a name');
    $doc = inc(qq{<r xmlns:xi="$XI"><xi:include href="p.xml" xpointer="element(top/1/1)"/></r>});
    my ($f1) = $doc->root->elements; is($f1->text, q{first}, 'element() with a name and a sequence');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="p.xml" xpointer="element(/1/9)"/></r>}),
         qr/names no element in the included document/, 'a step past the end is an error');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="p.xml" xpointer="xpointer(//b)"/></r>}),
         qr/only the element\(\) scheme and a bare name are supported/, 'the xpointer() scheme is not supported, and says so');

    # a same-document include, which needs no href
    $doc = inc(qq{<r xmlns:xi="$XI" ><t xml:id="here"><deep/></t><xi:include xpointer="here"/></r>});
    is(scalar(() = $doc->root->descendants(undef, 'deep')), 2, 'a same-document include copies the subtree it names');
}

# the options are refused under strict, and the pass needs a resolver
{
    ok(!eval { file_xml_decode('<r/>', xinclude => 1); 1 }, 'xinclude is refused under strict');
    like($@, qr/xinclude is an option of profile => 'full'/, 'naming full');
    ok(!eval { file_xml_decode('<r/>', max_xinclude_depth => 2); 1 }, 'and so is its budget');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include href="x.xml"/></r>}, resolve => undef),
         qr/cannot be read without a resolver; pass resolve/, 'without a resolver an include is refused, naming the option');
    my ($still) = file_xml_decode(qq{<r xmlns:xi="$XI"><xi:include href="x.xml"/></r>}, profile => q{full})->root->elements; is($still->local, q{include}, 'and without xinclude => 1 an xi:include is just an element');
    like(refused(qq{<r xmlns:xi="$XI"><xi:include/></r>}), qr/needs an href or an xpointer/, 'an include with neither is an error');
}

done_testing;
