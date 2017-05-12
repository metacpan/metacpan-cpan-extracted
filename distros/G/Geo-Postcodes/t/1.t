###############################################################################
#                                                                             #
#                     Geo::Postcodes - Stub Test Suite                        #
#          ------------------------------------------------------             #
#               Arne Sommer - perl@bbop.org  - 30. July 2006                  #
#                                                                             #
###############################################################################

use Test::More tests => 22;

BEGIN { use_ok('Geo::Postcodes') };

#################################################################################

ok( ! Geo::Postcodes::legal ("0010"),               "Postcode > Legal");
ok( ! Geo::Postcodes::valid ("0010"),               "Postcode > Valid");
ok( ! Geo::Postcodes::legal ("9999"),               "Postcode > Legal");
ok( ! Geo::Postcodes::valid ("9999"),               "Postcode > Valid");
ok( ! Geo::Postcodes::legal ("10"),                 "Postcode > Legal");
ok( ! Geo::Postcodes::valid ("10"),                 "Postcode > Valid");
ok( ! Geo::Postcodes::legal ("Something or other"), "Postcode > Legal");
ok( ! Geo::Postcodes::valid ("Something or other"), "Postcode > Valid");

#################################################################################

is( Geo::Postcodes::location_of ("1178"), undef, "Postcode > Location");
is( Geo::Postcodes::borough_of  ("1178"), undef, "Postcode > Borough");
is( Geo::Postcodes::county_of   ("1178"), undef, "Postcode > County");
is( Geo::Postcodes::type_of     ("1178"), undef, "Postcode > Type");
is( Geo::Postcodes::owner_of    ("1178"), undef, "Postcode > Owner");
is( Geo::Postcodes::address_of  ("1178"), undef, "Postcode > Address");

#################################################################################

is( Geo::Postcodes::location_of ("Something or other"), undef, "Postcode > Location");
is( Geo::Postcodes::borough_of  ("Something or other"), undef, "Postcode > Borough");
is( Geo::Postcodes::county_of   ("Something or other"), undef, "Postcode > County");
is( Geo::Postcodes::type_of     ("Something or other"), undef, "Postcode > Type");
is( Geo::Postcodes::owner_of    ("Something or other"), undef, "Postcode > Owner");
is( Geo::Postcodes::address_of  ("Something or other"), undef, "Postcode > Address");

#################################################################################

is( Geo::Postcodes::selection   ("and", "postcode" => ".*"), undef, "Selection and");

#################################################################################
