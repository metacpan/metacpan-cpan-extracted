#!/usr/bin/perl -w

BEGIN { unshift @INC, '../lib'; }	# uncomment to use old, org version

$| = 1;

use Math::BigInt;
use Math::Big;
use strict;

# Show fibonacci number calculation.

my $n = Math::BigInt->new( shift || 370 ); $n->babs();

die "Invalid input" if $n->is_nan();

my $trace = shift || 0;			# set to 1 to see trials of numbers

print "The $n"."th number in the Fibonacci series is:\n\n";

my $fib = Math::Big::fibonacci($n);

print "$fib\n\n";

###############################################################################
print "The first Fibonacci number with $n digits is ";

# about 4.7 numbers in serie per 10 digits, so approximate it to take as few
# steps as possible

print "\n" if $trace;
my $cur = $n * 5;
$fib = Math::Big::fibonacci($cur);
while ($fib->length() - $n > 10)
  {
  $fib = Math::Big::fibonacci($cur);
  print "try $cur ",$fib->length(),"\n" if $trace;
  $cur += ($n - $fib->length()) * 5;
  }
print "$cur would have been next\n" if $trace;
# we overshoot, so go backwards
while ($fib->length() < $n)
  {
  $fib = Math::Big::fibonacci($cur);
  print "try $cur ",$fib->length(),"\n" if $trace;
  $cur ++;
  }
# we undershoot, so go forward again
$cur -= 2; print "tracing backwards\n" if $trace;
while ($fib->length() >= $n)
  {
  $fib = Math::Big::fibonacci($cur);
  print "try $cur ",$fib->length(),"\n" if $trace;
  $cur --;
  }
$cur += 2;
#$fib = Math::Big::fibonacci($cur); 	# this is the final first

print "the $cur"."th in the series.\n\n";
