use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('Lille')->parse;
my $routing = $graph->routing_for(qw/1 3/);

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Quatre Cantons - Stade Pierre-Mauroy', 'Found route';

# more tests

done_testing;
