#!/usr/bin/perl -T

# This script tests the CharacterData interface. Since objects are never
# blessed into the HTML::DOM::CharacteData class, I am using a comment node
# to test the interface.

use strict; use warnings; use lib 't';

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use utf8;
use HTML::DOM;

# -------------------------#
use tests 1; # constructor

my $doc = new HTML::DOM; # We need this because the ownerDocument attri-
                                     # bute holds a weak ref,  and muta-
my $c = createComment{$doc}'comment contents';   # tion events will die
isa_ok $c, 'HTML::DOM::CharacterData';                      # otherwise.

# -------------------------#
use tests 8; # attributes

is data $c, 'comment contents', 'get data';
is nodeValue $c, 'comment contents', 'get nodeValue';
is $c->data('new content'), 'comment contents', 'set data';
is $c->data(), 'new content', 'get data after setting';
is $c->nodeValue('new contents'), 'new content', 'set nodeValue';
is $c->nodeValue, 'new contents', 'get nodeValue after setting';

$c->data('π𐅽3.14');
is $c->length, 6, 'length';
is $c->length16, 7, 'length16';

$c->data('new contents');

# -------------------------#
use tests 6; # substringData

is $c->substringData(3,4), ' con', 'substringData';
is $c->substringData(3,27866), ' contents',
	'substringData when the length arg is too long';
eval { $c->substringData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after substringData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'substringData with a negative offset throws a index size error';
eval { $c->substringData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after substringData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'substringData throws a index size error when offset > length';

# -------------------------#
use tests 2; # appendData

is_deeply [appendData $c '++'],[], 'appendData returns nothing';
is data $c, 'new contents++', 'result of appendData';

# -------------------------#
use tests 6; # insertData

is_deeply [insertData $c 0, '++'],[], 'insertData returns nothing';
is data $c, '++new contents++', 'result of insertData';
eval { $c-> insertData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after insertData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'insertData with a negative offset throws a index size error';
eval { $c-> insertData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after insertData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'insertData throws a index size error when offset > length';

# -------------------------#
use tests 6; # deleteData

is_deeply [deleteData $c 2, 4],[], 'deleteData returns nothing';
is data $c, '++contents++', 'result of deleteData';
eval { $c-> deleteData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after deleteData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'deleteData with a negative offset throws a index size error';
eval { $c-> deleteData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after deleteData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'deleteData throws a index size error when offset > length';

# -------------------------#
use tests 6; # replaceData

is_deeply [replaceData $c 2, 1, 'C'],[], 'replaceData returns nothing';
is data $c, '++Contents++', 'result of replaceData';
eval { $c-> replaceData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after replaceData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'replaceData with a negative offset throws a index size error';
eval { $c-> replaceData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after replaceData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'replaceData throws a index size error when offset > length';

# -------------------------#
use tests 7; # substringData16

$c->data('π𐅽3.14');

is $c->substringData16(3,3), '3.1', 'substringData16';
is ord $c->substringData16(2,1), 0xdd7d;
is $c->substringData16(3,27866), '3.14',
	'substringData16 when the length arg is too long';
eval { $c->substringData16(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after substringData16 with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'substringData16 with a negative offset throws a index size error';
eval { $c->substringData16(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after substringData16 when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'substringData16 throws a index size error when offset > length';

# -------------------------#
use tests 6; # insertData16

is_deeply [insertData16 $c 3, ' '],[], 'insertData16 returns nothing';
is data $c, 'π𐅽 3.14', 'result of insertData16';
eval { $c-> insertData16(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after insertData16 with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'insertData16 with a negative offset throws a index size error';
eval { $c-> insertData16(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after insertData16 when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'insertData16 throws a index size error when offset > length';

# -------------------------#
use tests 6; # deleteData16

is_deeply [deleteData16 $c 3, 1],[], 'deleteData16 returns nothing';
is data $c, 'π𐅽3.14', 'result of deleteData16';
eval { $c-> deleteData16(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after deleteData16 with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'deleteData16 with a negative offset throws a index size error';
eval { $c-> deleteData16(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after deleteData16 when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'deleteData16 throws a index size error when offset > length';

# -------------------------#
use tests 6; # replaceData16

is_deeply [replaceData16 $c 1, 2, ' 𐅽 '],[],
	'replaceData16 returns nothing';
is data $c, 'π 𐅽 3.14', 'result of replaceData16';
eval { $c-> replaceData16(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after replaceData16 with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'replaceData16 with a negative offset throws a index size error';
eval { $c-> replaceData16(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after replaceData16 when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'replaceData16 throws a index size error when offset > length';
