#!/usr/bin/perl -T

use strict; use warnings; use lib 't';

use Test::More tests => 17;
use utf8;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Test 2: constructor

our $elem = (our $doc = new HTML::DOM)->createElement('div');
$elem->appendChild(our $t = createTextNode $doc 'text contents');
isa_ok $t, 'HTML::DOM::CharacterData';

# -------------------------#
# Tests 3-9: splitText

eval { $t-> splitText(-9) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after splitText with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'splitText with a negative offset throws a index size error';

eval { $t-> splitText(89) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after splitText when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'splitText throws a index size error when offset > length';

# All right, enough of this playing. Let's do it for real tnow.

our $u = $t->splitText(5);
is $t->data, 'text ', 'text node loses part of its text after splitText';
is $u->data, 'contents', 'the new text node got it';
ok firstChild $elem == $t && (childNodes $elem)[1] == $u &&
	lastChild$elem == $u, 'the tree was modified correctly';

$elem->removeChild($u);

# -------------------------#
# Tests 10-16: splitText16

eval { $t-> splitText16(-9) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after splitText16 with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'splitText16 with a negative offset throws a index size error';

eval { $t-> splitText16(89) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after splitText16 when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'splitText throws a index size error when offset > length';

# All right, enough of this playing. Let's do it for real tnow.

$t->data('π 𐅽 3.14');
$u = $t->splitText16(5);
is $t->data, 'π 𐅽 ', 'text node loses part of its text after splitText16';
is $u->data, '3.14', 'and it was the new text node that got it';
ok firstChild $elem == $t && (childNodes $elem)[1] == $u &&
	lastChild$elem == $u,
	'the tree was modified correctly by splitText16';

# -------------------------#
# Test 17: nodeValue

is $doc->createTextNode('aoeusnth')->nodeValue, 'aoeusnth', 'nodeValue';
