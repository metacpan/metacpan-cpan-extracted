package # hide from PAUSE
  Test_Functions;
use strict;
use warnings;
require Test::More;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_approx histo_eq histo_eq_test_no);

sub is_approx {
  my $delta = $_[3] || 1e-9;
  Test::More::ok($_[0] > $_[1]-$delta && $_[0] < $_[1]+$delta, (@_ > 2 ? ($_[2]) : ()))
    or Test::More::diag("Got $_[0], expected $_[1]");
}


sub histo_eq_test_no {
  my $hist = shift;
  my $is_named = $hist->isa("Math::SimpleHisto::XS::Named");
  ($is_named ? 7 : 11) + scalar(@{$hist->bin_centers})*2;
}

sub histo_eq {
  my ($ref, $test, $name) = @_;
  $name = "hist. compare" if not defined $name;

  my $is_named = $test->isa("Math::SimpleHisto::XS::Named");

  if (not $is_named) {
    Test::More::is($test->min, $ref->min, "min is the same ($name)");
    Test::More::is($test->max, $ref->max, "max is the same ($name)");
    is_approx($test->width, $ref->width, "width is the same ($name)");
    is_approx($test->binsize, $ref->binsize, "binsize is the same ($name)");
  }
  Test::More::is($test->nbins, $ref->nbins, "nbins is the same ($name)");
  Test::More::is($test->nfills, $ref->nfills, "nbins is the same ($name)");
  is_approx($test->overflow, $ref->overflow, "overflow is the same ($name)");
  is_approx($test->underflow, $ref->underflow, "underflow is the same ($name)");
  is_approx($test->total, $ref->total, "total is the same ($name)");

  my $ref_content = $ref->all_bin_contents();
  my $test_content = $test->all_bin_contents();
  my ($ref_centers, $test_centers);
  if (not $is_named) {
    $ref_centers = $ref->bin_centers();
    $test_centers = $test->bin_centers();
  }
  Test::More::is(scalar(@$ref_content), scalar(@{$test->all_bin_contents()}), "No. of bins with content correct ($name)");
  Test::More::is(scalar(@$ref_centers), scalar(@{$test->bin_centers()}), "No. of bin centers correct ($name)")
    if not $is_named;
  foreach my $i (0..$ref->nbins-1) {
    is_approx($test_content->[$i], $ref_content->[$i], "Bin content bin $i ($name)");
    is_approx($test_centers->[$i], $ref_centers->[$i], "Bin center bin $i ($name)")
      if not $is_named;
  }
}

1;

