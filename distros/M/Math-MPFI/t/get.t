use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..2\n";

my $fr = Math::MPFR->new();
my $op = Math::MPFI->new(2);

$op = sqrt($op);

my $double = Rmpfi_get_d($op);
Rmpfi_get_fr($fr, $op);

if($double == $op) {print "ok 1\n"}
else {
  warn "\$double: $double\n\$op: $op\n";
  print "not ok 1\n";
}

if(! Rmpfi_cmp_fr($op, $fr)) {print "ok 2\n"}
else {
  warn "\$op: $op\n\$fr: $fr\n";
  print "not ok 2\n";
}

