use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('Stockholm')->parse;
my $routing = $graph->routing_for(qw/Hjulsta Rinkeby/);

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Hjulsta', 'Found route Hjulsta';

$routing = $graph->routing_for('Vreten', 'Huvudsta');
my @all = $routing->get_route(0)->get_step(0)->origin_line_station->station->all_search_names;

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Solna strand', 'Used search name';


done_testing;
