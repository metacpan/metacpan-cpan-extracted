use strict;
use warnings;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('London')->parse;
my $routing = $graph->routing_for('Baker Street', 'Bank');

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Baker Street', 'Found route';

done_testing;
