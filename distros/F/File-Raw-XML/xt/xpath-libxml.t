#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);
use File::Raw::XML::XPath ();

# The same expressions against XML::LibXML, which is libxml2's XPath, on
# the same document. A disagreement is a bug in one of them and the
# specification sentence decides which; the ones already decided are in
# %DECIDED below, each with its sentence and with the answer this
# implementation gives. An expression that disagrees and is not there is
# a failure, and so is one that is there and now agrees, so the list can
# only shrink.

plan skip_all => 'XML::LibXML is not installed'
    unless eval { require XML::LibXML; 1 };

my $XML = '<?xml version="1.0"?><?pi dat?>'
        . '<r xmlns:p="urn:p" id="r0" xml:lang="en-GB">'
        .   '<a id="e1">1</a>'
        .   '<b><a id="e2">2</a><p:e>pe</p:e><!--cm--></b>'
        .   '<a>3</a>'
        .   '<q xmlns="urn:q"/>'
        . '</r>';

my %NS = (p => 'urn:p', q => 'urn:q', x => 'http://www.w3.org/XML/1998/namespace');

my $mine = file_xml_decode($XML, id_attrs => ['id']);
my $lx   = XML::LibXML->new(no_network => 1)->parse_string($XML);
my $ctx  = XML::LibXML::XPathContext->new($lx);
$ctx->registerNs($_, $NS{$_}) for keys %NS;

# Every one of these is libxml2 or its Perl binding departing from XPath
# 1.0, checked digit by digit when it was written.
my %DECIDED = (
    '/r/namespace::*' => [
        'N:p=urn:p|N:xml=http://www.w3.org/XML/1998/namespace',
        'XPath 5.4: an element has a namespace node for every namespace in '
      . 'scope, including the xml prefix, which is implicitly declared. '
      . "libxml2's own count() sees it; XML::LibXML's findnodes drops it.",
    ],
    '/r/b/namespace::*' => [
        'N:p=urn:p|N:xml=http://www.w3.org/XML/1998/namespace',
        'the same, on a descendant',
    ],
    'string(1 div 3)' => [
        '0.3333333333333333',
        'XPath 4.2: as many digits as are necessary to uniquely distinguish '
      . 'the value from all other IEEE 754 numeric values. Fifteen threes '
      . 'reads back as a different double; sixteen reads back as this one. '
      . 'libxml2 renders with a fixed fifteen significant digits.',
    ],
    'string(0.1 + 0.2)' => [
        '0.30000000000000004',
        'the same sentence: 0.1 + 0.2 is not the double 0.3, and printing it '
      . 'as 0.3 loses which double it was',
    ],
    'string(123456789012345678901234567890)' => [
        '123456789012345680000000000000',
        'XPath 4.2: the Number is never in exponential notation. libxml2 '
      . 'gives 1.23456789012346e+29, which is not a Number at all.',
    ],
    'string(0.000001)' => [
        '0.000001',
        'the same sentence, at the other end: libxml2 gives 1e-06',
    ],
    'string(0.0000001)' => [
        '0.0000001',
        'and 1e-07',
    ],
    'string(1e0 * 1)' => [
        'REFUSED',
        'XPath 3.7: Number is Digits ("." Digits?)? or "." Digits. There is '
      . 'no exponent, so "1e0" is the Number 1 followed by the name "e0", '
      . 'and a name where an operator belongs is an error. libxml2 accepts '
      . 'an exponent as an extension.',
    ],
    q{number('1e5')} => [
        'NaN',
        'XPath 4.4: a string is converted to a number when it is optional '
      . 'whitespace, an optional minus sign, a Number and optional '
      . 'whitespace, and to NaN otherwise. A Number has no exponent (3.7), '
      . 'so "1e5" is not one. libxml2 converts it with strtod.',
    ],
);

sub render_mine {
    my ($o) = @_;
    my $r = ref $o;
    return 'A:{' . $o->ns . '}' . $o->local . '=' . $o->value if $r eq 'File::Raw::XML::Attr';
    return 'N:' . $o->prefix . '=' . $o->uri                  if $r eq 'File::Raw::XML::Namespace';
    my $k = $o->kind;
    return 'E:{' . $o->ns . '}' . $o->local   if $k == 1;
    return 'T:' . $o->text                    if $k == 2;
    return 'C:' . $o->text                    if $k == 3;
    return 'P:' . $o->local . '=' . $o->text  if $k == 4;
    return 'D:';
}

sub render_lx {
    my ($o) = @_;
    my $t = $o->nodeType;
    return 'E:{' . ($o->namespaceURI // '') . '}' . $o->localname if $t == 1;
    return 'A:{' . ($o->namespaceURI // '') . '}' . $o->localname . '=' . $o->value if $t == 2;
    return 'T:' . $o->data if $t == 3 || $t == 4;
    return 'C:' . $o->data if $t == 8;
    return 'P:' . $o->nodeName . '=' . $o->textContent if $t == 7;
    return 'N:' . ($o->declaredPrefix // '') . '=' . ($o->declaredURI // '') if $t == 18;
    return 'D:' if $t == 9;
    return "?$t";
}

my @EXPR = grep { !/^\s*(?:#|$)/ } map { chomp; $_ } <DATA>;

for my $e (@EXPR) {
    my $is_set = eval { $ctx->find($e)->isa('XML::LibXML::NodeList') } ? 1 : 0;
    my ($m, $l);

    if ($is_set) {
        eval { $m = join '|', map { render_mine($_) } $mine->xpath($e, ns => \%NS); 1 }
            or $m = 'REFUSED';
        eval { $l = join '|', map { render_lx($_) } $ctx->findnodes($e); 1 }
            or $l = 'REFUSED';
    } else {
        eval { $m = scalar $mine->xpath("string($e)", ns => \%NS); 1 } or $m = 'REFUSED';
        eval { $l = $ctx->findvalue("string($e)"); 1 }                 or $l = 'REFUSED';
    }
    $_ = '' for grep { !defined } ($m, $l);

    my $decided = $DECIDED{$e};
    if ($m eq $l) {
        ok(!$decided, "$e: agrees with XML::LibXML")
            or diag("this is listed as a decided disagreement and now agrees; "
                  . "remove it from \%DECIDED:\n  $decided->[1]");
    } elsif ($decided) {
        is($m, $decided->[0], "$e: the decided disagreement, and this side is unchanged")
            or diag($decided->[1]);
    } else {
        fail("$e: disagrees with XML::LibXML and is not decided");
        diag("  mine: $m\n  libxml: $l\n"
           . "  find the sentence of XPath 1.0 that decides this before changing either");
    }
}

done_testing;

__DATA__
/
/*
//a
//a[1]
(//a)[1]
//a[2]
/r/a[1]
/r/a[last()]
/r/a[position() > 1]
//a[position() = 1][2]
//a[2][position() = 1]
//*
//node()
//text()
//comment()
//processing-instruction()
//processing-instruction('pi')
//@*
//@id
/r/@*
/r/namespace::*
/r/b/namespace::*
//b/preceding-sibling::*
//b/following-sibling::*
//b/preceding::*
//b/following::*
//b/ancestor::*
//b/ancestor-or-self::*
//b/descendant::*
//b/descendant-or-self::*
//b/self::*
//b/parent::*
//b/child::node()
//a/@id/parent::*
//a/@id/ancestor::*
//a/@id/self::node()
//a | //b
//a | //a
count(//a | //@id)
/r/*[@id]
/r/*[not(@id)]
//*[@id = 'e1']
//*[text()]
//a[. = '2']
//a[. != '2']
//a[number(.) > 1]
//*[count(a) = 2]
//*[local-name() = 'a']
//*[namespace-uri() = 'urn:p']
//p:*
//q:*
//q
//*[lang('en')]
//*[lang('EN-gb')]
//*[lang('fr')]
//*[@x:lang]
count(//a)
count(//@*)
count(//node())
count(/r/namespace::*)
sum(//a)
string(//a)
string(/r/@id)
string(//b)
local-name(//p:e)
namespace-uri(//p:e)
name(//p:e)
local-name(//@id)
name(/r/@x:lang)
local-name(//zz)
name(/r/namespace::p)
string(/r/namespace::p)
string-length('hello')
concat('a', 'b', 'c')
starts-with('abcd', 'ab')
starts-with('abcd', 'bc')
contains('abcd', 'bc')
contains('abcd', 'zz')
contains('abcd', '')
substring-before('1999/04/01', '/')
substring-after('1999/04/01', '/')
substring-before('abc', 'z')
substring('12345', 2, 3)
substring('12345', 2)
substring('12345', 1.5, 2.6)
substring('12345', 0, 3)
substring('12345', 0 div 0, 3)
substring('12345', 1, 0 div 0)
substring('12345', -42, 1 div 0)
substring('12345', -1 div 0, 1 div 0)
normalize-space('  a   b  c  ')
translate('bar', 'abc', 'ABC')
translate('--aaa--', 'abc-', 'ABC')
translate('abcdef', 'abc', 'x')
boolean(1)
boolean(0)
boolean(0 div 0)
boolean('')
boolean('x')
boolean(//zz)
not(1)
true()
false()
number('  12  ')
number('12.5')
number('.5')
number('-3')
number('12x')
number('')
number('1e5')
number('+1')
number(true())
number(false())
floor(1.5)
floor(-1.5)
ceiling(1.5)
ceiling(-1.5)
round(1.5)
round(-1.5)
round(0.5)
round(-0.5)
round(2.5)
round(0 div 0)
round(1 div 0)
1 div 0
-1 div 0
0 div 0
5 mod 2
5 mod -2
-5 mod 2
-5 mod -2
1 + 2 * 3
(1 + 2) * 3
- 3 + 4
1 = 1
1 = '1'
1 = true()
'1' = true()
'' = false()
0 = false()
'a' = 'a'
'a' = 'b'
//a = '1'
//a = 1
//a != '1'
//a > 1
//a < 1
//a = //b
//a = true()
//zz = true()
1 < 2 < 3
2 > 1 > 0
string(1 div 3)
string(-0)
string(0)
string(1000000)
string(1e0 * 1)
string(0.1 + 0.2)
string(123456789012345678901234567890)
string(0.000001)
string(0.0000001)
string(1 div 0)
string(-1 div 0)
string(0 div 0)
string(-1 div 0 + 1 div 0)
