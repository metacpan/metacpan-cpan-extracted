use strict;
use Test::More;

use Map::Metro;
use utf8;

my $graph = Map::Metro->new('Budapest')->parse;
my $routing = $graph->routing_for(qw/1 3/);

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Vörösmarty tér', 'Found route';

# more tests

done_testing;
