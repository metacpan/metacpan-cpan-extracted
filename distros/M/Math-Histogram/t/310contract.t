use strict;
use warnings;
use Math::Histogram qw(make_histogram);
use Test::More;
use File::Spec;

BEGIN { push @INC, -d "t" ? File::Spec->catdir(qw(t lib)) : "lib"; }
use Math::Histogram::Test;

my @axis_specs = ([2, 0., 1.], [100, 0., 1.], [[1., 2., 3., 4., 5.]]);

SCOPE: {
  my $h = make_histogram(@axis_specs);

  my $contract_dimension = 1;
  my @cspecs = map $axis_specs[$_],
               grep $_ != $contract_dimension,
               0..$#axis_specs;

  my $ch = make_histogram(@cspecs);

  $h->fill_w([0.1, 0.99999999, 1.5], 2.3);
  $h->fill_w([0.1, 0.12, 1.5], 1);
  $h->fill_w([0.7, 0.12, 1.5], 3.3);

  $ch->fill_w([0.1, 1.5], 2.3);
  $ch->fill_w([0.1, 1.5], 1);
  $ch->fill_w([0.7, 1.5], 3.3);

  my $contracted = $h->contract_dimension(1);
  isa_ok($contracted, "Math::Histogram");

  histogram_eq($contracted, $ch, "Contracted dimension");

  $ch->fill([0.1, 1.5]);
  ok(!$ch->data_equal_to($contracted), "No longer equivalent after another fill");
} # end SCOPE

done_testing();

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

