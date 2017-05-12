use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
BEGIN { use_ok('Geo::Coordinates::KKJ') };

dies_ok { KKJ_Zone_Lo("2") } 'Expecting a croak';
dies_ok { KKJ_Zone_Lo() } 'Expecting a croak when no longitude provided';
dies_ok { KKJ_Zone_Lo(undef) } 'Expecting a croak also when longitude is specificly undef';
dies_ok { KKJxy_to_WGS84lalo() } 'Expecting two arguments';
dies_ok { WGS84lalo_to_KKJxy(60.22543759) } 'Expecting two arguments';
dies_ok { KKJxy_to_KKJlalo(6679636.140) } 'Expecting two arguments';
dies_ok { KKJlalo_to_KKJxy(60.22526709) } 'Expecting two arguments';
dies_ok { KKJlalo_to_WGS84lalo(60.22526709) } 'Expecting two arguments';
dies_ok { WGS84lalo_to_KKJlalo(60.22543759) } 'Expecting two arguments';
dies_ok { KKJ_Zone_I() } 'Expecting one argument';
dies_ok { KKJ_Zone_Lo() } 'Expecting one argument';
dies_ok { KKJ_Zone_Lo(24.853707887286728,24.853707887286728) } 'Expecting one argument (only)';
