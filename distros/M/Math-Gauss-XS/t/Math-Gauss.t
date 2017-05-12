# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-Gauss.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 101;
BEGIN { use_ok('Math::Gauss::XS', ':all') }

#########################

# There are three kinds of tests in this file:
# 1) Comparison of the results single-argument versions of pdf() and cdf(),
#    and the results of inv_cdf() against "tabulated" values.
# 2) Testing that illegal inputs do generate exceptions.
# 3) Tests that the three-argument versions of pdf() and cdf() give the
#    same results as the corresponding single-argument versions, for a
#    large variety of inputs.

# ============================================================
# Use gnuplot's math library to find an independent set of "tabulated"
# values for all functions.
# Alternatively, compare against (eg) Abramowitz/Stegun.

# perl -e 'for($x=-7.5;$x<=7.5;$x+=0.5){print $x, "\n"}' > pos

# gnuplot> plot 'pos' u 1:(exp(-0.5*$1**2)/sqrt(2*pi)), "" u 1:(norm($1))
# set format "%.15f"; set table 'vals'; replot; unset table

# x     pdf                cdf
my @vals = (
    [-7.50, 0.000000000000243, 0.000000000000032],
    [-7.00, 0.000000000009135, 0.000000000001280],
    [-6.50, 0.000000000266956, 0.000000000040160],
    [-6.00, 0.000000006075883, 0.000000000986588],
    [-5.50, 0.000000107697600, 0.000000018989562],
    [-5.00, 0.000001486719515, 0.000000286651572],
    [-4.50, 0.000015983741107, 0.000003397673125],
    [-4.00, 0.000133830225765, 0.000031671241833],
    [-3.50, 0.000872682695046, 0.000232629079036],
    [-3.00, 0.004431848411938, 0.001349898031630],
    [-2.50, 0.017528300493569, 0.006209665325776],
    [-2.00, 0.053990966513188, 0.022750131948179],
    [-1.50, 0.129517595665892, 0.066807201268858],
    [-1.00, 0.241970724519143, 0.158655253931457],
    [-0.50, 0.352065326764300, 0.308537538725987],
    [0.00,  0.398942280401433, 0.500000000000000],
    [0.50,  0.352065326764300, 0.691462461274013],
    [1.00,  0.241970724519143, 0.841344746068543],
    [1.50,  0.129517595665892, 0.933192798731142],
    [2.00,  0.053990966513188, 0.977249868051821],
    [2.50,  0.017528300493569, 0.993790334674224],
    [3.00,  0.004431848411938, 0.998650101968370],
    [3.50,  0.000872682695046, 0.999767370920964],
    [4.00,  0.000133830225765, 0.999968328758167],
    [4.50,  0.000015983741107, 0.999996602326875],
    [5.00,  0.000001486719515, 0.999999713348428],
    [5.50,  0.000000107697600, 0.999999981010438],
    [6.00,  0.000000006075883, 0.999999999013412],
    [6.50,  0.000000000266956, 0.999999999959840],
    [7.00,  0.000000000009135, 0.999999999998720],
    [7.50,  0.000000000000243, 0.999999999999968],
);

# perl -e '$x=0; while($x<0.095){$x+=0.01;print "$x\n";}while($x<0.89){$x+=0.1;print "$x\n";}while($x<.99){$x+=0.01;print "$x\n";}' > ipos

# gnuplot> plot "ipos" u 1:(invnorm($1))
# gnuplot> set format "%.15f"; set table "ivals"; replot; unset table

my @ivals = (
    [0.010, -2.326347874040841],
    [0.020, -2.053748910631823],
    [0.030, -1.880793608151251],
    [0.040, -1.750686071252170],
    [0.050, -1.644853626951473],
    [0.060, -1.554773594596853],
    [0.070, -1.475791028179171],
    [0.080, -1.405071560309633],
    [0.090, -1.340755033690217],
    [0.100, -1.281551565544600],
    [0.200, -0.841621233572914],
    [0.300, -0.524400512708041],
    [0.400, -0.253347103135800],
    [0.500, 0.000000000000000],
    [0.600, 0.253347103135800],
    [0.700, 0.524400512708041],
    [0.800, 0.841621233572914],
    [0.900, 1.281551565544600],
    [0.910, 1.340755033690217],
    [0.920, 1.405071560309633],
    [0.930, 1.475791028179171],
    [0.940, 1.554773594596853],
    [0.950, 1.644853626951472],
    [0.960, 1.750686071252169],
    [0.970, 1.880793608151251],
    [0.980, 2.053748910631823],
    [0.990, 2.326347874040841],
);

# ============================================================
# Compare calculated results against tabulated values

my ($x, $y);

for (@vals) {
    ($x, $y, undef) = @{$_};
    ok(almost(pdf($x), $y, 1e-15), "pdf($x)==$y");
}

for (@vals) {
    ($x, undef, $y) = @{$_};
    ok(almost(cdf($x), $y, 7.5e-8), "cdf($x)==$y");
}

for (@ivals) {
    ($x, $y) = @{$_};
    ok(almost(inv_cdf($x), $y, 4.5e-4), "inv_cdf($x)==$y");
}

# ============================================================
# Ensure that routines throw exceptions for illegal input

eval { pdf(0, 0, 1); };
ok(!$@, "Positive std dev in pdf() does not cause exception");
eval { pdf(0, 0, -1); };
ok($@, "Negative std dev in pdf() causes exception");

eval { cdf(0, 0, 1); };
ok(!$@, "Positive std dev in cdf() does not cause exception");
eval { cdf(0, 0, -1); };
ok($@, "Negative std dev in cdf() causes exception");

eval { inv_cdf(0.5); };
ok(!$@, "inv_cdf( 0.5 ) does not cause exception");
eval { inv_cdf(0); };
ok($@, "inv_cdf(0) causes exception");
eval { inv_cdf(1); };
ok($@, "inv_cdf(1) causes exception");
eval { inv_cdf(-1); };
ok($@, "inv_cdf(-1) causes exception");
eval { inv_cdf(2); };
ok($@, "inv_cdf(2) causes exception");

# ============================================================
# Check that supplying explicit arguments is equivalent to supplying z-score

my ($pdf_fails, $pdf_trials) = (0, 0);
for (my $m = -15; $m <= 15; $m += 0.5) {
    for (my $s = 0.01; $s < 10; $s *= 2) {
        for (my $x = -50.0; $x <= 50.0; $x += 0.25) {
            my $z = ($x - $m) / $s;
            unless (almost(pdf($z), $s * pdf($x, $m, $s), 1e-15)) {
                $pdf_fails += 1;
            }
            $pdf_trials += 1;
        }
    }
}

if ($pdf_fails) {
    fail("$pdf_fails out of $pdf_trials trials testing pdf() arguments failed");
} else {
    pass("$pdf_trials trials testing pdf() arguments succeeded");
}

# ============================================================
# Check that supplying explicit arguments is equivalent to supplying z-score

my ($cdf_fails, $cdf_trials) = (0, 0);
for (my $m = -15; $m <= 15; $m += 0.5) {
    for (my $s = 0.01; $s < 10; $s *= 2) {
        for (my $x = -50.0; $x <= 50.0; $x += 0.25) {
            my $z = ($x - $m) / $s;
            unless (almost(cdf($z), cdf($x, $m, $s), 1e-15)) {
                $cdf_fails += 1;
            }
            $cdf_trials += 1;
        }
    }
}

if ($cdf_fails) {
    fail("$cdf_fails out of $cdf_trials trials testing cdf() arguments failed");
} else {
    pass("$cdf_trials trials testing cdf() arguments succeeded");
}

# ============================================================

done_testing();

# ============================================================

sub almost {
    my ($x, $y, $err) = @_;
    return abs($x - $y) < $err;
}
