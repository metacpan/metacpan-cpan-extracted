
use strict;
use warnings;

use Test::More 0.96;
use FindBin;

my $base = "$FindBin::Bin/../corpus";

use Gentoo::Overlay::Group;

my $its = 0;

sub fast_group {
  my $x = Gentoo::Overlay::Group->new();
  $x->add_overlay("$base/overlay_4");
  $x->add_overlay("$base/overlay_5");

  return $x;
}

fast_group()->iterate(
  'categories' => sub {
    my ( $self, $config ) = @_;
    $its++;
  }
);

is( $its, 4, 'Iterator iterates twice per overlay' );

my $pits = 0;

fast_group()->iterate(
  'packages' => sub {
    my ( $self, $config ) = @_;
    $pits++;
  }
);

is( $pits, 0, 'Iterator iterates none ( no packages yet )' );

done_testing;
