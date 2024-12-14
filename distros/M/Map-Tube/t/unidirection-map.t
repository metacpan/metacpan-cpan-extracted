package UnidirectionMap;

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'unidirection-map.xml') });
with 'Map::Tube';

package main;

use 5.006;
use strict; use warnings;
use Test::More;
use Test::Exception;

my $map = UnidirectionMap->new;

is($map->get_shortest_route('A street', 'C alley'),
    'A street (Line1), B road (Line1), C alley (Line1)',
    'Testing line 1: unidirectional, no indices, existing route');

throws_ok { $map->get_shortest_route('C alley', 'A street') } qr/Route not found/,
    'Testing line 1: unidirectional, no indices, non-existing route due to unidirectionality';

is($map->get_shortest_route('E street', 'G alley'),
    'E street (Line2), F road (Line2), G alley (Line2)',
    'Testing line 2: unidirectional, with indices, existing route');

throws_ok { $map->get_shortest_route('G alley', 'E street') } qr/Route not found/,
    'Testing line 2: unidirectional, with indices, non-existing route due to unidirectionality';

is($map->get_shortest_route('K street', 'M alley'),
    'K street (Line3), L road (Line3), M alley (Line3)',
    'Testing line 3: bidirectional, with indices, existing route');

is($map->get_shortest_route('M alley', 'K street'),
    'M alley (Line3), L road (Line3), K street (Line3)',
    'Testing line 3: bidirectional, with indices, existing route (reverse)');

is($map->get_shortest_route('P street', 'R alley'),
    'P street (Line4), Q road (Line4), R alley (Line4)',
    'Testing line 4: bidirectional, with incomplete indices, existing route');

is($map->get_shortest_route('R alley', 'P street'),
    'R alley (Line4), Q road (Line4), P street (Line4)',
    'Testing line 4: bidirectional, with incomplete indices, existing route (reverse)');

is($map->get_shortest_route('W drive', 'V alley'),
    'W drive (Line5), T street (Line5), U road (Line5), V alley (Line5)',
    'Testing line 5: unidirectional circular, with indices, existing route');

throws_ok { $map->get_shortest_route( 'E street', 'V alley'  ) } qr/Route not found/,
    'Testing lines 2 and 5: non-existing route due to unconnectedness';

throws_ok { $map->get_shortest_route( 'E street', 'V alley'  )->preferred() } qr/Route not found/,
    'Testing lines 2 and 5: non-existing route due to unconnectedness, preferred';

done_testing;
