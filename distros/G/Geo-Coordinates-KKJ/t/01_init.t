use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Geo::Coordinates::KKJ') };

my @subroutines = qw(
    KKJxy_to_WGS84lalo
    WGS84lalo_to_KKJxy
    KKJxy_to_KKJlalo
    KKJlalo_to_KKJxy
    KKJlalo_to_WGS84lalo
    WGS84lalo_to_KKJlalo
    KKJ_Zone_I
    KKJ_Zone_Lo
    );

foreach my $sub ( @subroutines ) {
    can_ok(__PACKAGE__, $sub);
}

