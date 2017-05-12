use strict;
use warnings;
use Math::Histogram;
use Test::More;
use File::Spec;
use Data::Dumper;

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

  my $dump = $ax->_as_hash;
  #use Data::Dumper; warn Dumper $dump;
  is(ref($dump), 'HASH', "axis dump is a hash");
  my $ax2;
  eval {
    $ax2 = Math::Histogram::Axis->_from_hash($dump);
    1
  } or do {
    my $err = $@ || 'Zombie error';
    die("Caught error while trying to reinstantiate axis from hash dump ($err). Hash was:\n" . Dumper($dump));
  };
  isa_ok($ax2, 'Math::Histogram::Axis');
  axis_eq($ax2, $ax, "axis equality before/after dump for $desc");

  my $json = $ax->serialize;
  ok($json =~ /^\{/ && $json =~ /\}$/);
  my $ax3 = Math::Histogram::Axis->deserialize($json);
  isa_ok($ax3, 'Math::Histogram::Axis');
  my $ax4 = Math::Histogram::Axis->deserialize($json);
  isa_ok($ax4, 'Math::Histogram::Axis');

  axis_eq($ax3, $ax, "axis equality before/after serialization for $desc");
  axis_eq($ax4, $ax, "axis equality before/after serialization (via ref) for $desc");
}

done_testing();

