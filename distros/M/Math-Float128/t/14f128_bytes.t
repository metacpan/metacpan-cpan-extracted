use strict;
use warnings;
use Math::Float128 qw(:all);

print "1..1\n";

my $frac = 3.0;
my $f = Math::Float128->new($frac);
my $bytes = f128_bytes(sqrt($f));

if(uc($bytes) eq '3FFFBB67AE8584CAA73B25742D7078B8') {print "ok 1\n"}
else {
  warn  "\n Expected: 3FFFBB67AE8584CAA73B25742D7078B8\n      Got: ", uc($bytes), "\n";
  print "not ok 1\n";
}
