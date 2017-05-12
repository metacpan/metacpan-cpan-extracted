use strict;
use warnings;
use Math::Histogram;
use Test::More;
use File::Spec;

BEGIN { push @INC, -d "t" ? File::Spec->catdir(qw(t lib)) : "lib"; }
use Math::Histogram::Test;

my $bins = [1.1, 1.35, 1.6, 1.85, 2.1];
my @ax = (Math::Histogram::Axis->new(4, 1.1, 2.1),
          Math::Histogram::Axis->new($bins));
is(scalar(@ax), 2);
isa_ok($ax[0], 'Math::Histogram::Axis');
isa_ok($ax[1], 'Math::Histogram::Axis');

my @desc = qw(fixbin varbin);
foreach my $ax (@ax) {
  my $desc = shift @desc;

  is($ax->nbins, 4, "$desc: nbins");

  my @bad_methods = qw(binsize lower_boundary upper_boundary bin_center);
  foreach my $dying_method (@bad_methods) {
    foreach my $ibin (0, 5) {
      my $res = eval {$ax->$dying_method($ibin); 1};
      ok(!$res && $@ =~ /\boutside axis bin range\b/);
    }
  }

  is_approx($ax->min, 1.1, "$desc: min");
  is_approx($ax->max, 2.1, "$desc: max");
  is_approx($ax->width, $ax->max - $ax->min, "$desc: width");

  foreach my $ibin (0..3) {
    my $lower = $bins->[$ibin];
    my $upper = $bins->[$ibin+1];
    my $center = 0.5*($upper+$lower);
    my $binsize = $upper-$lower;
    is_approx($ax->binsize($ibin+1), $binsize, "$desc, $ibin: binsize");
    is_approx($ax->lower_boundary($ibin+1), $lower, "$desc, $ibin: lower bin boundary");
    is_approx($ax->upper_boundary($ibin+1), $upper, "$desc, $ibin: upper bin boundary");
    is_approx($ax->bin_center($ibin+1), $center, "$desc, $ibin: bin center");

    is($ax->find_bin($lower), $ibin+1, "$desc, $ibin: found lower bin boundary");
    is($ax->find_bin($center), $ibin+1, "$desc, $ibin: found bin center");
    is($ax->find_bin($upper), $ibin+2, "$desc, $ibin: found upper bin boundary");
  }
}


done_testing();

