#!perl -T

use strict;
use warnings;

use Test::More;

use Encoding::FixLatin qw(fix_latin);
use Encoding::FixLatin::XS;

is(length(fix_latin("a b")), 3,
    "string length for simple ascii input looks OK");

is(length(fix_latin("a\xC2\xA0b")), 3,
    "string length for utf8 input looks OK");

is(length(fix_latin("a\xA0b")), 3,
    "string length for latin-1 input looks OK");

is(length(fix_latin("a\xC2\xA0b", bytes_only => 1)), 4,
    "string length for utf8 input looks OK");

is(length(fix_latin("a\xA0b", bytes_only => 1)), 4,
    "string length for utf8 input looks OK");

is(fix_latin("M\x{101}ori", bytes_only => 1) => "M\xC4\x81ori",
    'UTF-8 string converted to bytes');

is(fix_latin("\xE0\x83\x9A", bytes_only => 1) => "\xC3\x9A",
    'Over-long UTF-8 string shortened to correct bytes');

is(fix_latin("\xC0\xAB", bytes_only => 1) => "+",
    '2 byte over-long UTF-8 string shortened to 1 byte');

is(fix_latin("\xE0\x80\xAB", bytes_only => 1) => "+",
    '3 byte over-long UTF-8 string shortened to 1 byte');

is(fix_latin("\xF0\x80\x80\xAB", bytes_only => 1) => "+",
    '4 byte over-long UTF-8 string shortened to 1 byte');

is(fix_latin("\xF8\x80\x80\x80\xAB", bytes_only => 1) => "+",
    '5 byte over-long UTF-8 string shortened to 1 byte');

done_testing;
exit;

