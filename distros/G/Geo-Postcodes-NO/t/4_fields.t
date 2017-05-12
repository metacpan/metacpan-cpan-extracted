###############################################################################
#                                                                             #
#            Geo::Postcodes::NO Test Suite 4 - Available fields               #
#            --------------------------------------------------               #
#             Arne Sommer - perl@bbop.org  - 9. September 2006                #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 4_fields.t'.      #
#                                                                             #
###############################################################################

use Test::More tests => 22;

BEGIN { use_ok('Geo::Postcodes::NO') };

###############################################################################

my @fields  = qw(postcode location borough borough_number county type
                  type_verbose);

my @fields1 = Geo::Postcodes::NO::get_fields();
my @fields2 = Geo::Postcodes::NO->get_fields();

is_deeply(\@fields, \@fields1, "Geo::Postcodes::NO::fields()");
is_deeply(\@fields, \@fields2, "Geo::Postcodes::NO->fields()");

foreach (@fields)
{
  ok (Geo::Postcodes::NO::is_field($_), "Geo::Postcodes::NO::is_field()");
  ok (Geo::Postcodes::NO->is_field($_), "Geo::Postcodes::NO->is_field()");
}

foreach (qw (just kidding))
{
  ok (! Geo::Postcodes::NO::is_field($_), "Geo::Postcodes::NO::is_field()");
  ok (! Geo::Postcodes::NO->is_field($_), "Geo::Postcodes::NO->is_field()");
}

is (Geo::Postcodes::NO::selection('and', "kidding", "1299"), undef);