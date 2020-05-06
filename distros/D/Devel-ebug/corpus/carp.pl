#!perl
use strict;
use warnings;
use Carp;

my $x = -4;
print "Hi!\nAbout to get square_root($x)\n";
warn "\$x is -4";
my $result = square_root($x);
print "$result\n";

sub square_root {
  my $arg = shift;
  carp "debug: In square_root, $arg is $arg";
  if ($arg < 0) {
    croak "square_root of negative number: $arg";
  }
  return sqrt($arg);
}
