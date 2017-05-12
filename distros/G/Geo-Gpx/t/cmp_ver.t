# Test version comparison

use Test::More tests => 2;

BEGIN {
  use_ok( 'Geo::Gpx' );
}

my @ok = qw(
 0.0.0.0.0.1 0.0.0.0.0.2 1 1.0 1.0.1 1.1 2
 2.1 2.99 2.100 3 10.1
);

# Mix them up
my @m = sort { $b cmp $a } @ok;

# Sort them according to _cmp_ver
my @got = sort { Geo::Gpx::_cmp_ver( $a, $b ) } @m;

is_deeply( \@got, \@ok, 'version ordering' );
