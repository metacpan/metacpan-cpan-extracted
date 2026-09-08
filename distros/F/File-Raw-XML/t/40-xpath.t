#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use File::Raw::XML qw(:all);
use File::Raw::XML::XPath;

# XPath 1.0 (W3C Recommendation, 16 November 1999). The section beside
# each group is the one it transcribes. Every expected value here was
# cross-checked against XML::LibXML while it was written; the eight
# places the two disagree are in xt/xpath-libxml.t with the sentence that
# decides each, and they are all number formatting, the implicit xml
# namespace node, and `1e0`, which is not an XPath number.

my $XML = '<?xml version="1.0"?><?pi dat?>'
        . '<r xmlns:p="urn:p" id="r0" xml:lang="en-GB">'
        .   '<a id="e1">1</a>'
        .   '<b><a id="e2">2</a><p:e>pe</p:e><!--cm--></b>'
        .   '<a>3</a>'
        .   '<q xmlns="urn:q"/>'
        . '</r>';

my %NS  = (p => 'urn:p', x => 'http://www.w3.org/XML/1998/namespace');
my $doc = file_xml_decode($XML, id_attrs => ['id']);

# a node-set rendered so a whole result compares in one is()
sub render {
    my ($o) = @_;
    my $r = ref $o;
    return 'A:{' . $o->ns . '}' . $o->local . '=' . $o->value if $r eq 'File::Raw::XML::Attr';
    return 'N:' . $o->prefix . '=' . $o->uri                  if $r eq 'File::Raw::XML::Namespace';
    my $k = $o->kind;
    return 'E:{' . $o->ns . '}' . $o->local if $k == FRX_ELEMENT;
    return 'T:' . $o->text                  if $k == FRX_TEXT;
    return 'C:' . $o->text                  if $k == FRX_COMMENT;
    return 'P:' . $o->local . '=' . $o->text if $k == FRX_PI;
    return 'D:';
}

sub nodes { join '|', map { render($_) } $doc->xpath($_[0], ns => \%NS) }
sub str   { scalar $doc->xpath("string($_[0])", ns => \%NS) }

# ---- 2.5, the abbreviation that catches every implementation ------------
#
# `//` is `/descendant-or-self::node()/`, so the predicate of `//a[1]`
# belongs to the child::a step and selects the first `a` child of every
# element that has one. It is not the first `a` in the document.

is(nodes('//a'),      'E:{}a|E:{}a|E:{}a', '//a: every a, in document order');
is(nodes('//a[1]'),   'E:{}a|E:{}a',       '//a[1] is the first a child of each parent, not the first in the document');
is(nodes('(//a)[1]'), 'E:{}a',             '(//a)[1] is the first in the document');
is(str('(//a)[1]'),   '1',                 'and it is the one holding 1');
is(str('//a[2]'),     '3',                 '//a[2]: r has a second a child and b does not');

# ---- 2.1 and 2.2: the location path, and all thirteen axes -------------

is(nodes('/'),  'D:',    '/ is the root node, which is the document node');
is(nodes('/*'), 'E:{}r', '/* is the root element');

is(nodes('//b/self::*'),                'E:{}b',                'self');
is(nodes('//b/parent::*'),              'E:{}r',                'parent');
is(nodes('//b/child::node()'),          'E:{}a|E:{urn:p}e|C:cm', 'child, every kind');
is(nodes('//b/ancestor::*'),            'E:{}r',                'ancestor');
is(nodes('//b/ancestor-or-self::*'),    'E:{}r|E:{}b',          'ancestor-or-self, in document order once sorted');
is(nodes('//b/descendant::*'),          'E:{}a|E:{urn:p}e',     'descendant');
is(nodes('//b/descendant-or-self::*'),  'E:{}b|E:{}a|E:{urn:p}e', 'descendant-or-self');
is(nodes('//b/following-sibling::*'),   'E:{}a|E:{urn:q}q',     'following-sibling');
is(nodes('//b/preceding-sibling::*'),   'E:{}a',                'preceding-sibling');
is(nodes('//b/following::*'),           'E:{}a|E:{urn:q}q',     'following excludes descendants');
is(nodes('//b/preceding::*'),           'E:{}a',                'preceding excludes ancestors');
is(nodes('/r/@*'),
   'A:{}id=r0|A:{http://www.w3.org/XML/1998/namespace}lang=en-GB',
   'attribute, in document order');
is(nodes('/r/namespace::*'),
   'N:p=urn:p|N:xml=http://www.w3.org/XML/1998/namespace',
   'namespace: the in-scope bindings, with xml always among them (5.4)');
is(nodes('/r/b/namespace::*'),
   'N:p=urn:p|N:xml=http://www.w3.org/XML/1998/namespace',
   'and they are in scope on a descendant too');

# an attribute is a node of the axes as much as an element is
is(nodes('//a/@id/parent::*'),   'E:{}a|E:{}a',  'parent of an attribute is its element');
is(nodes('//a/@id/ancestor::*'), 'E:{}r|E:{}a|E:{}b|E:{}a', 'and its ancestors are the element chain');
is(nodes('//a/@id/self::node()'), 'A:{}id=e1|A:{}id=e2', 'self::node() on the attribute axis keeps the attribute');

# ---- 2.3: node tests ---------------------------------------------------

is(nodes('//*'), 'E:{}r|E:{}a|E:{}b|E:{}a|E:{urn:p}e|E:{}a|E:{urn:q}q', '* is every element');
is(nodes('//text()'),    'T:1|T:2|T:pe|T:3', 'text()');
is(nodes('//comment()'), 'C:cm',             'comment()');
is(nodes('//processing-instruction()'),     'P:pi=dat', 'processing-instruction()');
is(nodes('//processing-instruction("pi")'), 'P:pi=dat', 'with a target');
is(nodes('//processing-instruction("no")'), '',         'and a target that does not match');
is(str('count(//node())'), '13', 'node() on the child axis is every kind of child');
is(nodes('//p:*'), 'E:{urn:p}e', 'prefix:* is every element in that namespace');
is(nodes('//a[1]/@*'), 'A:{}id=e1|A:{}id=e2', '@* is every attribute');

# an unprefixed name test is a null namespace URI, never the default one
is(nodes('//q'), '', 'an unprefixed name test does not match a name in the default namespace');
{
    my $qns = $doc->xpath('//z:q', ns => { z => 'urn:q' });
    is(render($qns), 'E:{urn:q}q', 'and a bound prefix does, whatever prefix the document wrote');
}

# ---- 3.3: predicates, position() and last() ----------------------------

is(str('/r/a[last()]'), '3', 'last() over the child::a step');
is(nodes('/r/a[position() > 1]'), 'E:{}a', 'position() over the same');
is(nodes('//a[position() = 1][2]'), '',      'two predicates apply left to right: nothing is second');
is(nodes('//a[2][position() = 1]'), 'E:{}a', 'and the second, renumbered, is first');
is(str('//a[2][position() = 1]'),   '3',     'which is the a holding 3');
is(nodes('/r/*[@id]'),      'E:{}a',                 'a predicate over an attribute existence test');
is(nodes('/r/*[not(@id)]'), 'E:{}b|E:{}a|E:{urn:q}q', 'and its negation');
is(nodes('//*[count(a) = 2]'), 'E:{}r', 'a predicate calling a function over a nested path');

# a reverse axis counts its proximity position from the context node out
is(str('local-name(//p:e/ancestor::*[1])'), 'b', 'ancestor::*[1] is the nearest ancestor');
is(str('local-name(//p:e/ancestor::*[2])'), 'r', 'and [2] is the one above it');

# a function call is not a step: a location path is axis, node test and
# predicates, and FunctionName is a QName that is not a NodeType (3.7)
ok(!eval { $doc->xpath('//a/local-name()'); 1 }, 'a function call cannot be a step');

# ---- 3.4: the comparison rules, as a table -----------------------------

my @CMP = (
    # expression                 expected  what it exercises
    [ '1 = 1',            'true',  'number to number' ],
    [ q{1 = '1'},         'true',  'number to string: the string becomes a number' ],
    [ '1 = true()',       'true',  'number to boolean: both become booleans' ],
    [ q{'1' = true()},    'true',  'string to boolean: both become booleans' ],
    [ q{'' = false()},    'true',  'the empty string is false' ],
    [ '0 = false()',      'true',  'and so is zero' ],
    [ q{'a' = 'a'},       'true',  'string to string' ],
    [ q{'a' = 'b'},       'false', 'and unequal strings' ],
    [ q{//a = '1'},       'true',  'node-set to string: one node has that string-value' ],
    [ '//a = 1',          'true',  'node-set to number: one node numbers to it' ],
    [ q{//a != '1'},      'true',  'and != is existential too, so both can hold at once' ],
    [ '//a > 1',          'true',  'node-set relational: one node is greater' ],
    [ '//a < 1',          'false', 'and none is smaller' ],
    [ '//a = //b',        'false', 'node-set to node-set: no pair of string-values is equal' ],
    [ '//a = true()',     'true',  'node-set to boolean: a non-empty set is true' ],
    [ '//zz = true()',    'false', 'and an empty one is false' ],
    [ '1 < 2 < 3',        'true',  'relational is left-associative over booleans-as-numbers' ],
    [ '2 > 1 > 0',        'true',  'and so the second comparison is 1 > 0' ],
);
is(str($_->[0]), $_->[1], "3.4: $_->[0] is $_->[1] ($_->[2])") for @CMP;

# ---- 3.5: the arithmetic operators -------------------------------------

is(str('1 + 2 * 3'),   '7', 'multiplicative binds tighter than additive');
is(str('(1 + 2) * 3'), '9', 'and parentheses win');
is(str('- 3 + 4'),     '1', 'unary minus');
is(str('5 mod 2'),     '1',  'mod truncates towards zero');
is(str('5 mod -2'),    '1',  'so the sign follows the left operand');
is(str('-5 mod 2'),    '-1', 'as here');
is(str('-5 mod -2'),   '-1', 'and here');

# ---- 4.1: the node-set functions ---------------------------------------

is(str('count(//a)'),   '3', 'count');
is(str('count(//@*)'),  '4', 'count over attributes');
is(str('count(//zz)'),  '0', 'count of nothing');
is(str('sum(//a)'),     '6', 'sum');
is(str('string(//a)'),  '1', 'string of a node-set is its first node in document order');
is(str('string(//b)'),  '2pe', 'and a node string-value is its descendant text');
is(str('local-name(//p:e)'),    'e',     'local-name');
is(str('namespace-uri(//p:e)'), 'urn:p', 'namespace-uri');
is(str('name(//p:e)'),          'p:e',   'name is the qualified name as written');
is(str('local-name(//@id)'),    'id',    'local-name of an attribute');
is(str('name(/r/@x:lang)'),     'xml:lang', 'name of a prefixed attribute');
is(str('local-name(//zz)'),     '',      'local-name of an empty node-set is the empty string');
is(str('name(/r/namespace::p)'), 'p',    'a namespace node is named by its prefix');
is(str('string(/r/namespace::p)'), 'urn:p', 'and its string-value is the URI');
is(str('id("e1")'),      '1',   'id() over the index the document was parsed with');
is(str('count(id("e1 e2"))'), '2', 'id() splits on whitespace');
is(str('count(id("nope"))'),  '0', 'and finds nothing for an unknown one');

# ---- 4.2: the string functions -----------------------------------------

is(str(q{concat('a', 'b', 'c')}), 'abc', 'concat is variadic');
is(str(q{starts-with('abcd', 'ab')}), 'true',  'starts-with');
is(str(q{starts-with('abcd', 'bc')}), 'false', 'and only at the start');
is(str(q{contains('abcd', 'bc')}), 'true',  'contains');
is(str(q{contains('abcd', 'zz')}), 'false', 'and not');
is(str(q{contains('abcd', '')}),   'true',  'the empty string is contained');
is(str(q{substring-before('1999/04/01', '/')}), '1999',  'substring-before');
is(str(q{substring-after('1999/04/01', '/')}),  '04/01', 'substring-after');
is(str(q{substring-before('abc', 'z')}), '', 'and the empty string when there is no match');

# an empty node-set reaches these as the empty string, and the empty
# string is a prefix and a substring of itself
is(str('contains(//zz, "")'),          'true',  'contains over an empty node-set and an empty needle');
is(str('starts-with(//zz, "")'),       'true',  'and starts-with');
is(str('contains(//zz, "x")'),         'false', 'and a needle that is not there');
is(str('substring-before(//zz, "")'),  '',      'substring-before of nothing');
is(str('substring-after(//zz, "")'),   '',      'substring-after of nothing');
is(str(q{substring-after('abc', '')}), 'abc',   'and after the empty prefix of a string');

# 4.2's own examples for substring, infinities included
is(str(q{substring('12345', 2, 3)}),   '234',   'substring');
is(str(q{substring('12345', 2)}),      '2345',  'substring to the end');
is(str(q{substring('12345', 1.5, 2.6)}), '234', 'the arguments are rounded');
is(str(q{substring('12345', 0, 3)}),   '12',    'a start before the string');
is(str(q{substring('12345', 0 div 0, 3)}), '',  'a NaN start selects nothing');
is(str(q{substring('12345', 1, 0 div 0)}), '',  'nor does a NaN length');
is(str(q{substring('12345', -42, 1 div 0)}), '12345', 'an infinite length reaches the end');
is(str(q{substring('12345', -1 div 0, 1 div 0)}), '', 'and -Infinity + Infinity is NaN, so nothing');

is(str(q{string-length('hello')}), '5', 'string-length');
is(str(q{normalize-space('  a   b  c  ')}), 'a b c', 'normalize-space strips and collapses');
is(str(q{translate('bar', 'abc', 'ABC')}), 'BAr', 'translate');
is(str(q{translate('--aaa--', 'abc-', 'ABC')}), 'AAA', 'a character with no replacement is removed');
is(str(q{translate('abcdef', 'abc', 'x')}), 'xdef', 'and so is one past the end of the replacement');

# by character, not by byte. The expression crosses the seam as its UTF-8
# bytes when it is flagged as characters and as its raw bytes when it is
# not, which is what every other input to this dist does, so a Latin-1
# byte string is not an expression and is refused.
{
    my $e = q{substring('} . "\x{e9}\x{ea}\x{eb}" . q{', 2, 1)};
    utf8::upgrade($e);
    is(scalar $doc->xpath("string($e)"), "\x{ea}", 'substring is by character');

    my $len = q{string-length('h} . "\x{e9}" . q{llo')};
    utf8::upgrade($len);
    is(scalar $doc->xpath("string($len)"), '5', 'string-length counts characters');

    my $tr = q{translate('} . "\x{e9}" . q{x', '} . "\x{e9}" . q{', 'e')};
    utf8::upgrade($tr);
    is(scalar $doc->xpath("string($tr)"), 'ex', 'and so is translate');

    my $latin1 = $e;
    utf8::downgrade($latin1);
    ok(!eval { $doc->xpath("string($latin1)"); 1 }, 'a Latin-1 byte expression is not UTF-8 and is refused');
    like($@, qr/the expression is not UTF-8/, '  saying so');
}

# ---- 4.3: the boolean functions ----------------------------------------

is(str('boolean(1)'),      'true',  'boolean of a non-zero number');
is(str('boolean(0)'),      'false', 'of zero');
is(str('boolean(0 div 0)'), 'false', 'of NaN');
is(str(q{boolean('')}),    'false', 'of the empty string');
is(str(q{boolean('x')}),   'true',  'of a non-empty one');
is(str('boolean(//a)'),    'true',  'of a non-empty node-set');
is(str('boolean(//zz)'),   'false', 'of an empty one');
is(str('not(1)'),          'false', 'not');
is(str('true()'),          'true',  'true');
is(str('false()'),         'false', 'false');
is(str('local-name(//*[lang("en")])'), 'r', 'lang() matches a language subtag of xml:lang');
is(str('count(//*[lang("en")])'), '7', 'and xml:lang is inherited by every descendant');
is(str('count(//*[lang("fr")])'), '0', 'and does not match another language');
is(str('count(//*[lang("EN-gb")])'), '7', 'the comparison is case-insensitive');
is(str('count(//*[lang("en-GB-x")])'), '0', 'and a longer tag does not match a shorter value');

# ---- 4.4: the number functions -----------------------------------------

is(str(q{number('  12  ')}), '12',   'number strips surrounding whitespace');
is(str(q{number('12.5')}),   '12.5', 'a fraction');
is(str(q{number('.5')}),     '0.5',  'a leading point');
is(str(q{number('-3')}),     '-3',   'a minus');
is(str(q{number('12x')}),    'NaN',  'anything else is NaN');
is(str(q{number('')}),       'NaN',  'including the empty string');
is(str(q{number('1e5')}),    'NaN',  'and an exponent, which is not a Number');
is(str(q{number('+1')}),     'NaN',  'and a plus sign');
is(str('number(true())'),    '1',    'a boolean numbers to 1');
is(str('number(false())'),   '0',    'or 0');

is(str('floor(1.5)'),   '1',  'floor');
is(str('floor(-1.5)'),  '-2', 'floor of a negative');
is(str('ceiling(1.5)'), '2',  'ceiling');
is(str('ceiling(-1.5)'), '-1', 'ceiling of a negative');
is(str('round(1.5)'),   '2',  'round');
is(str('round(2.5)'),   '3',  'a tie goes towards positive infinity');
is(str('round(-1.5)'),  '-1', 'so -1.5 rounds to -1');
is(str('round(0.5)'),   '1',  'and 0.5 to 1');
is(str('round(-0.5)'),  '0',  'and -0.5 to negative zero, which prints as 0');
is(str('round(0 div 0)'), 'NaN', 'round of NaN');
is(str('round(1 div 0)'), 'Infinity', 'round of an infinity');

# ---- 4.2's number to string: no exponent, shortest round trip ----------

is(str('string(0)'),       '0',       'zero');
is(str('string(-0)'),      '0',       'negative zero prints as 0');
is(str('string(1000000)'), '1000000', 'an integer has no fraction');
is(str('string(1 div 0)'),  'Infinity',  'positive infinity');
is(str('string(-1 div 0)'), '-Infinity', 'negative infinity');
is(str('string(0 div 0)'),  'NaN',       'NaN');
is(str('string(-1 div 0 + 1 div 0)'), 'NaN', 'and an infinity less an infinity');
is(str('string(1 div 3)'), '0.3333333333333333',
   'as many digits as distinguish the value: fifteen threes is a different double');
is(str('string(0.1 + 0.2)'), '0.30000000000000004',
   'and 0.1 + 0.2 is not 0.3');
is(str('string(0.000001)'),  '0.000001',  'no exponent, however small');
is(str('string(0.0000001)'), '0.0000001', 'still no exponent');
is(str('string(123456789012345678901234567890)'), '123456789012345680000000000000',
   'no exponent, however large, and the digits are the double the literal names');

# ---- 3.3: union --------------------------------------------------------

is(nodes('//a | //b'), 'E:{}a|E:{}b|E:{}a|E:{}a', 'a union is in document order');
is(nodes('//a | //a'), 'E:{}a|E:{}a|E:{}a',       'and has no duplicates');
is(str('count(//a | //@id)'), '6', 'attributes and elements sort together');

# ---- the Perl surface --------------------------------------------------

{
    my @all = $doc->xpath('//a', ns => \%NS);
    is(scalar @all, 3, 'list context gives every node');
    my $one = $doc->xpath('//a', ns => \%NS);
    isa_ok($one, 'File::Raw::XML::Node', 'scalar context gives one node, which');
    is($one->text, '1', 'and it is the first in document order');
    is(scalar($doc->xpath('//zz')), undef, 'an empty node-set in scalar context is undef');
    is_deeply([$doc->xpath('//zz')], [], 'and an empty list in list context');
}

{
    my ($attr) = $doc->xpath('/r/@id');
    isa_ok($attr, 'File::Raw::XML::Attr');
    is($attr->name,  'id',   'an attribute knows its name');
    is($attr->local, 'id',   'its local part');
    is($attr->ns,    '',     'its namespace, empty when it has none');
    is($attr->prefix, '',    'and its prefix');
    is($attr->value, 'r0',   'and its value');
    is($attr->owner->local, 'r', 'and the element it is on');
    isa_ok($attr->doc, 'File::Raw::XML::Document', 'and its document, which');

    my ($lang) = $doc->xpath('/r/@x:lang', ns => \%NS);
    is($lang->name,   'xml:lang', 'a prefixed attribute keeps the name as written');
    is($lang->prefix, 'xml',      'and its prefix');
    is($lang->ns, 'http://www.w3.org/XML/1998/namespace', 'and its namespace');
}

{
    my ($ns) = $doc->xpath('/r/namespace::p', ns => \%NS);
    isa_ok($ns, 'File::Raw::XML::Namespace');
    is($ns->name,   'p',     'a namespace node is named by its prefix');
    is($ns->prefix, 'p',     'which is also its prefix');
    is($ns->uri,    'urn:p', 'and its URI');
    is($ns->value,  'urn:p', 'which is its value too');
    is($ns->owner->local, 'r', 'and the element it is in scope on');
}

# a node from a result keeps its document alive, as a Node does
{
    my ($node, $attr, $nsn, $weak);
    {
        my $d = file_xml_decode('<a xmlns:z="urn:z" k="v"><b/></a>');
        $weak = $d;
        weaken($weak);
        ($node) = $d->xpath('//b');
        ($attr) = $d->xpath('//@k');
        ($nsn)  = $d->xpath('/a/namespace::z');
    }
    ok(defined $weak, 'the document is alive while a result holds it');
    is($node->local, 'b',     'a node from a result answers after the document lexical is gone');
    is($attr->value, 'v',     'and so does an attribute');
    is($nsn->uri,    'urn:z', 'and a namespace node');
    undef $node; undef $attr;
    ok(defined $weak, 'and it is still alive while the namespace node holds it');
    undef $nsn;
    ok(!defined $weak, 'and freed when the last one goes');
}

# ---- the compiled object -----------------------------------------------

{
    my $xp = File::Raw::XML::XPath->new('count(//a)');
    is($xp->find($doc), 3, 'a compiled expression evaluates');
    is($xp->find($doc), 3, 'and evaluates again');
    my $other = file_xml_decode('<r><a/><a/></r>');
    is($xp->find($other), 2, 'and against another document, holding neither');

    my $rel = File::Raw::XML::XPath->new('count(a)');
    is($rel->find($doc->root), 2, 'a relative expression is evaluated at the node it is given');
    is($rel->find($doc), 0, 'and the document node has no a children');
}

{
    my $xp = File::Raw::XML::XPath->new(
        '//p:e[../a/@id = $want]',
        ns   => \%NS,
        vars => { want => 'e2' },
    );
    is(render(scalar $xp->find($doc)), 'E:{urn:p}e', 'a variable is bound at compile');

    my $n = File::Raw::XML::XPath->new('$v + 1', vars => { v => 41 });
    is($n->find($doc), 42, 'a numeric variable stays a number');
    my $s = File::Raw::XML::XPath->new('string($v)', vars => { v => '007' });
    is($s->find($doc), '007', 'and a string variable stays a string');
}

is($doc->xpath('string(//p:e)', ns => \%NS), 'pe', 'the per-call form on a document');
is($doc->root->xpath('string(b/p:e)', ns => \%NS), 'pe', 'and on a node');
ok(utf8::is_utf8($doc->xpath('string(//a)')), 'a string result is a character string');
is(file_xml_decode("<r>\xC3\xA9</r>")->xpath('string(/r)'), "\x{e9}",
   'and carries the characters it should');

# ---- refusals ----------------------------------------------------------

my @BAD = (
    [ '//q:e',            qr/the prefix of a name test is not in the expression's namespace map/,
      'an unmapped prefix is a compile error' ],
    [ '//a[',             qr/File::Raw::XML: /,             'an unclosed predicate' ],
    [ '//a[1',            qr/a predicate is never closed/,  'an unclosed bracket' ],
    [ '(1',               qr/never closed/,                 'an unclosed parenthesis' ],
    [ 'nosuch()',         qr/not one of the 27 core functions/, 'an unknown function' ],
    [ 'count()',          qr/wrong number of arguments/,    'too few arguments' ],
    [ 'count(1, 2)',      qr/wrong number of arguments/,    'too many' ],
    [ 'nosuch::a',        qr/not one of the thirteen axis names/, 'an unknown axis' ],
    [ '1 +',              qr/a node test was expected/,     'a missing operand' ],
    [ '1 2',              qr/more after its end/,           'two expressions' ],
    [ q{'unclosed},       qr/never closed/,                 'an unclosed literal' ],
    [ '1e0',              qr/an operator was expected here/, 'an exponent, which is not an XPath number' ],
);
for my $case (@BAD) {
    my ($expr, $re, $why) = @$case;
    ok(!eval { $doc->xpath($expr, ns => \%NS); 1 }, "refused: $expr ($why)");
    like($@, $re, "  with a message naming why");
}

ok(!eval { $doc->xpath('count(1)'); 1 }, 'count() of a number is an evaluation error');
like($@, qr/take a node-set/, '  naming the type');
ok(!eval { $doc->xpath('1 | 2'); 1 }, 'a union of non-node-sets is an error');
like($@, qr/joins two node-sets/, '  naming the operator');
ok(!eval { $doc->xpath('$nope'); 1 }, 'an unbound variable is refused');
like($@, qr/uses \$nope and no value was given/, '  naming the variable');
ok(!eval { $doc->xpath('$v', vars => { v => [] }); 1 }, 'a reference is not a variable value');
like($@, qr/must be a string or a number/, '  saying what one is');

# The variable's name lives in the compiled expression's arena, and both
# messages above are raised after that expression has been freed, so a
# message that read the name where it used to be would be a use-after-free.
# A long name is what makes a stale read show as something other than the
# name: ASan reports it either way, and this asserts the name is whole.
{
    my $long = 'v' . ('ariable' x 20);
    ok(!eval { $doc->xpath("\$$long"); 1 }, 'a long unbound variable name is refused');
    like($@, qr/uses \$\Q$long\E and no value was given/,
         '  and the name in the message is whole, not read back out of the freed expression');
    ok(!eval { $doc->xpath("\$$long", vars => { $long => {} }); 1 },
       'and a reference given for one');
    like($@, qr/of \$\Q$long\E must be a string or a number/, '  the same there');
}
ok(!eval { $doc->xpath('//a', nope => 1); 1 }, 'an unknown option is refused');
like($@, qr/unknown option 'nope'/, '  naming it');

# a compile refusal names the offset in the expression, in the one shape
ok(!eval { $doc->xpath('//a[1'); 1 }, 'an unclosed predicate is refused');
like($@, qr/^File::Raw::XML: .* at (?:byte offset \d+|end of input)/,
     'and the message is the shape every other refusal uses');

# ---- max_expr_depth ----------------------------------------------------

{
    my $deep = '(' x 70 . '1' . ')' x 70;
    ok(!eval { $doc->xpath($deep); 1 }, 'an expression nesting past the default depth is refused');
    like($@, qr/nests deeper than max_expr_depth/, '  naming the budget');
    ok(eval { $doc->xpath($deep, max_expr_depth => 128); 1 }, 'and a larger budget accepts it');

    # the depth is the compiled form's, so a long chain of one operator
    # counts as deeply as it is long: that is what the evaluator recurses
    my $chain = join ' and ', ('1') x 200;
    ok(!eval { $doc->xpath($chain); 1 }, 'a long chain of `and` is bounded too');
    like($@, qr/nests deeper than max_expr_depth/, '  by the same budget');
    ok(eval { $doc->xpath($chain, max_expr_depth => 256); 1 }, 'and a larger budget accepts that');
}

# ---- the invocant checks -----------------------------------------------

{
    my $xp = File::Raw::XML::XPath->new('1');
    ok(!eval { File::Raw::XML::XPath::find($doc, $doc); 1 }, 'find on a Document is not find on an XPath');
    like($@, qr/the invocant is not a File::Raw::XML::XPath/, '  naming the class');
    my ($attr) = $doc->xpath('/r/@id');
    ok(!eval { File::Raw::XML::Namespace::name($attr); 1 }, 'an Attr is not a Namespace');
    like($@, qr/the invocant is not a File::Raw::XML::Namespace/, '  naming that class too');
    ok(!eval { File::Raw::XML::Node::local($attr); 1 }, 'nor is it a Node');
    like($@, qr/the invocant is not a File::Raw::XML::Node/, '  naming that one');
}

# ---- document order across a mutated tree ------------------------------
#
# An edit marks `order` stale rather than paying to keep it current; the
# first evaluation after one renumbers the document in a single walk. A
# node-set is sorted by `order`, so every one of these would come back in
# the wrong order if that did not happen.

SKIP: {
    skip 'the mutable tree is not in this build', 8
        unless File::Raw::XML::Document->can('new_element');

    my $d = file_xml_decode('<r><a>1</a><b/><a>2</a></r>');
    is(join(',', map { $_->text } $d->xpath('//a')), '1,2', 'before any edit');

    my $new = $d->new_element('', 'a');
    $new->set_text('0');
    my ($b) = $d->xpath('//b');
    $b->insert_before($new);

    is(join(',', map { $_->text } $d->xpath('//a')), '1,0,2',
       'a node inserted in the middle sorts in the middle');
    is(scalar($d->xpath('/r/a[1]'))->text,      '1', 'and the first is still the first');
    is(scalar($d->xpath('/r/a[last()]'))->text, '2', 'and last() still counts to the end');
    is(join(',', map { $_->local } $d->xpath('//b/preceding-sibling::*')), 'a,a',
       'a reverse axis sees it too');

    my ($first) = $d->xpath('//a');
    $first->detach;
    is(join(',', map { $_->text } $d->xpath('//a')), '0,2', 'a detached node leaves the set');
    is(scalar($d->xpath('count(/r/*)')), 3, 'and the count follows');

    # a compiled expression is not tied to the tree it first saw
    my $xp = File::Raw::XML::XPath->new('count(//a)');
    my $before = $xp->find($d);
    $d->root->append($d->new_element('', 'a'));
    is($xp->find($d), $before + 1, 'a compiled expression sees an edit made after it was compiled');
}

# ---- the strict profile is untouched -----------------------------------

{
    my $s = file_xml_decode('<r><a>x</a></r>');
    is($s->xpath('string(//a)'), 'x', 'XPath works under the strict profile too');
    is($s->xpath('count(//a)'), 1, 'and counts there');
}

done_testing;
