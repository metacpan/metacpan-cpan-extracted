###############################################################################
#                                                                             #
#            Geo::Postcodes::DK Test Suite 2 - Object interface               #
#            --------------------------------------------------               # 
#               Arne Sommer - perl@bbop.org  - 19. July 2006                  #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 2_objects.t'.     #
#                                                                             #
###############################################################################

use Test::More tests => 20;

BEGIN { use_ok('Geo::Postcodes::DK') };

#################################################################################

my $P = Geo::Postcodes::DK->new("1171");
isa_ok($P, "Geo::Postcodes::DK");

is( $P->postcode(),                     "1171",           "Postcode object > Postcode");
is( $P->location(),                     "København K",    "Postcode object > Location");
is( $P->type(),                         "ST",             "Postcode object > Type");
is( $P->type_verbose(),                 "Gadeadresse",    "Postcode object > Type");
is( $P->Geo::Postcodes::type_verbose(), "Street address", "Postcode object > Type");
is( $P->address(),                      "Fiolstræde",     "Postcode object > Address");
is( $P->owner(),                        undef,            "Postcode object > Owner");

#################################################################################

my $P2 = Geo::Postcodes::DK->new("215"); # Another one.
isa_ok($P2, "Geo::Postcodes::DK");

is( $P2->postcode(),                     "215",             "Postcode object > Postcode");
is( $P2->location(),                     "Sandur",          "Postcode object > Location");
is( $P2->type(),                         "BX",              "Postcode object > Type");
is( $P2->type_verbose(),                 "Postboks",        "Postcode object > Type");
is( $P2->Geo::Postcodes::type_verbose(), "Post Office box", "Postcode object > Type");
is( $P2->address(),                      undef,             "Postcode object > Address");
is( $P2->owner(),                        undef,             "Postcode object > Owner");

## And now, error handling ######################################################

my $P3 = Geo::Postcodes::DK->new("9999"); # Dette postnummeret er ikke i bruk.
is( $P3, undef, "Undef caused by illegal postcode");

$P3 = Geo::Postcodes::DK->new(undef); 
is( $P3, undef, "Undef caused by illegal postcode");

$P3 = Geo::Postcodes::DK->new("Totusensekshundreognoenogtredve"); 
is( $P3, undef, "Undef caused by illegal postcode");

#################################################################################
