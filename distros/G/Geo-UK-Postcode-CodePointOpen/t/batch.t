use Test::Most;

use Geo::UK::Postcode::CodePointOpen;

ok my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => 'corpus' ),
    'new object';

ok my $bi = $cpo->batch_iterator( batch_size => 4 ), 'got batch_iterator';


my @batches;
while (my (@batch) = $bi->() ) {
    push @batches, \@batch;
}

is scalar(@batches), 5, "got correct number of batches";
is scalar(@{$batches[0]}), 4, "got batch size of 4";

is_deeply $batches[0]->[0],
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

done_testing();

