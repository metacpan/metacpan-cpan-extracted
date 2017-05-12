use 5.10.0;
use strict;
use Test::More;

use Map::Metro;
use utf8;

{
    my $graph = Map::Metro->new('Helsinki')->parse;
    my $routing = $graph->routing_for(qw/Kaisaniemi Rastila/);
    is $routing->get_route(0)->get_step(4)->origin_line_station->station->name, 'Kulosaari', 'Found step from Kulosaari';
}
{
    my $graph = Map::Metro->new('Helsinki', hooks => ['Helsinki::Swedish', 'StreamStations'])->parse;
    my $routing = $graph->routing_for('Grasviken', 'Vuosaari');

    is $routing->get_route(0)->get_step(7)->origin_line_station->station->name, 'Brändö', 'Found step from Brändö';

    is $graph->get_plugin('StreamStations')->get_station_name(12), 'Gårdsbacka', 'Station indexed 12 is Gårdsbacka in swedish';

}

{
    my $graph = Map::Metro->new('Helsinki', hooks => ['Helsinki::Swedish'])->parse;
    my $routing = $graph->routing_for('Grasviken', 'Vuosaari');

    is $routing->get_route(0)->get_step(7)->origin_line_station->station->name, 'Brändö', 'Found step from Brändö with no diacritics';

}

done_testing;
