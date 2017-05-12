use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('Copenhagen')->parse;
my $routing = $graph->routing_for('Bella center', 'Kastrup');

is $routing->get_route(0)->get_step(9)->origin_line_station->station->name, 'Amager Strand', 'Found route Amager Strand';

done_testing;
