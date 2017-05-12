use strict;

use Test::More;
use Path::Tiny;

use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Map::Metro;
use Map::Metro::Shim;

subtest standard => sub {
    my $metro = Map::Metro::Shim->new('t/share/test-map.metro');
    my $graph = $metro->parse;

    is($graph->get_station(0)->name, 'Hjulsta', 'Correct first station');
};

subtest override => sub {
    my $metro = Map::Metro::Shim->new('t/share/test-map.metro', override_line_change_weight => 10);
    my $graph = $metro->parse;

    is($graph->get_station(0)->name, 'Hjulsta', 'Correct first station');

};
subtest routing => sub {
    my $metro = Map::Metro::Shim->new('t/share/test-map.metro', override_line_change_weight => 10);
    my $graph = $metro->parse;
    my $routing = $graph->routing_for(qw/1 4/);

    is($routing->get_route(0)->get_step(0)->origin_line_station->station->name, 'Hjulsta', 'Correct first station');

    my $routing_hash = $routing->to_hash;
    is $routing_hash->{'routes'}[0]{'steps'}[1]{'origin_line_station'}{'station'}{'name'}, 'Tensta', 'Basic to_hash test';
};

done_testing;
