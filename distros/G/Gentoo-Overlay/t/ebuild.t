
use strict;
use warnings;

use Test::More 0.96;
use FindBin;

my $base = "$FindBin::Bin/../corpus";

use Gentoo::Overlay;

my $its = 0;

my $ebuild = {};

Gentoo::Overlay->new( path => "$base/overlay_5" )->iterate(
  'ebuilds' => sub {
    my ( $self, $config ) = @_;
    $its++;
    $ebuild = $config;
  }
);
is( $its, 1, 'Iterator iterates once' );

is( $ebuild->{category_name}, 'fake-category-2',           'simple category name' );
is( $ebuild->{package_name},  'fake-package',              'simple package name' );
is( $ebuild->{ebuild_name},   'fake-package-1.0.0.ebuild', 'ebuild' );

#note explain $ebuild;

done_testing;
