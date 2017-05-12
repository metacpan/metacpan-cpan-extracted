use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
BEGIN { use_ok('Geo::Coordinates::ETRSTM35FIN') };

my $gce = new Geo::Coordinates::ETRSTM35FIN;

dies_ok { $gce->ETRSTM35FINxy_to_WGS84lalo() } 'Expecting two arguments (ETRSTM35FINxy_to_WGS84lalo)';
dies_ok { $gce->ETRSTM35FINxy_to_WGS84lalo("6678450.000") } 'Expecting two arguments (ETRSTM35FINxy_to_WGS84lalo)';
dies_ok { $gce->ETRSTM35FINxy_to_WGS84lalo("6678450.000",	"381151.000", "381151.000") } 'Expecting two arguments (ETRSTM35FINxy_to_WGS84lalo)';
dies_ok { $gce->WGS84lalo_to_ETRSTM35FINxy() } 'Expecting two arguments (WGS84lalo_to_ETRSTM35FINxy)';
dies_ok { $gce->WGS84lalo_to_ETRSTM35FINxy("60.22543759") } 'Expecting two arguments (WGS84lalo_to_ETRSTM35FINxy)';
dies_ok { $gce->WGS84lalo_to_ETRSTM35FINxy("60.22543759", "24.85437044", "24.85437044") } 'Expecting two arguments (WGS84lalo_to_ETRSTM35FINxy)';

