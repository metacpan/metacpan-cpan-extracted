package CommonLinesMap;

use Moo;
use namespace::autoclean;

has json => (is => 'ro', default => sub { File::Spec->catfile('t', 'common-lines-map.json') });
with 'Map::Tube';

package main;

use 5.006;
use strict; use warnings;
use Test::Map::Tube tests => 1;

my @routes = <DATA>;
ok_map_routes(CommonLinesMap->new(experimental =>1), \@routes);

__DATA__
Route 1|A|D|A,B,C,D
Route 2|A|F|A,E,F
