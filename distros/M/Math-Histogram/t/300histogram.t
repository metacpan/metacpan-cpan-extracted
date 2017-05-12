use strict;
use warnings;
use Math::Histogram qw(make_histogram);
use Test::More;
use File::Spec;

BEGIN { push @INC, -d "t" ? File::Spec->catdir(qw(t lib)) : "lib"; }
use Math::Histogram::Test;

my @axis_specs = ([2, 0., 1.], [100, 0., 1.], [[1., 2., 3., 4., 5.]]);
test_histogram(\@axis_specs, 0);
test_histogram(\@axis_specs, 1);
test_histogram(\@axis_specs, 1, 1);

done_testing();

sub test_histogram {
  my $specs = shift;
  my $do_clone = shift;
  my $do_retain_data_while_cloning = shift;

  my $h = make_histogram(@$specs);
  $h = $do_retain_data_while_cloning ? $h->clone : $h->new_alike if $do_clone;
  isa_ok($h, 'Math::Histogram');

  test_hist_axises($h, $specs);

  is($h->ndim, 3, "ndim");
  is($h->nfills, 0, "nfills");
  is_approx($h->total, 0., "total");

  my @test_fills = (
    1, 2.1, -100., 10000, 1, 0., 1
  );
  my @test_bins = (
    { in   => [0., 0., 1.],
      out  => [1, 1, 1],
      name => "start of first bins" },
    { in   => [0.49, 1/100-1e-6, 1.999],
      out  => [1, 1, 1],
      name => "end of first bins" },
    { in   => [0.5, 1/100, 2],
      out  => [2, 2, 2],
      name => "lower bound of second bin" },
    { in   => [1.-1e-9, 1.-1e-9, 5-1e-9],
      out  => [2, 100, 4],
      name => "almost upper bound of last bin" },
    { in   => [1000., 100., 500],
      out  => [3, 101, 5],
      name => "overflow" },
    { in   => [1., 1., 5],
      out  => [3, 101, 5],
      name => "barely overflow" },
    { in   => [-1., -0.1, 0.],
      out  => [0, 0, 0],
      name => "underflow" },
    { in   => [-1e-9, -1e-9, 1.-1e-9],
      out  => [0, 0, 0],
      name => "barely underflow" },
  );
  foreach my $t (@test_bins) {
    my $coords = $t->{in};
    my $b = $h->find_bin_numbers($coords);
    is_deeply($b, $t->{out}, "Finding bins tests: $t->{name}");

    foreach my $bin_or_coord ([qw(fill), $coords], [qw(fill_bin), $b]) {
      my $fill_method = $bin_or_coord->[0];
      my $fill_n_method = $fill_method . "_n";
      my $fill_w_method = $fill_method . "_w";
      my $fill_nw_method = $fill_method . "_nw";
      my $location = $bin_or_coord->[1];

      my $nfills = $h->nfills;
      my $total = $h->total;
      my $total_before = $h->total;
      is_approx($h->get_bin_content($b), 0., "assert that initial bin is empty");
      my $content = $h->get_bin_content($b);
      foreach my $do_fill_n (0..1) {
        foreach my $fill_amount (@test_fills) {
          note("Testing for fill $fill_amount...");
          if ($fill_amount == 1) {
            if ($do_fill_n) { $h->$fill_n_method([$location]); }
            else { $h->$fill_method($location); }
            ++$nfills; $total += $fill_amount;
            $content += $fill_amount;
            is_approx($h->get_bin_content($b), $content, "check content after fill");
            is_approx($h->total, $total, "check total");
            is($h->nfills, $nfills, "check nfills");
          }

          if ($do_fill_n) { $h->$fill_nw_method([$location], [$fill_amount]); }
          else { $h->$fill_w_method($location, $fill_amount); }
          ++$nfills; $total += $fill_amount;
          $content += $fill_amount;
          is_approx($h->get_bin_content($b), $content, "check content after fill_w");
          is_approx($h->total, $total, "check total");
          is($h->nfills, $nfills, "check nfills");
        } # end foreach fillamount
      } # end do_fill_n or not
      $h->set_bin_content($b, 0.);
      is_approx($h->total, $total_before, "check total back to normal");
    }
  } # foreach test bin
}

sub test_hist_axises {
  my $h = shift;
  my $specs = shift;

  my @axis_defs = @$specs;

  my @axis = map $h->get_axis($_), 0..2;
  my @ref_axis = map Math::Histogram::Axis->new(@$_), @$specs;
  foreach (0..2) {
    axis_eq($axis[$_], $ref_axis[$_], "axis " . ($_+1));
  }
}

