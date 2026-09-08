#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# Namespaces 1.0 through the dump: the default applies to elements and not
# attributes, prefixes rebind, the xml and xmlns rules, and the refusals.

sub dump_   { File::Raw::XML::_dump(@_) }
sub refused { my $ok = eval { File::Raw::XML::_dump(@_); 1 }; $ok ? '' : $@ }
sub root    { dump_(@_)->[1][0] }

{
    my $r = root('<r xmlns="urn:d"><a b="1"/></r>');
    is($r->[1], 'urn:d', 'the default namespace applies to the root');
    is($r->[6][0][1], 'urn:d', 'and to its child');
    is($r->[6][0][4][0][0], '', 'and not to the child\'s unprefixed attribute');
}

{
    my $r = root('<r xmlns:p="urn:1"><p:a xmlns:p="urn:2"><p:b/></p:a><p:c/></r>');
    is($r->[6][0][1], 'urn:2', 'a prefix rebound on a child takes the new binding');
    is($r->[6][0][6][0][1], 'urn:2', 'and its descendants see the rebinding');
    is($r->[6][1][1], 'urn:1', 'while a sibling outside it sees the original');
}

{
    my $r = root('<r xmlns="urn:d"><a xmlns=""><b/></a></r>');
    is($r->[6][0][1], '', 'xmlns="" undeclares the default');
    is($r->[6][0][6][0][1], '', 'for its descendants too');
    is_deeply($r->[6][0][5], [['', '']], 'and is recorded as a declaration with an empty URI');
}

{
    my $r = root('<r xml:lang="en"><a xml:space="preserve"/></r>');
    is($r->[4][0][0], 'http://www.w3.org/XML/1998/namespace', 'the xml prefix resolves with no declaration');
    is($r->[6][0][4][0][0], 'http://www.w3.org/XML/1998/namespace', 'anywhere in the document');
    is_deeply($r->[5], [], 'and never appears as a declaration');

    $r = root('<r xmlns:xml="http://www.w3.org/XML/1998/namespace" xml:lang="en"/>');
    is_deeply($r->[5], [], 'an explicit xmlns:xml with the right URI is accepted and dropped');
    is($r->[4][0][0], 'http://www.w3.org/XML/1998/namespace', 'and xml: still resolves');
}

# interning: two elements in one namespace share the pointer
{
    my $t = dump_('<r xmlns="urn:d" xmlns:p="urn:d"><p:a/><b xmlns="urn:d"/></r>');
    my $r = $t->[1][0];
    my @ptr = ($r->[7], $r->[6][0][7], $r->[6][1][7]);
    is($ptr[1], $ptr[0], 'a prefixed element in the same namespace shares the interned URI');
    is($ptr[2], $ptr[0], 'and so does one that redeclared the same default');
    $t = dump_('<r xmlns="urn:a"><b xmlns="urn:b"/></r>');
    isnt($t->[1][0][6][0][7], $t->[1][0][7], 'different namespaces are different pointers');
}

# refusals
{
    like(refused('<p:a/>'),                 qr/element prefix is not bound to a namespace at byte offset 0/, 'an unbound element prefix');
    like(refused('<a p:b="1"/>'),           qr/attribute prefix is not bound to a namespace at byte offset 3/, 'an unbound attribute prefix');
    like(refused('<a xmlns:p="urn:p"><p:b><q:c/></p:b></a>'), qr/element prefix is not bound.* at byte offset 24/, 'an unbound prefix deeper down, at its offset');
    like(refused('<a xmlns:xml="urn:x"/>'), qr/xml prefix is bound to its own namespace and no other at byte offset 3/, 'xmlns:xml with the wrong URI');
    like(refused('<a xmlns:p="http://www.w3.org/XML/1998/namespace"/>'), qr/only the xml prefix may be bound to the xml namespace/, 'another prefix bound to the xml namespace');
    like(refused('<a xmlns:xmlns="urn:x"/>'), qr/the xmlns prefix cannot be declared at byte offset 3/, 'xmlns:xmlns');
    like(refused('<a xmlns:p="http://www.w3.org/2000/xmlns/"/>'), qr/the xmlns namespace name cannot be bound/, 'a prefix bound to the xmlns namespace');
    like(refused('<a xmlns:p=""/>'),        qr/a prefix cannot be undeclared/, 'xmlns:p=""');
    like(refused('<a xmlns="relative/uri"/>'), qr/relative namespace URI is refused.* at byte offset 3/, 'a relative default namespace URI');
    like(refused('<a xmlns:p="urn"/>'),     qr/relative namespace URI/, 'a scheme with no colon is relative');
    like(refused('<a xmlns:p="1abc:x"/>'),  qr/relative namespace URI/, 'a scheme must start with a letter');
    ok(!refused('<a xmlns:p="a+b-c.d:x"/>'), 'a scheme may carry + - . after the first letter');
    ok(!refused('<a xmlns:p="urn:p" xmlns:q="urn:p"/>'), 'two prefixes bound to one URI is legal');

    like(refused('<a xmlns:p="urn:p" xmlns:q="urn:p" p:x="1" q:x="2"/>'),
         qr/two attributes with one namespace and local name at byte offset 43/,
         'the same attribute through two prefixes is a duplicate after expansion (6.3)');
    ok(!refused('<a xmlns:p="urn:p" xmlns:q="urn:q" p:x="1" q:x="2"/>'), 'but the same local name in two namespaces is fine');
    ok(!refused('<a xmlns:p="urn:p" x="1" p:x="2"/>'), 'and unprefixed beside prefixed is fine, since unprefixed has no namespace');
    like(refused('<a xmlns:p="urn:p" xmlns:p="urn:q"/>'), qr/attribute given twice/, 'the same prefix declared twice is the lexer\'s literal duplicate');
}

done_testing;
