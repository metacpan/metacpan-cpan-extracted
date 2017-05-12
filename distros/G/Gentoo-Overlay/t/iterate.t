
use strict;
use warnings;

use Test::More 0.96;
use FindBin;

my $base = "$FindBin::Bin/../corpus";

use Gentoo::Overlay;

my $its = 0;

Gentoo::Overlay->new( path => "$base/overlay_4" )->iterate(
  'categories' => sub {
    my ( $self, $config ) = @_;
    $its++;
  }
);

is( $its, 2, 'Iterator iterates twice' );

my $pits = 0;

Gentoo::Overlay->new( path => "$base/overlay_4" )->iterate(
  'packages' => sub {
    my ( $self, $config ) = @_;
    $pits++;
  }
);

is( $pits, 0, 'Iterator iterates none ( no packages yet )' );

done_testing;
