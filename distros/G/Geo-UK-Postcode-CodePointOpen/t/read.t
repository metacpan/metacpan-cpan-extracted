use Test::Most;

use Geo::UK::Postcode::CodePointOpen;
use Geo::UK::Postcode::Regex;

ok my $cpo = Geo::UK::Postcode::CodePointOpen->new(
    path  => 'corpus',
    pc_re => Geo::UK::Postcode::Regex->regex,    # allow XX10 outcode
    ),
    'new object';

{
    note "defaults";
    ok my $ri = $cpo->read_iterator(), 'got read_iterator';

    my @pcs;
    while ( my $row = $ri->() ) {
        push @pcs, $row;
    }

    is scalar(@pcs), 20, "read correct number of postcodes";

    is_deeply $pcs[0],
        {
        Admin_county_code            => "",
        Admin_district_code          => "S12000033",
        Admin_ward_code              => "S13002483",
        Country_code                 => "S92000003",
        Eastings                     => 394251,
        NHS_HA_code                  => "S08000006",
        NHS_regional_HA_code         => "",
        Northings                    => 806376,
        Positional_quality_indicator => 10,
        Postcode                     => "XX101AA"
        },
        "sample row ok";
}

{
    note "split_postcode";

    ok my $ri = $cpo->read_iterator( split_postcode => 1 ), 'got read_iterator';

    my @pcs;
    while ( my $row = $ri->() ) {
        push @pcs, $row;
    }

    is scalar(@pcs), 20, "read correct number of postcodes";

    is_deeply $pcs[0],
        {
        Admin_county_code            => "",
        Admin_district_code          => "S12000033",
        Admin_ward_code              => "S13002483",
        Country_code                 => "S92000003",
        Eastings                     => 394251,
        Incode                       => '1AA',
        NHS_HA_code                  => "S08000006",
        NHS_regional_HA_code         => "",
        Northings                    => 806376,
        Outcode                      => 'XX10',
        Positional_quality_indicator => 10,
        Postcode                     => "XX101AA"
        },
        "sample row ok";
}

{
    note "outcodes";

    ok my $ri = $cpo->read_iterator( outcodes => [qw/ AB10 WC1 XX10 /] ),
        'got read_iterator';

    my @pcs;
    while ( my $row = $ri->() ) {
        push @pcs, $row;
    }

    is scalar(@pcs), 10, "read correct number of postcodes";

    is_deeply $pcs[0],
        {
        Admin_county_code            => "",
        Admin_district_code          => "S12000033",
        Admin_ward_code              => "S13002483",
        Country_code                 => "S92000003",
        Eastings                     => 394251,
        NHS_HA_code                  => "S08000006",
        NHS_regional_HA_code         => "",
        Northings                    => 806376,
        Positional_quality_indicator => 10,
        Postcode                     => "XX101AA"
        },
        "sample row ok";
}

{
    note "include_lat_long";

    ok my $ri = $cpo->read_iterator( include_lat_long => 1 ),
        'got read_iterator';

    my @pcs;
    while ( my $row = $ri->() ) {
        push @pcs, $row;
    }

    is scalar(@pcs), 20, "read correct number of postcodes";

    is_deeply $pcs[0],
        {
        Admin_county_code            => "",
        Admin_district_code          => "S12000033",
        Admin_ward_code              => "S13002483",
        Country_code                 => "S92000003",
        Eastings                     => 394251,
        Latitude                     => '57.14822',
        Longitude                    => '-2.09666',
        NHS_HA_code                  => "S08000006",
        NHS_regional_HA_code         => "",
        Northings                    => 806376,
        Positional_quality_indicator => 10,
        Postcode                     => "XX101AA"
        },
        "sample row ok";
}

done_testing();

