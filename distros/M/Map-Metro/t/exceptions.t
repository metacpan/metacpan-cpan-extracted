use strict;
use Test::More;
use Test::Exception;

use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Try::Tiny;
use Map::Metro;
use Map::Metro::Shim;

subtest non_existing => sub {
    my $metro = Map::Metro::Shim->new('t/share/test-map.metro');
    my $graph = $metro->parse;

    my $station_does_not_exist = try { $graph->get_station_by_name('Doesnotexist', check => 1) } catch { $_->desc };
    is $station_does_not_exist, 'Station name [Doesnotexist] does not exist in station list (check segments or arguments)', 'Exception on non-existing station';

    my $line_id_does_not_exist = try { $graph->get_line_by_id(1111) } catch { $_->desc };
    is $line_id_does_not_exist, 'Line id [1111] does not exist in line list (maybe check segments?)', 'Exception on non-existing line id';
};
subtest metro => sub {
    my $non_existing_map = try { Map::Metro->new('NonExistingMap') } catch { $_ };
    like $non_existing_map, qr/^Could not find map with name \[NonExistingMap\] \(check if it is installed\)/, 'Exception loading non-existing map';
};

done_testing;
