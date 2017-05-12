use Geo::GeoNames;
use Data::Printer;

my $geo = Geo::GeoNames->new(
	username => 'briandfoy',
	);

my $results = $geo->find_nearby_placename(
	lat => $ARGV[0],
	lng => $ARGV[1],
	);

p $results;

__END__
              <LatitudeDegrees>30.0082800</LatitudeDegrees>
              <LongitudeDegrees>31.1053410</LongitudeDegrees>
            </Position>

\ [
    [0] {
        countryCode   "EG",
        countryName   "Egypt",
        distance      1.40427,
        fcl           "P",
        fcode         "PPL",
        geonameId     8139751,
        lat           30.01445,
        lng           31.11807,
        name          "‘Izbat Dhū al Fiqār",
        toponymName   "‘Izbat Dhū al Fiqār"
    }
]
