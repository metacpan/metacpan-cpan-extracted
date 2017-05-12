use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Geo::Coordinates::ETRSTM35FIN') };

my $gce = new Geo::Coordinates::ETRSTM35FIN;

my @subroutines = qw(
    is_defined_ETRSTM35FINxy
    is_defined_WGS84lalo
    ETRSTM35FINxy_to_WGS84lalo
    WGS84lalo_to_ETRSTM35FINxy
    );

foreach my $sub ( @subroutines ) {
    can_ok($gce, $sub);
}

