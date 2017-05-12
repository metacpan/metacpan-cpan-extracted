use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

my $bins = [];
my $x = 2.1;
my $n = 10;
push @$bins, sprintf("%.1f", $x+=$x/($_+1)) for 0..$n;
my $h = Math::SimpleHisto::XS->new(bins => $bins);
isa_ok($h, 'Math::SimpleHisto::XS');

my $lower_b = $h->bin_lower_boundaries();
my $upper_b = $h->bin_upper_boundaries();
my $centers = $h->bin_centers();
foreach my $i (0..$#$bins-1) {
  is_approx($lower_b->[$i], $bins->[$i], "lower boundary ($i) okay");
  is_approx($upper_b->[$i], $bins->[$i+1], "upper boundary ($i) okay");
  is_approx($centers->[$i], 0.5*($bins->[$i]+$bins->[$i+1]), "bin center ($i) okay");
}

foreach my $i (0..$n-1) {
  is_approx($h->bin_lower_boundary($i), $bins->[$i], "lower boundary bin $i");
  is_approx($h->bin_upper_boundary($i), $bins->[$i+1], "upper boundary bin $i");
  is_approx($h->bin_center($i), 0.5*($bins->[$i]+$bins->[$i+1]), "bin center $i");
}

# Test addition
SCOPE: {
  my $hclone = $h->clone;
  $hclone->set_bin_content(0, 23.4);
  my $hcloneclone = $hclone->clone;
  $hcloneclone->add_histogram($h);
  foreach my $meth (qw(total overflow underflow nfills)) {
    is_approx($hcloneclone->$meth, $hclone->$meth + $h->$meth, "addition: $meth");
  }
  foreach my $i (0..$h->nbins-1) {
    is_approx($hcloneclone->bin_content($i), $hclone->bin_content($i) + $h->bin_content($i));
  }
}

# Test subtraction
SCOPE: {
  my $hclone = $h->clone;
  $hclone->set_bin_content(0, 23.4);
  my $hcloneclone = $hclone->clone;
  $hcloneclone->subtract_histogram($h);
  foreach my $meth (qw(total overflow underflow)) {
    is_approx($hcloneclone->$meth, $hclone->$meth - $h->$meth, "subtraction: $meth");
  }
  is_approx($hcloneclone->nfills, $hclone->nfills + $h->nfills, "subtraction: nfills");
  foreach my $i (0..$h->nbins-1) {
    is_approx($hcloneclone->bin_content($i), $hclone->bin_content($i) - $h->bin_content($i));
  }
}

#diag(join(" ", @$bins));
$h->fill([-1.2, 7.9, 1.1, 5.1, 20., 14.13, 81.]);
is($h->nfills, 7, "nfills");
is_approx($h->underflow, 2., "underflow");
is_approx($h->overflow, 1., "overflow");
my @expected_contents = (
  1, 1, 0, 0, 1,
  0, 0, 1, 0, 0
);
foreach (0..$#expected_contents) {
  is_approx($h->bin_content($_), $expected_contents[$_], "Bin content $_");
}
is_approx($h->mean, 11.55, "mean");

is($h->find_bin($bins->[0]), 0, "find_bin min");
is($h->find_bin($bins->[-1]), undef, "find_bin max");
is($h->find_bin($bins->[-1]-1e-2), $n-1, "find_bin max-eps");
is($h->find_bin(0.5*($bins->[3]+$bins->[4])), 3, "find_bin some bin center");

is($h->find_bin(21), 8, "find_bin x=21 => ibin=8");

is_approx($h->binsize, $h->bin_upper_boundary(0)-$h->bin_lower_boundary(0), "binsize default is first bin");
for (0, 2, 5) {
  is_approx($h->binsize($_), $h->bin_upper_boundary($_)-$h->bin_lower_boundary($_), "binsize($_)");
}
ok(!eval{$h->binsize(-1); 1}, "binsize(-1) fails");
ok(!eval{$h->binsize(100); 1}, "binsize(100) fails");


#my @t;
#for (1..1000) {
#  my $ibin = int(rand($n));
#  my $x = $bins->[$ibin] + ((rand() < 0.01) ? 0. : rand($bins->[$ibin+1]-$bins->[$ibin]));
#  is($h->find_bin($x), $ibin, "find_bin: $x ==> $ibin");
#  push @t, [$x, $ibin];
#}
#print "[qw(@$_)],\n" for @t;

# 4.2 6.3 8.4 10.5 12.6 14.7 16.8 18.9 21.0 23.1 25.2
my @tests = (
  [qw(4.2 0)],
  [qw(4.3 0)],
  [qw(6.3 1)],
  [qw(6.4 1)],
  [qw(8.4 2)],
  [qw(8.5 2)],
  [qw(10.5 3)],
  [qw(10.6 3)],
  [qw(12.6 4)],
  [qw(12.7 4)],
  [qw(14.7 5)],
  [qw(14.8 5)],
  [qw(16.8 6)],
  [qw(16.9 6)],
  [qw(18.9 7)],
  [qw(18.92 7)],
  [qw(21.0 8)],
  [qw(21.1 8)],
  [qw(23.1 9)],
  [qw(23.2 9)],
  [25.2-1e-9, 9],
  [qw(21.5300051946957 8)],
  [qw(23.1 9)],
  [qw(19.7411354842682 7)],
  [qw(18.6878835266225 6)],
  [qw(23.8972735361547 9)],
  [qw(15.4095905076324 5)],
  [qw(20.5184622603176 7)],
  [qw(20.5076673136554 7)],
  [qw(24.6393243048754 9)],
  [qw(7.22094555804201 1)],
  [qw(9.70258097757372 2)],
  [qw(18.7812156474824 6)],
  [qw(24.9270609110801 9)],
  [qw(4.7475100249957 0)],
  [qw(6.73480915112459 1)],
  [qw(16.8747346788451 6)],
  [qw(21.5171018609279 8)],
  [qw(12.8519732713312 4)],
  [qw(11.6448464169138 3)],
  [qw(9.70882358825989 2)],
  [qw(11.2119530227146 3)],
  [qw(20.1264645223088 7)],
  [qw(6.56250095873766 1)],
  [qw(10.4329716331412 2)],
  [qw(13.814587763189 4)],
  [qw(7.35334253415085 1)],
  [qw(17.3976219670695 6)],
  [qw(16.806394260161 6)],
  [qw(17.1719149983471 6)],
  [qw(10.9857623214947 3)],
  [qw(12.1384640829417 3)],
  [qw(8.83129986331711 2)],
  [qw(15.5370933069582 5)],
  [qw(7.86203725025672 1)],
  [qw(21.002381733907 8)],
  [qw(10.4806788200255 2)],
  [qw(21.5819017571493 8)],
  [qw(17.1192004636426 6)],
  [qw(11.0443961210872 3)],
  [qw(15.5901401335003 5)],
  [qw(15.9186784601364 5)],
  [qw(16.0392663893265 5)],
  [qw(22.9939449765338 8)],
  [qw(24.0348642305808 9)],
  [qw(5.26513170931282 0)],
  [qw(16.3328120930821 5)],
  [qw(6.46671038032167 1)],
  [qw(18.394636292406 6)],
);
for (@tests) {
  my ($x, $ibin) = @$_;
  is($h->find_bin($x), $ibin, "find_bin: $x ==> $ibin");
}

done_testing();
