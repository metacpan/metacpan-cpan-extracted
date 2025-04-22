package UnicodeMap;

use strict;
use warnings;
use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return File::Spec->catfile('t/unicode-map.xml') });
with 'Map::Tube';

package main;

use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More;
my $map = UnicodeMap->new;

is($map->get_shortest_route('À', 'Ù'), 'À (Èà), Ï (Èà, Àé), Ù (Àé)', 'Route showing station and line names with unicode character');
is($map->get_line_by_name('Èà'), 'Èà', 'Line name with unicode characters');
is(join(" -> ", @{$map->get_stations('Èà')}), 'Ï (Èà, Àé) -> À (Èà) -> È (Èà)', 'Line station list');

done_testing;
