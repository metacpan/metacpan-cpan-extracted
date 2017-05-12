###############################################################################
#                                                                             #
#          Geo::Postcodes::NO Test Suite 1 - Procedural interface             #
#          ------------------------------------------------------             # 
#             Arne Sommer - perl@bbop.org  - 9. September 2006                #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 1_procedures.t'.  #
#                                                                             #
###############################################################################

use Test::More tests => 52;

BEGIN { use_ok('Geo::Postcodes::NO') };

#################################################################################

ok(   Geo::Postcodes::NO::legal ("0010"), "Legal postcode");
ok(   Geo::Postcodes::NO::valid ("0010"), "Postcode in use");
ok(   Geo::Postcodes::NO::legal ("1178"), "Legal postcode");
ok(   Geo::Postcodes::NO::valid ("1178"), "Postcode in use");
ok(   Geo::Postcodes::NO::legal ("2542"), "Legal postcode");
ok(   Geo::Postcodes::NO::valid ("2542"), "Postcode in use");

ok(   Geo::Postcodes::NO::legal ("0000"), "Legal postcode");
ok( ! Geo::Postcodes::NO::valid ("0000"), "Postcode not in use");
ok(   Geo::Postcodes::NO::legal ("9999"), "Legal postcode");
ok( ! Geo::Postcodes::NO::valid ("9999"), "Illegal postcode");

ok( ! Geo::Postcodes::NO::legal ("10"),              "Illegal postcode");
ok( ! Geo::Postcodes::NO::valid ("10"),              "Illegal postcode");
ok( ! Geo::Postcodes::NO::legal ("Ett eller annet"), "Illegal postcode");
ok( ! Geo::Postcodes::NO::valid ("Ett eller annet"), "Illegal postcode");

#################################################################################

my $postcode = "1178"; # My postal code.

is( Geo::Postcodes::NO::location_of      ($postcode), "OSLO", "Postcode > Location");
is( Geo::Postcodes::NO::borough_number_of($postcode), "0301", "Postcode > Borough number");
is( Geo::Postcodes::NO::borough_of       ($postcode), "OSLO", "Postcode > Borough");
is( Geo::Postcodes::NO::county_of        ($postcode), "OSLO", "Postcode > County");
is( Geo::Postcodes::NO::borough_number2county  (Geo::Postcodes::NO::borough_number_of($postcode)), "OSLO", "Borough number > County");
is( Geo::Postcodes::NO::type_of          ($postcode), "ST",             "Postcode > Type");
is( Geo::Postcodes::NO::type_verbose_of  ($postcode), "Gateadresse",    "Postcode > Type");
is( Geo::Postcodes::type_verbose_of      ($postcode), undef,            "Postcode > Type");

## Try another one, where the names differ. #####################################

$postcode = "2542"; # Another one.

is( Geo::Postcodes::NO::location_of      ($postcode), "VINGELEN",    "Postcode > Location");
is( Geo::Postcodes::NO::borough_number_of($postcode), "0436",        "Postcode > Borough number");
is( Geo::Postcodes::NO::borough_of       ($postcode), "TOLGA",       "Postcode > Borough");
is( Geo::Postcodes::NO::county_of        ($postcode), "HEDMARK",     "Postcode > County");
is( Geo::Postcodes::NO::borough_number2county  (Geo::Postcodes::NO::borough_number_of($postcode)), "HEDMARK", "Borough Number > County");
is( Geo::Postcodes::NO::type_of          ($postcode), "ST",          "Postcode > Type");
is( Geo::Postcodes::NO::type_verbose_of  ($postcode), "Gateadresse", "Postcode > Type");
is( Geo::Postcodes::type_verbose_of      ($postcode), undef,         "Postcode > Type");

## And now, error handling ######################################################

is( Geo::Postcodes::NO::location_of ("9999"),            undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::location_of (undef),             undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::location_of ("Ett eller annet"), undef, "Undef caused by illegal postcode");

is( Geo::Postcodes::NO::borough_number_of ("9999"),            undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::borough_number_of (undef),             undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::borough_number_of ("Ett eller annet"), undef, "Undef caused by illegal postcode");

is( Geo::Postcodes::NO::borough_of ("9999"),            undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::borough_of (undef),             undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::borough_of ("Ett eller annet"), undef, "Undef caused by illegal postcode");

is( Geo::Postcodes::NO::borough_number2borough ("9999"),            undef, "Undef caused by illegal borough number");
is( Geo::Postcodes::NO::borough_number2borough (undef),             undef, "Undef caused by illegal borough number");
is( Geo::Postcodes::NO::borough_number2borough ("Ett eller annet"), undef, "Undef caused by illegal borough number");

is( Geo::Postcodes::NO::county_of ("9999"),            undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::county_of (undef),             undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::county_of ("Ett eller annet"), undef, "Undef caused by illegal postcode");

is( Geo::Postcodes::NO::borough_number2county ("9999"),            undef, "Undef caused by illegal borough number");
is( Geo::Postcodes::NO::borough_number2county (undef),             undef, "Undef caused by illegal borough number");
is( Geo::Postcodes::NO::borough_number2county ("Ett eller annet"), undef, "Undef caused by illegal borough number");

is( Geo::Postcodes::NO::type_of ("9999"),            undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::type_of (undef),             undef, "Undef caused by illegal postcode");
is( Geo::Postcodes::NO::type_of ("Ett eller annet"), undef, "Undef caused by illegal postcode");

#################################################################################
