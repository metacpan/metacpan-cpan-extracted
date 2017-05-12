#!/usr/bin/perl -w

BEGIN { unshift @INC, '../lib'; }	# uncomment to use old, org version

$| = 1;

use Math::BigInt;

# this is a complicated version of the prime number sieve.
# It is not optimized (since we want to benchmark as many features as
# possible).

$amount = Math::BigInt->new( shift || 1000000 );

@primes = (1,1,0); # any not defined number is prime, 0,1 are not, but 2 is
my $prime = Math::BigInt->new (3);	# start

# the loop below is faster in the old version than in the new, since it is
# the worst case for new lib: small numbers and lot's of bstr()/new().
# It also slows down the benchmark too much so we use slightly faster int here
$r = 0; my $a = $amount->numify();
for ($i = 3; $i < $a; $i++)		# int version
  {
  $primes[$i] = $r; $r = 1-$r;
  }

# find primes
OUTER:
while ($prime < $amount)
  {
  # find first unmarked, it is the next prime
  $cur = $prime;
  while ($primes[$cur])
    {
    $cur += 2; last OUTER if $cur >= $amount; 	# no more to do
    }
  # $cur is now new prime
  $str = "$cur"; $str =~ s/\+//; # unify output for comapre
  #print "$str $prime $amount\n";
  # now strike out all multiples of $cur
  $add = $cur*2;
  $prime = $cur + 2;			# next round start two higher
  $cur += $add;
  while ($cur < $amount)
    {
    $primes[$cur] = 1; $cur += $add;
    }
  }

$i = 0;
foreach (@primes)
  {
  push @real_primes, $i if $primes[$i] == 0;
  $i++;
  }
# uncomment to print em:
# foreach (@real_primes) { print "$_\n"; }

print "last prime: $real_primes[-1]\n";


# check against text
open FILE, '1000.txt' or die "Can't read 1000.txt: $!";
my @test;
while (<FILE>)
  {
  next if /^#/;
  next if /^\s*$/;
  $_ =~ s/\s+/ /g;
  $_ =~ s/^\s+//;
  $_ =~ s/\s+$//;
  push @test, split /\s+/,$_;
  }
close FILE;
my $i = 0;
foreach (@real_primes)
  {
  print "oups: $i: $test[$i] != $real_primes[$i]\n"
    if $test[$i] != $real_primes[$i]; $i++;
  last if $i >= 1000;
  }

print "done\n";
