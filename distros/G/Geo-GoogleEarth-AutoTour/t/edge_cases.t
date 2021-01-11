use Test2::V0;
use Geo::GoogleEarth::AutoTour;
use IO::File;

ok (
    dies {
        Geo::GoogleEarth::AutoTour::tour();
    },
    qr/Input not defined/,
    'tour() fails without input',
);

my $input = IO::File->new( 't/0_data.kmz', '<' ) or die $!;
my $tour  = IO::File->new( 't/0_tour.kmz', '<' ) or die $!;

my ( $kml_input, $kml_tour, $output );

ok(
    lives {
        $kml_input = Geo::GoogleEarth::AutoTour::kmz_to_xml($input);
        $kml_tour  = Geo::GoogleEarth::AutoTour::tour($kml_input);
    },
    'tour() stand-alone execution',
) or note $@;

ok(
    dies {
        Geo::GoogleEarth::AutoTour::build_tour({});
    },
    qr/Points not defined properly/,
    'Points not defined properly throws',
);

ok(
    lives {
        Geo::GoogleEarth::AutoTour::build_tour({ points => [
            {
                'time' => time,
            },
        ] });
    },
    'build_tour() stand-alone lives',
) or note $@;

done_testing;
