use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..1\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(150);


my $nan = Math::MPFR->new();
my $inf = Math::MPFR->new();
my $neg = Math::MPFR->new(-12345);
my $pos = Math::MPFR->new(23456);

my $ok = '';

$ok .= 'a' if !Rmpfr_signbit($nan);
$ok .= 'b' if  Rmpfr_signbit($neg);
$ok .= 'c' if !Rmpfr_signbit($pos);

Rmpfr_set_si($nan, -2, GMP_RNDN);

Rmpfr_setsign($nan, $neg, 0, GMP_RNDN);
$ok .= 'd' if $nan + $neg == 0;

Rmpfr_setsign($nan, $neg, -1, GMP_RNDN);
$ok .= 'e' if $nan == $neg;

Rmpfr_setsign($nan, $neg, 1, GMP_RNDN);
$ok .= 'f' if $nan == $neg;

Rmpfr_copysign($nan, $pos, $neg, GMP_RNDN);

$ok .= 'g' if $nan + $pos == 0;

Rmpfr_set_inf($inf, 1);
$ok .= 'h' if !Rmpfr_signbit($inf);

Rmpfr_set_inf($inf, -1);
$ok .= 'i' if Rmpfr_signbit($inf);

if($ok eq 'abcdefghi') {print "ok 1\n"}
else {print "not ok $ok\n"}
