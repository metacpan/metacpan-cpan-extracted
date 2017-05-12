use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('Amsterdam')->parse;
my $routing = $graph->routing_for(qw/Gaasperplas Gein/);

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Gaasperplas', 'Found route Gaasperplas-Gein';

$routing = $graph->routing_for('ArenA', 'Brink');

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Bijlmer/ArenA', 'Found route ArenA-Brink';

done_testing;
