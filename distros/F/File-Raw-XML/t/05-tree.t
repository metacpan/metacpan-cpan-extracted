#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# The tree, through the private dump: kinds, order, parent links, text
# merged across CDATA, the document node and its children.

sub dump_ { File::Raw::XML::_dump(@_) }
sub refused { my $ok = eval { File::Raw::XML::_dump(@_); 1 }; $ok ? '' : $@ }

# strip the pointer column so is_deeply reads cleanly
sub strip {
    my ($row) = @_;
    return $row unless ref $row eq 'ARRAY';
    if ($row->[0] eq 'element') {
        return ['element', @{$row}[1..5], [map { strip($_) } @{ $row->[6] }]];
    }
    if ($row->[0] eq 'document') {
        return ['document', [map { strip($_) } @{ $row->[1] }]];
    }
    return $row;
}

# shape and order
{
    my $t = strip(dump_('<?xml version="1.0"?><!-- top --><?pi x?><r><a>t</a><b/></r><!-- tail -->'));
    is_deeply($t, ['document', [
        ['comment', ' top '],
        ['pi', 'pi', 'x'],
        ['element', '', '', 'r', [], [], [
            ['element', '', '', 'a', [], [], [['text', 't']]],
            ['element', '', '', 'b', [], [], []],
        ]],
        ['comment', ' tail '],
    ]], 'the document node holds the top-level misc with the root among them, in order');
}

# text coalescing
{
    my $t = strip(dump_('<r>a<![CDATA[b]]>c<![CDATA[]]>d</r>'));
    is_deeply($t->[1][0][6], [['text', 'abcd']], 'adjacent text and CDATA merge into one text node');

    $t = strip(dump_('<r>a<!-- c -->b</r>'));
    is_deeply($t->[1][0][6], [['text', 'a'], ['comment', ' c '], ['text', 'b']],
              'a comment splits text into two nodes');

    $t = strip(dump_('<r>a<?p?>b</r>'));
    is_deeply($t->[1][0][6], [['text', 'a'], ['pi', 'p', ''], ['text', 'b']],
              'and so does a PI');

    $t = strip(dump_('<r>&lt;<![CDATA[&lt;]]></r>'));
    is_deeply($t->[1][0][6], [['text', '<&lt;']], 'a reference and its CDATA spelling stay distinct in the merge');
}

# whitespace
{
    my $t = strip(dump_("\n<r> <a/> </r>\n\n"));
    is_deeply($t->[1], [['element', '', '', 'r', [], [], [
        ['text', ' '], ['element', '', '', 'a', [], [], []], ['text', ' '],
    ]]], 'whitespace inside the root is kept, whitespace outside it is dropped');

    $t = strip(dump_("<r/>"));
    is_deeply($t->[1][0][6], [], 'an empty element has no children');
    $t = strip(dump_("<r></r>"));
    is_deeply($t->[1][0][6], [], 'and neither does an empty start/end pair');
}

# attributes and names
{
    my $t = dump_('<r xmlns="urn:d" xmlns:p="urn:p" a="1" p:b="2"><p:c d="3"/></r>');
    my $r = $t->[1][0];
    is($r->[1], 'urn:d', 'the root is in the default namespace');
    is($r->[3], 'r', 'local name');
    is_deeply($r->[4], [['', '', 'a', '1'], ['urn:p', 'p', 'b', '2']],
              'attributes in document order: unprefixed has no namespace, prefixed resolved');
    is_deeply($r->[5], [['', 'urn:d'], ['p', 'urn:p']], 'declarations, in order; none of them in attrs');
    my $c = $r->[6][0];
    is_deeply([@{$c}[1..3]], ['urn:p', 'p', 'c'], 'a prefixed child resolves through the parent scope');
    is_deeply($c->[4], [['', '', 'd', '3']], 'an unprefixed attribute on it has no namespace, not urn:d');
    is_deeply($c->[5], [], 'and it carries no declarations of its own');
}

# the walkers: find with a cursor, descendants in order, text, attr_value
{
    my $doc = '<r xmlns:p="urn:p" a="1" p:a="2"><a>x<b>y</b></a><p:a/>z<c><a/></c></r>';
    my $w = File::Raw::XML::_walk($doc, undef, 'a');
    is_deeply($w->{find}, ['a', 'p:a'], 'find with undef namespace: every direct child named a');
    is_deeply($w->{descendants}, ['a', 'b', 'p:a', 'c', 'a'], 'descendants in document order');
    is($w->{text}, 'xyz', 'text is every descendant text run in order');
    is($w->{attr}, '1', 'attr_value with undef namespace: the first a in document order');

    $w = File::Raw::XML::_walk($doc, '', 'a');
    is_deeply($w->{find}, ['a'], 'find with the empty namespace: only the unprefixed child');
    is($w->{attr}, '1', 'attr_value with the empty namespace: the unprefixed attribute');

    $w = File::Raw::XML::_walk($doc, 'urn:p', 'a');
    is_deeply($w->{find}, ['p:a'], 'find with a namespace: only the child in it');
    is($w->{attr}, '2', 'attr_value with a namespace: the prefixed attribute');

    $w = File::Raw::XML::_walk($doc, 'urn:none', 'a');
    is_deeply($w->{find}, [], 'find with an unknown namespace: nothing');
    is($w->{attr}, undef, 'attr_value with an unknown namespace: undef');
}

# refusals the parser makes
{
    like(refused('<a><b></a>'),  qr/end tag does not match the open element at byte offset 6/, 'a mismatched end tag');
    like(refused('<a></b>'),     qr/end tag does not match/, 'a mismatched end tag on the root');
    like(refused('<a>'),         qr/element is never closed at byte offset 0/, 'an unclosed root');
    like(refused('<a><b/>'),     qr/element is never closed at byte offset 0/, 'an unclosed root after a child');
    like(refused('<a><b>'),      qr/element is never closed at byte offset 3/, 'the innermost unclosed element is cited');
    like(refused(''),            qr/no root element at end of input/, 'an empty input has no root');
    like(refused('<!-- only -->'), qr/no root element/, 'a comment alone has no root');
    like(refused('<a/><b/>'),    qr/more than one root element at byte offset 4/, 'two roots');
    like(refused('x<a/>'),       qr/content before the root element at byte offset 0/, 'text before the root');
    like(refused('<a/>x'),       qr/content after the root element at byte offset 4/, 'text after the root');
    like(refused('</a>'),        qr/end tag with no open element at byte offset 0/, 'an end tag first');
    like(refused('<a/></a>'),    qr/end tag with no open element/, 'an end tag after the root closed');
}

done_testing;
