use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('Athens')->parse;
my $routing = $graph->routing_for('Airport', 'Ano Patisia');

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Athens International Airport', 'Found route Airport->Ano Patisia';

# more tests

done_testing;
