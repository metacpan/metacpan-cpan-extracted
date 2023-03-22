use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print"1..6\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my ($sum, @obj);
my $rop = Math::MPFR->new();

for(my $i = int(rand(201)); $i < 10000; $i++) {
   push @obj, Math::MPFR->new($i);
   $sum += $i;
}

my $ret = Rmpfr_sum($rop, \@obj, scalar(@obj), GMP_RNDN);

if($sum == $rop) {print "ok 1\n"}
else {
  warn "\n   Got $rop\n   Expected $sum\n";
  print "not ok 1\n";
}

Rmpfr_add_si($rop, $rop, -1, GMP_RNDN);

if($rop == $sum - 1) {print "ok 2\n"}
else {
  warn "\n   Got $rop\n   Expected ", $sum - 1, "\n";
  print "not ok 2\n";
}

my $size = @obj + 1;
my $max = $size - 1;
eval {Rmpfr_sum($rop, \@obj, $size, GMP_RNDN)};

if($@ =~ /2nd last arg to Rmpfr_sum is greater than the size of the array/) {print "ok 3\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 3\n";
}

if(4 <= MPFR_VERSION_MAJOR) {
  warn "\nCalling all cache freeing functions\n";
  Rmpfr_free_cache2(MPFR_FREE_LOCAL_CACHE);
  Rmpfr_free_cache2(MPFR_FREE_GLOBAL_CACHE);
  Rmpfr_free_cache();
  Rmpfr_free_pool();
  warn "Skipping tests 4, 5 and 6 - not relevant to this build\n";
  for(4 .. 6) {print "ok $_\n"}
}
else {
  warn "\nCalling Rmpfr_free_cache()\n";
  Rmpfr_free_cache();

  eval {Rmpfr_free_cache2(MPFR_FREE_LOCAL_CACHE);};
  if($@ =~ /^Rmpfr_free_cache2 not implemented/) {print "ok 4\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 4\n";
  }

  eval {Rmpfr_free_cache2(MPFR_FREE_GLOBAL_CACHE);};
  if($@ =~ /^Rmpfr_free_cache2 not implemented/) {print "ok 5\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 5\n";
  }

  eval {Rmpfr_free_pool();};
  if($@ =~ /^Rmpfr_free_pool not implemented/) {print "ok 6\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 6\n";
  }

}

