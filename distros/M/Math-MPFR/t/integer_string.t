use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..1\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $ok = '';

my $nan = Math::MPFR->new();

$ok .= 'a' if lc(Rmpfr_integer_string($nan, 10, GMP_RNDN)) eq '@nan@';

my ($man, $exp) = Rmpfr_deref2($nan, 10, 0, GMP_RNDN);

$ok .= 'b' if lc($man) eq '@nan@';

my $one = Math::MPFR->new(1);
my $minus_one = Math::MPFR->new(-1);
my $zero = Math::MPFR->new(0);
my $minus_zero = Math::MPFR->new(-0.0);

my $inf = $one / $zero;
$ok .= 'c' if lc(Rmpfr_integer_string($inf, 10, GMP_RNDN)) eq '@inf@';

$inf = $minus_one / $minus_zero;
$ok .= 'd' if lc(Rmpfr_integer_string($inf, 10, GMP_RNDN)) eq '@inf@';

$inf = $one / $minus_zero;
$ok .= 'e' if lc(Rmpfr_integer_string($inf, 10, GMP_RNDN)) eq '-@inf@';

$inf = $minus_one / $zero;
$ok .= 'f' if lc(Rmpfr_integer_string($inf, 10, GMP_RNDN)) eq '-@inf@';

$ok .= 'g' if Rmpfr_integer_string($zero, 10, GMP_RNDN) eq '0';
$ok .= 'h' if Rmpfr_integer_string($minus_zero, 10, GMP_RNDN) eq '-0';

my $minus_zero2 = Math::MPFR->new(-0);
$ok .= 'i' if Rmpfr_integer_string($minus_zero2, 10, GMP_RNDN) eq '0';
$ok .= 'j' if lc(Rmpfr_integer_string($zero / $minus_zero, 10, GMP_RNDN)) eq '@nan@';

if($ok eq 'abcdefghij') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

