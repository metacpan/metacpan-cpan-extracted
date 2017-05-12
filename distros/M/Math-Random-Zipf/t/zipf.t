#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 14;
use Math::Random::Zipf;
use List::MoreUtils qw/all pairwise/;
use POSIX qw/floor/;

my $N = 10;
my $p = 0.99;
my $chi_threshold = 23.2; # 99%, 10 d.o.f.


my @pmf_expected_1 = ( 0.3414171521474055,   0.1707085760737028,
		     0.1138057173824685,   0.0853542880368514,   0.0682834304294811,
		     0.0569028586912343,   0.0487738788782008,  0.0426771440184257,
		     0.0379352391274895,   0.0341417152147406 );

my @cdf_expected_1 = ( 0.341417152147406,   0.512125728221108,
		     0.625931445603577,   0.711285733640428,   0.779569164069909,
		     0.836472022761144,   0.885245901639344,   0.927923045657770,
		     0.965858284785260,   1.000000000000000 );

run_test(1, \@cdf_expected_1, \@pmf_expected_1);

my @pmf_expected_2 = ( 0.5011686015541617,  0.1771898583383633,
		       0.0964499423388945,  0.0626460751942702,
		       0.0448258824505445,  0.0341002041364419,
		       0.0270605609107414,  0.0221487322922954,
		       0.0185618000575615,   0.0158483427267255 );

my @cdf_expected_2 = ( 0.501168601554162,   0.678358459892525,   
		       0.774808402231419,   0.837454477425690,   
		       0.882280359876234,   0.916380564012676,   0.943441124923418,
		       0.965589857215713,   0.984151657273275,   1.000000000000000 );

run_test(1.5, \@cdf_expected_2, \@pmf_expected_2);

sub run_test {
    my ($exp, $cdf_expected, $pmf_expected) = @_;

    my $zipf = Math::Random::Zipf->new($N, $exp);

    my $tol = 1e-12;

    ok((all { $_ } (pairwise { abs($a - $b) < $tol } @{$zipf->cdf_ref}, @$cdf_expected)), "cdf_ref, exp=$exp");
    ok((all { $_ } (pairwise { abs($a - $b) < $tol } @{$zipf->pmf_ref}, @$pmf_expected)), "pmf_ref, exp=$exp");

# Spot check cdf/pmf
    ok($zipf->pmf(5) == $zipf->pmf_ref->[4], "pmf, exp=$exp");
    ok($zipf->cdf(5) == $zipf->cdf_ref->[4], "cdf, exp=$exp");

# check that results are within bounds and have integer values
    ok((all { floor($_) == $_ && $_ >= 1 && $_ <= $N } map { $zipf->rand() } (1 .. 10)), "Integer samples within bounds, exp=$exp");

# Run repeated chi2 tests, then run chi2 test on results to confirm that number
# of passes is within expected limits
    my $pass = 0;
    my $tests = 31;
    for (1 .. $tests) {
	my @samples = map { $zipf->rand() } (1 .. 1000);

	my @dist;
	$dist[$_ - 1]++ for @samples;
	my $chi2 = 0;
	for my $i (0 .. @dist - 1) {
	    $chi2 += ($dist[$i] - @samples * $pmf_expected->[$i])**2 / (@samples * $pmf_expected->[$i]);
	}
	$pass++ if $chi2 < $chi_threshold;
    }

    my $total_chi2 = ($pass - $p * $tests) ** 2 / ($p * $tests) + ($tests - $pass - (1-$p) * $tests) ** 2 / ((1-$p) * $tests); 
#print "Chi2: $total_chi2, $pass\n";
    ok($total_chi2 < 10.8, "Chi sq test of distribution, exp=$exp");

    my $x = $zipf->inv_cdf($cdf_expected->[2] - $tol);
    is($x, 3, "inv_cdf, exp=$exp");

}
