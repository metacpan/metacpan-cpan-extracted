#!/usr/bin/perl

use strict;
use warnings;

use Lingua::DE::ASCII;
use Test::More tests => 1;

my $EIGHT_BIT_CHAR    = "[" .chr(128) . "-" . chr(255) . "]";

local @ARGV = (map "t/words_with_$_.dat", "ä", "ö", "ü", "ß", 'foreign');
while (<>) {
    chomp;
    to_ascii($_) !~ /$EIGHT_BIT_CHAR/o
        or diag("to_ascii($_) => " . to_ascii($_) . " contains 8bit characters"),
           fail,
           exit;
}

ok("to_ascii returns really only 7bit characters");
