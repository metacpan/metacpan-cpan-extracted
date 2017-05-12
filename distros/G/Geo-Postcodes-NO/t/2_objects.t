###############################################################################
#                                                                             #
#            Geo::Postcodes::NO Test Suite 2 - Object interface               #
#            --------------------------------------------------               # 
#               Arne Sommer - perl@bbop.org  - 19. July 2006                  #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 2_objects.t'.     #
#                                                                             #
###############################################################################

use Test::More tests => 22;

BEGIN { use_ok('Geo::Postcodes::NO') };

#################################################################################

my $P = Geo::Postcodes::NO->new("1178"); # My postal code.
isa_ok($P, "Geo::Postcodes::NO");

is( $P->postcode(),       "1178",         "Postcode object > Postcode");
is( $P->location(),       "OSLO",         "Postcode object > Borough number");
is( $P->borough_number(), "0301",         "Postcode object > Borough number");
is( $P->borough(),        "OSLO",         "Postcode object > Borough");
is( $P->county(),         "OSLO",         "Postcode object > County");
is( $P->type(),           "ST",           "Postcode > Type");
is( $P->type_verbose(),   "Gateadresse",  "Postcode > Type");
is( $P->Geo::Postcodes::type_verbose(),   "Street address", "Postcode > Type");

## Try another one, where the names differ. #####################################

my $P2 = Geo::Postcodes::NO->new("2542"); # Another one.
isa_ok($P2, "Geo::Postcodes::NO");

is( $P2->postcode(),       "2542",         "Postcode object > Postcode");
is( $P2->location(),       "VINGELEN",     "Postcode object > Borough number");
is( $P2->borough_number(), "0436",         "Postcode object > Borough number");
is( $P2->borough(),        "TOLGA",        "Postcode object > Borough");
is( $P2->county(),         "HEDMARK",      "Postcode object > County");
is( $P2->type(),           "ST",           "Postcode > Type");
is( $P2->type_verbose(),   "Gateadresse",  "Postcode > Type");
is( $P2->Geo::Postcodes::type_verbose(),   "Street address", "Postcode > Type");

## And now, error handling ######################################################

my $P3 = Geo::Postcodes::NO->new("9999"); # This postcode is not in use.
is( $P3, undef,  "Undef caused by illegal postcode");

$P3 = Geo::Postcodes::NO->new(undef); 
is( $P3, undef,  "Undef caused by illegal postcode");

$P3 = Geo::Postcodes::NO->new("Totusensekshundreognoenogtredve"); 
is( $P3, undef,  "Undef caused by illegal postcode");

#################################################################################

