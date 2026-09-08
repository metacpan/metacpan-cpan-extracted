#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# Fuzz through the Perl surface: fifty seeds, hundreds of inputs each,
# built from XML fragments and from random bytes. Every input either
# parses or dies with a message carrying the prefix, and nothing else is
# acceptable. An input that parses is canonicalised in all three modes
# and walked to the end, because the walkers and the serialiser read what
# the parser wrote and a malformed tree that parsed cleanly is found
# there. Run with: prove -b xt/fuzz.t
#
# The memory-safety proof is tools/fuzz/build.sh under ASan; this is the
# same idea through the SV layer, at Perl speed, on any machine.

my @frag = (
    '<a', '<a>', '</a>', '<a/>', '<', '>', '/>', '</', '<p:a', '</p:a>',
    'xmlns:', 'xmlns:p="urn:p"', 'xmlns=""', 'xmlns="urn:d"', 'xmlns:p=""',
    'xmlns:p="rel"', 'xmlns:xml="x"', 'xmlns:xmlns="x"', 'p:', 'xml:',
    'xml:lang="en"', 'xml:base="a/"', 'xml:base="../b"', 'xml:space="preserve"',
    'ID="x"', 'ID="y"', 'id="x"', 'a="1"', "a='1'", '="', '"', "'", '=', ' ',
    '&#x', '&#', '&amp;', '&lt;', '&gt;', '&quot;', '&apos;', '&#60;', '&#x3C;',
    '&#0;', '&#xD800;', '&#x110000;', '&foo;', '&', ';',
    '<![CDATA[', ']]>', '<!--', '-->', '--', '<?', '?>', '<?pi d?>', '<?xml',
    '<?xml version="1.0"?>', '<?xml version="1.1"?>', 'encoding="UTF-8"',
    'encoding="ISO-8859-1"', '<!DOCTYPE', '<!DOCTYPE a>', '<!ENTITY', '<!',
    "\r\n", "\r", "\n", "\t", "\0", "\xef\xbb\xbf", "\xfe\xff", "\xff\xfe",
    "\xc3\xa9", "\xe6\x97\xa5", "\xf0\x9f\x98\x80", "\xc0\x80", "\xed\xa0\x80",
    "\xf4\x90\x80\x80", "\xff", "\x80", 'text', 'x', ':', '_', '-', '.', '1',
    # the full profile's surface: the DOCTYPE, declarations, references
    '<!DOCTYPE r [', '<!DOCTYPE r SYSTEM "r.dtd">', ']>', '<!ELEMENT r (#PCDATA|a)*>',
    '<!ELEMENT a (b,(c|d)+)?>', '<!ATTLIST r a CDATA "x" b NMTOKENS #IMPLIED>',
    '<!ENTITY e "&e;">', '<!ENTITY f "<a>&#x20;</a>">', '<!ENTITY % p "<!ENTITY q \'x\'>">',
    '%p;', '&e;', '&f;', '&q;', '&#38;#38;', '<!NOTATION n SYSTEM "n">',
    '<!ENTITY u SYSTEM "u" NDATA n>', '<![INCLUDE[', '#REQUIRED', '#FIXED',
);

# every input under both profiles: strict must be untouched by the DTD
# code, and full must refuse or parse everything the fragments can make
sub try_one {
    my ($src) = @_;
    return try_profile($src, 'strict') && try_profile($src, 'full');
}

sub try_profile {
    my ($src, $profile) = @_;
    my $doc = eval { file_xml_decode($src, id_attrs => ['ID'], max_depth => 64, profile => $profile,
                                     ($profile eq 'full' ? (max_expansion_bytes => 65536, max_entity_depth => 8) : ())) };
    return $@ =~ /^File::Raw::XML: / ? 1 : 0 unless $doc;
    my $ok = eval {
        my $root = $doc->root;
        for my $mode (qw(exclusive inclusive inclusive-1.1)) {
            my $out = $root->c14n(mode => $mode, comments => 1);
            die 'empty' unless length $out;
            $doc->c14n(mode => $mode);
        }
        my $n = () = $root->descendants(undef, '');
        defined $root->text or die 'no text';
        $doc->by_id(ID => 'x');
        my @stack = ($doc->document);
        while (my $node = pop @stack) {
            $node->kind; $node->name; $node->attrs;
            push @stack, $node->children;
        }
        1;
    };
    return $ok ? 1 : 0;
}

# A random tree that is well-formed by construction, so the third batch
# reaches the walkers and the serialiser, then one hostile fragment
# spliced in at a random offset half the time, so the near-misses are
# fuzzed too: a tree that parses with the splice is the interesting case.
my @names = qw(a b c p:a p:b xml:x r);
my @attrs = ('a="1"', "b='2'", 'p:c="&amp;"', 'xml:lang="en"', 'xml:base="x/"',
             'xml:space="preserve"', 'ID="i1"', 'ID="i2"', 'xmlns:q="urn:q"',
             'xmlns=""', 'xmlns="urn:e"', 'q:d="&#10;"');
my @leaves = ('text', ' &lt; &amp; &gt; ', '&#169;', "\xc3\xa9", '<![CDATA[<x>]]>',
              '<!-- c -->', '<?pi d?>', "\n  ", "\r\n", '');
sub tree {
    my ($depth) = @_;
    my $name = $names[rand @names];
    my $open = "<$name" . join('', map { ' ' . $attrs[rand @attrs] } 1 .. int rand 3);
    return "$open/>" if $depth >= 5 || rand() < 0.3;
    my $body = join '', map { rand() < 0.5 ? $leaves[rand @leaves] : tree($depth + 1) } 1 .. int rand 5;
    return "$open>$body</$name>";
}
sub mutated_tree {
    my $src = '<r xmlns:p="urn:p">' . tree(1) . '</r>';
    if (rand() < 0.5) {
        my $at = int rand(length($src) + 1);
        substr($src, $at, 0) = $frag[rand @frag];
    }
    return $src;
}

my ($fails, $parsed, $total) = (0, 0, 0);
for my $seed (1 .. 50) {
    srand $seed;
    for (1 .. 400) {
        my $len = int rand 2000;
        my $src = join '', map { chr int rand 256 } 1 .. $len;
        $total++;
        $fails++ unless try_one($src);
    }
    for (1 .. 400) {
        my $n = 1 + int rand 60;
        my $src = join '', map { $frag[rand @frag] } 1 .. $n;
        $total++;
        $fails++ unless try_one($src);
    }
    for (1 .. 400) {
        my $src = mutated_tree();
        $total++;
        $parsed++ if eval { file_xml_decode($src, max_depth => 64); 1 };
        $fails++ unless try_one($src);
    }
}
is($fails, 0, "$total fuzz inputs handled cleanly");
cmp_ok($parsed, '>', 5000, "and $parsed of the tree inputs parsed, so the walkers and the serialiser were fuzzed too");

done_testing;
