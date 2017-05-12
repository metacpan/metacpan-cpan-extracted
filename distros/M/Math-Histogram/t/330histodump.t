use strict;
use warnings;
use Math::Histogram qw(make_histogram);
use Test::More;
use File::Spec;

BEGIN { push @INC, -d "t" ? File::Spec->catdir(qw(t lib)) : "lib"; }
use Math::Histogram::Test;

my @axis_specs = ([2, 0., 1.], [23, 0., 1.], [[1., 2., 3., 4., 5.]]);

my $h = make_histogram(@axis_specs);
my $hash = $h->_as_hash;
ok(ref($hash) eq 'HASH');
#use Data::Dumper; warn Dumper $hash;
my $h2 = Math::Histogram->_from_hash($hash);
histogram_eq($h2, $h, "histogram copied via hash conversion");
my $json = $h->serialize;
ok($json && $json =~ /^\{/);
my $h3 = Math::Histogram->deserialize($json);
my $h4 = Math::Histogram->deserialize(\$json);
histogram_eq($h3, $h, "histogram copied via JSON serialization");
histogram_eq($h4, $h, "histogram copied via JSON serialization, using reference");

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

