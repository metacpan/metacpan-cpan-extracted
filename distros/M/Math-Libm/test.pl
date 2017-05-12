# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $loaded;
BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use strict;
use Math::Libm ':all';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $i = 1;
my $eps = 2**(-47);
my $signgam = 0;
while (<DATA>) {
    $i++;
    my ($exp, @a) = split;
    my @b = eval $exp;
    my $ok = (@b == @a);
    if ($ok) {
	my $s = 0;
	foreach my $i (0..$#a) {
	    $s += ($b[$i]/$a[$i] - 1)**2;
	}
	$ok = sqrt($s) <= $eps;
	print "# $exp @a @b\n" if not $ok;
    }
    print $ok ? "" : "not ", "ok $i\n";
}

__DATA__
M_1_PI		 0.31830988618379067154
M_2_PI		 0.63661977236758134308
M_2_SQRTPI	 1.12837916709551257390
M_E		 2.7182818284590452354
M_LN10		 2.30258509299404568402
M_LN2		 0.69314718055994530942
M_LOG10E	 0.43429448190325182765
M_LOG2E		 1.4426950408889634074
M_PI		 3.14159265358979323846
M_PI_2		 1.57079632679489661923
M_PI_4		 0.78539816339744830962
M_SQRT1_2	 0.70710678118654752440
M_SQRT2		 1.41421356237309504880
acos(-1)	 3.14159265358979323846
acosh(1.25)	 0.69314718055994530942
asin(1)		 1.57079632679489661923
asinh(0.75)	 0.69314718055994530942
atan(1)		 0.78539816339744830962
atanh(0.6)	 0.69314718055994530942
cbrt(-8)	-2
cbrt(8)		 2
ceil(1.3)	 2
ceil(1.7)	 2
cosh(1)          1.54308063481524
erf(1)           0.842700792949715
erfc(1)          0.157299207050285
expm1(1)	 1.7182818284590452354
floor(1.3)	 1
floor(1.7)	 1
hypot(3,4)	 5
j0(1)            0.765197686557967
j1(1)            0.440050585744933
jn(2,1)          0.1149034849319
(lgamma_r(-0.5,$signgam),$signgam)	1.26551212348465	-1
(lgamma_r(0.5,$signgam),$signgam)	0.5723649429247		 1
log10(10)	 1
log1p(1)	 0.69314718055994530942
pow(-2,3)	-8
rint(1.3)	 1
rint(1.7)	 2
sinh(1)          1.1752011936438
tan(1)           1.5574077246549
tanh(1)          0.761594155955765
y0(1)            0.088256964215677
y1(1)           -0.781212821300289
yn(2,1)         -1.65068260681625
