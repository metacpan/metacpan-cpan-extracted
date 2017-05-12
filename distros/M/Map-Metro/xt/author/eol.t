use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Map/Metro.pm',
    'lib/Map/Metro/Cmd.pm',
    'lib/Map/Metro/Cmd/AllRoutes.pm',
    'lib/Map/Metro/Cmd/Available.pm',
    'lib/Map/Metro/Cmd/Graphviz.pm',
    'lib/Map/Metro/Cmd/Lines.pm',
    'lib/Map/Metro/Cmd/MetroToTube.pm',
    'lib/Map/Metro/Cmd/Route.pm',
    'lib/Map/Metro/Cmd/Stations.pm',
    'lib/Map/Metro/Elk.pm',
    'lib/Map/Metro/Emitter.pm',
    'lib/Map/Metro/Exceptions.pm',
    'lib/Map/Metro/Graph.pm',
    'lib/Map/Metro/Graph/Connection.pm',
    'lib/Map/Metro/Graph/Line.pm',
    'lib/Map/Metro/Graph/LineStation.pm',
    'lib/Map/Metro/Graph/Route.pm',
    'lib/Map/Metro/Graph/Routing.pm',
    'lib/Map/Metro/Graph/Segment.pm',
    'lib/Map/Metro/Graph/Station.pm',
    'lib/Map/Metro/Graph/Step.pm',
    'lib/Map/Metro/Graph/Transfer.pm',
    'lib/Map/Metro/Hook.pm',
    'lib/Map/Metro/Plugin/Hook/PrettyPrinter.pm',
    'lib/Map/Metro/Plugin/Hook/StreamStations.pm',
    'lib/Map/Metro/Plugin/Map.pm',
    'lib/Map/Metro/Shim.pm',
    'lib/Map/Metro/Types.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/exceptions.t',
    't/share/test-map.metro'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
