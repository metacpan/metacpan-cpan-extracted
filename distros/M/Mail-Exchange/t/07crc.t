#!/usr/bin/perl -w

use Test::More;
use Mail::Exchange::CRC;
use strict;
# use diagnostics;
use utf8;

plan tests => 4;

my $crc;

$crc=Mail::Exchange::CRC::crc("blarfl");
is($crc, 3132291351, "calculate crc directly");

$crc=Mail::Exchange::CRC->new("blarfl");
is($crc->value, 3132291351, "calculate crc from object");

$crc=Mail::Exchange::CRC->new();
$crc->append("blarfl");
is($crc->value, 3132291351, "calculate crc from object after append");

$crc=Mail::Exchange::CRC->new("blarfl");
$crc->append("blarfl");
$crc->append("foo bar");
is($crc->value, 627403236, "calculate crc from object with init and append");
