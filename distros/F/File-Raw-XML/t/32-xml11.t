#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# XML 1.1 (second edition, 16 August 2006) under the full profile: the
# 2.11 line ends, the restricted characters of 2.2 refused literal and
# admitted by reference, the names of 2.3, and canonicalisation over the
# result. Under strict the declaration is refused with 0.01's message.

sub full    { my ($b, %o) = @_; file_xml_decode($b, profile => 'full', %o) }
sub refused { my ($b, %o) = @_; my $ok = eval { full($b, %o); 1 }; $ok ? '' : $@ }
sub bytes   { my ($s) = @_; utf8::encode($s); $s }
sub v11     { my ($body) = @_; bytes(qq{<?xml version="1.1"?>$body}) }
sub v10     { my ($body) = @_; bytes(qq{<?xml version="1.0"?>$body}) }

# the deliverable
{
    my $doc = full(v11(qq{<r>a\x{85}b\x{2028}c\r\x{85}d\r\ne\rf&#x1;g</r>}));
    is($doc->root->text, "a\nb\nc\nd\ne\nf\x{1}g",
       '1.1: NEL, LS, CR NEL, CRLF and CR all become LF; &#x1; is U+0001');
    like(refused(v11(qq{<r>a\x{1}b</r>})), qr/restricted character may appear only as a character reference in XML 1.1 at byte offset 25/,
         '1.1: a literal U+0001 is refused at its offset');
    ok(!eval { file_xml_decode(v11('<r/>')); 1 }, 'strict refuses a 1.1 declaration');
    like($@, qr/^File::Raw::XML: only XML version 1.0 is accepted at byte offset 0/, 'with 0.01\'s message at offset 0');
}

# the 1.0 path is untouched
{
    my $doc = full(v10(qq{<r>a\x{85}b\x{2028}c</r>}));
    is($doc->root->text, "a\x{85}b\x{2028}c", '1.0: NEL and LS are ordinary characters');
    like(refused(v10(qq{<r>&#x1;</r>})), qr/non-XML character/, '1.0: &#x1; is not a Char');
    like(refused(v10(qq{<r>a\x{1}b</r>})), qr/control character is not allowed/, '1.0: a literal U+0001 is refused with the 1.0 message');
    is(full(v10(qq{<r>a\x{7f}\x{84}\x{9f}</r>}))->root->text, "a\x{7f}\x{84}\x{9f}", '1.0: U+007F, U+0084 and U+009F are Char, accepted literal');
    is(full(bytes(qq{<r>a\x{85}b</r>}))->root->text, "a\x{85}b", 'no declaration means 1.0');
}

# restricted characters, both ways
{
    for my $cp (0x1, 0x8, 0xB, 0xC, 0xE, 0x1F, 0x7F, 0x84, 0x86, 0x9F) {
        my $lit = chr($cp);
        like(refused(v11(qq{<r>x${lit}y</r>})), qr/restricted character/, sprintf('1.1: literal U+%04X is refused', $cp));
        is(full(v11(sprintf('<r>x&#x%X;y</r>', $cp)))->root->text, "x${lit}y", sprintf('1.1: &#x%X; is admitted', $cp));
    }
    is(full(v11(qq{<r>&#x85;&#x2028;</r>}))->root->text, "\x{85}\x{2028}", '1.1: NEL and LS by reference are not line ends and stay');
    like(refused(v11('<r>&#x0;</r>')), qr/non-XML character/, '1.1: &#x0; is refused, as in 1.0');
    like(refused(v11(qq{<r>\x{0}</r>})), qr/control character/, '1.1: a literal NUL is refused');
    is(full(v11(qq{<r>\x{9}\x{a}\x{d}\x{20}\x{a0}</r>}))->root->text, "\x{9}\x{a}\x{a}\x{20}\x{a0}", '1.1: TAB, LF, CR (normalised), SPACE and NBSP are fine literal');
    like(refused(v11(qq{<r><!-- \x{1} --></r>})), qr/restricted character/, '1.1: a restricted character in a comment');
    like(refused(v11(qq{<r><![CDATA[\x{7f}]]></r>})), qr/restricted character/, 'in CDATA');
    like(refused(v11(qq{<r><?p \x{84}?></r>})), qr/restricted character/, 'in a PI');
    like(refused(v11(qq{<r a="\x{1}"/>})), qr/restricted character/, 'in an attribute value');
}

# attribute values: 2.11 then 3.3.3
{
    my $r = full(v11(qq{<r a="x\x{85}y\x{2028}z\r\x{85}w\r\nv" b="&#x85;"/>}))->root;
    is($r->attr('a'), 'x y z w v', '1.1: every line end in an attribute value is one space');
    is($r->attr('b'), "\x{85}", 'and a referenced NEL stays');
}

# names: 2.3's productions are the ones XML 1.0 fifth edition adopted,
# so the same names are accepted under both versions
{
    ok(full(v11(qq{<r x\x{b7}y="1"><a\x{b7}b/></r>})), '1.1: MIDDLE DOT is a NameChar, as 2.3 says');
    ok(full(v10(qq{<r x\x{b7}y="1"><a\x{b7}b/></r>})), 'and under 1.0 fifth edition');
    like(refused(v11(qq{<r\x{37e}/>})), qr/unterminated start tag|expected/, '1.1: GREEK QUESTION MARK U+037E is excluded, as 2.3 says');
    like(refused(v10(qq{<r\x{37e}/>})), qr/unterminated start tag|expected/, 'and under 1.0');
    ok(full(v11(qq{<\x{1218}\x{130d}\x{1265}/>})), '1.1: an Ethiopic name, from a script the 1.0 fourth edition tables lacked');
    ok(full(v10(qq{<\x{1218}\x{130d}\x{1265}/>})), 'accepted under 1.0 too: the fifth edition took 1.1\'s tables');
}

# the version on the document, and canonicalisation over the data model
{
    my $doc = full(v11(qq{<r xmlns="urn:d" a="1\x{85}2">t\x{2028}u<!-- c --><b>&#x1;</b></r>}));
    for my $mode (qw(exclusive inclusive inclusive-1.1)) {
        is($doc->c14n(mode => $mode, comments => 1),
           qq{<r xmlns="urn:d" a="1 2">t\nu<!-- c --><b>\x{1}</b></r>},
           "a 1.1 document canonicalises under $mode with no declaration and its normalised text");
    }
    my $doc10 = full(v10(qq{<r xmlns="urn:d" a="1 2">t\nu<!-- c --><b>x</b></r>}));
    is($doc10->c14n(comments => 1), qq{<r xmlns="urn:d" a="1 2">t\nu<!-- c --><b>x</b></r>}, 'and a 1.0 document the same way');
}

# XML 1.0 fifth edition section 2.8: a 1.x version this processor does not
# know is processed as 1.0 under full, and the declared string is kept
{
    my $doc = full(bytes(qq{<?xml version="1.7"?><r>a\x{85}b</r>}));
    is($doc->version, '1.7', 'version="1.7" is accepted under full, and reported as declared');
    is($doc->root->text, "a\x{85}b", 'and processed as 1.0: NEL is an ordinary character');
    like(refused(qq{<?xml version="2.0"?><r/>}), qr/only XML version 1.0 is accepted at byte offset 0/, 'a 2.x is not a 1.x');
    like(refused(qq{<?xml version="1.x"?><r/>}), qr/only XML version 1.0 is accepted/, 'nor is a 1.x that is not digits');
    ok(!eval { file_xml_decode(qq{<?xml version="1.7"?><r/>}); 1 }, 'strict refuses it as 0.01 did');
    is(full('<r/>')->version, '1.0', 'no declaration is 1.0');
    is(full(qq{<?xml version="1.1"?><r/>})->version, '1.1', 'and 1.1 is 1.1');
}

# 1.1 in another encoding: the transcoder runs first, then the version
{
    require Encode;
    my $doc = full("\xFF\xFE" . Encode::encode('UTF-16LE', qq{<?xml version="1.1" encoding="UTF-16"?><r>a\x{85}b</r>}));
    is($doc->root->text, "a\nb", 'a UTF-16 XML 1.1 document normalises its NEL');
}

done_testing;
