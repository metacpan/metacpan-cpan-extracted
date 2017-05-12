use Test::Most;

use Geo::UK::Postcode::CodePointOpen;

ok my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => 'corpus' ), "new";

ok my $column_headers = $cpo->column_headers, "column headers";

is_deeply $column_headers,
    {
    short => [qw/ PC PQ EA NO CY RH LH CC DC WC /],
    long  => [
        qw/ Postcode Positional_quality_indicator Eastings Northings Country_code NHS_regional_HA_code NHS_HA_code Admin_county_code Admin_district_code Admin_ward_code /
    ],
    },
    "column headers ok";

done_testing();

