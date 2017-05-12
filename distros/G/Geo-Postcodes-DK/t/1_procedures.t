###############################################################################
#                                                                             #
#          Geo::Postcodes::DK Test Suite 1 - Procedural interface             #
#          ------------------------------------------------------             # 
#             Arne Sommer - perl@bbop.org  - 24. September 2006               #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 1_procedures.t'.  #
#                                                                             #
###############################################################################

use Test::More tests => 34;

BEGIN { use_ok('Geo::Postcodes::DK') };

#################################################################################

ok(   Geo::Postcodes::DK::legal ("0010"),            "Legal postcode");
ok( ! Geo::Postcodes::DK::valid ("0010"),            "Postcode not in use");
ok(   Geo::Postcodes::DK::legal ("0900"),            "Legal postcode");
ok(   Geo::Postcodes::DK::valid ("0900"),            "Postcode in use");
ok( ! Geo::Postcodes::DK::legal ("10"),              "Illegal postcode");
ok( ! Geo::Postcodes::DK::valid ("10"),              "Illegal postcode");
ok( ! Geo::Postcodes::DK::legal ("Ett eller annet"), "Illegal postcode");
ok( ! Geo::Postcodes::DK::valid ("Ett eller annet"), "Illegal postcode");

ok( Geo::Postcodes::DK::legal          ("1171"),                "Legal postcode");
ok( Geo::Postcodes::DK::valid          ("1171"),                "Postcode in use");
is( Geo::Postcodes::DK::location_of    ("1171"), "København K", "Postcode > Location");
is( Geo::Postcodes::DK::type_of        ("1171"), "ST",          "Postcode > Type");
is( Geo::Postcodes::DK::type_verbose_of("1171"), "Gadeadresse", "Postcode > Type");
is( Geo::Postcodes::type_verbose_of    ("1171"), undef,         "Postcode > Type");
is( Geo::Postcodes::DK::address_of     ("1171"), "Fiolstræde",  "Postcode > Address");
is( Geo::Postcodes::DK::owner_of       ("1171"), undef,         "Postcode > Owner");

#################################################################################

ok( Geo::Postcodes::DK::legal          ("215"),             "Legal postcode");
ok( Geo::Postcodes::DK::valid          ("215"),             "Postcode in use");
is( Geo::Postcodes::DK::location_of    ("215"), "Sandur",   "Postcode > Location");
is( Geo::Postcodes::DK::type_of        ("215"), "BX",       "Postcode > Type");
is( Geo::Postcodes::DK::type_verbose_of("215"), "Postboks", "Postcode > Type");
is( Geo::Postcodes::type_verbose_of    ("215"), undef,      "Postcode > Type");
is( Geo::Postcodes::DK::address_of     ("215"), undef,      "Postcode > Address");
is( Geo::Postcodes::DK::owner_of       ("215"), undef,      "Postcode > Owner");

#################################################################################

## The '0999' postcode is not present in current versions of the module.

# ok( Geo::Postcodes::DK::legal          ("0999"),                   "Legal postcode");
# ok( Geo::Postcodes::DK::valid          ("0999"),                   "Postcode in use");
# is( Geo::Postcodes::DK::location_of    ("0999"), "København C",    "Postcode > Location");
# is( Geo::Postcodes::DK::type_of        ("0999"), "IO",             "Postcode > Type");
# is( Geo::Postcodes::DK::type_verbose_of("0999"), "Personlig ejer", "Postcode > Type");
# is( Geo::Postcodes::type_verbose_of    ("0999"), undef,            "Postcode > Type");
# is( Geo::Postcodes::DK::address_of     ("0999"), undef,            "Postcode > Address");
# is( Geo::Postcodes::DK::owner_of       ("0999"), "DR Byen",        "Postcode > Owner");

## And now, error handling ######################################################

ok( ! Geo::Postcodes::DK::legal (undef), "Illegal postcode");
ok( ! Geo::Postcodes::DK::valid (undef), "Postcode not in use");

is( Geo::Postcodes::DK::location_of    (undef), undef, "Postcode > Location");
is( Geo::Postcodes::DK::type_of        (undef), undef, "Postcode > Type");
is( Geo::Postcodes::DK::type_verbose_of(undef), undef, "Postcode > Type");
is( Geo::Postcodes::type_verbose_of    (undef), undef, "Postcode > Type");
is( Geo::Postcodes::DK::type_of        (undef), undef, "Postcode > Type");
is( Geo::Postcodes::DK::address_of     (undef), undef, "Postcode > Address");
is( Geo::Postcodes::DK::owner_of       (undef), undef, "Postcode > Owner");

#################################################################################
