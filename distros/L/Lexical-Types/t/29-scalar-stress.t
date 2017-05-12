#!perl -T

use strict;
use warnings;

my $count;
BEGIN { $count = 1_000 }

use Test::More tests => $count;

sub Int::TYPEDSCALAR { join ':', (caller(0))[2], $_ }

for (1 .. $count) {
 eval q{
  use Lexical::Types;
  my Int $x;
  is $x, "3:$_", "run $_";
 }
}
