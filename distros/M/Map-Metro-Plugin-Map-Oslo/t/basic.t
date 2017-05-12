use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('Oslo')->parse;
my $routing = $graph->routing_for(qw/Lindeberg Vestli/);

is $routing->get_route(0)->get_step(2)->origin_line_station->station->name, 'Haugerud', 'Found Haugerud';

$routing = $graph->routing_for('Osthorn', 'Holmenkollen');

is $routing->get_route(0)->get_step(11)->origin_line_station->station->name, 'Gaustad', 'Found Gaustad';

done_testing;
