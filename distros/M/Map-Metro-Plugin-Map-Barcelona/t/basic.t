use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('Barcelona')->parse;
my $routing = $graph->routing_for('Florida', 'Catalunya');

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Florida', 'Found route Florida->Catalunya';

# more tests

done_testing;
