#!/usr/local/bin/perl -w

use strict;
use Test::More tests => 15;
use locale; # for the skip determination
            # DON'T change this to a use_ok() !

BEGIN {
  use_ok('Lingua::Pangram');
}

my $pan = Lingua::Pangram->new();

isa_ok($pan, "Lingua::Pangram");

#-----------------------------------------------------------------------------
# Test pangram
#-----------------------------------------------------------------------------

# One that is not a pangram
my $first = $pan->pangram('abc');

isnt($first, undef, "pangram returns defined value");
isnt($first, "", "pangram doesn't return an empty string");
is($first, 0, "pangram('abc') returns 0");

# One that is a simple pangram
my $second = $pan->pangram('abcdefghijklmnopqrstuvwxyz');

isnt($second, undef, "pangram returns defined value");
isnt($second, "", "pangram doesn't return an empty string");
is($second, 1, "pangram('abcdefghijklmnopqrstuvwxyz') returns 1");

# One that is a pangram and has spaces and punctuation
my $third = $pan->pangram('The quick brown fox jumps over a lazy dog.?!');

isnt($third, undef, "pangram returns defined value");
isnt($third, "", "pangram doesn't return an empty string");
is($third, 1, "pangram('The quick brown fox...') returns 1");

# One with extra letters
my $german = Lingua::Pangram->new( ['a'..'z', 'ä', 'ö', 'ü', 'ß'] );
isa_ok($german, "Lingua::Pangram");

my $fourth = $german->pangram('ZWÖLF große BOXKÄMPFER jagen Eva quer über den Sylter Deich');
# diag "lc ä = " . lc('ä') . " and lc Ä = " . lc('Ä');
# diag "uc ä = " . uc('ä') . " and uc Ä = " . uc('Ä');
SKIP: {
  skip 'different locale', 3 unless lc('Ä') eq 'ä';

  isnt($fourth, undef, "pangram returns defined value");
  isnt($fourth, "", "pangram doesn't return an empty string");
  is($fourth, 1, "German pangram returns 1");
}
