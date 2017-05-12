use strict;
use warnings;

use Test::Most;
use IO::File;

BEGIN { use_ok('Geo::GoogleEarth::AutoTour'); }

throws_ok(
    sub {
        Geo::GoogleEarth::AutoTour::tour();
    },
    qr/Input not defined/,
    'tour() fails without input',
);

my $input = IO::File->new( 't/0_data.kmz', '<' ) or die $!;
my $tour  = IO::File->new( 't/0_tour.kmz', '<' ) or die $!;

my ( $kml_input, $kml_tour, $output );

lives_ok(
    sub {
        $kml_input = Geo::GoogleEarth::AutoTour::kmz_to_xml($input);
        $kml_tour  = Geo::GoogleEarth::AutoTour::tour($kml_input);
    },
    'tour() stand-alone execution',
);

throws_ok(
    sub {
        Geo::GoogleEarth::AutoTour::build_tour({});
    },
    qr/Points not defined properly/,
    'Points not defined properly throws',
);

lives_ok(
    sub {
        Geo::GoogleEarth::AutoTour::build_tour({ points => [
            {
                'time' => time,
            },
        ] });
    },
    'build_tour() stand-alone lives',
);

done_testing;
