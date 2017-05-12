###############################################################################
#                                                                             #
#            Geo::Postcodes::DK Test Suite 4 - Available fields               #
#            --------------------------------------------------               #
#             Arne Sommer - perl@bbop.org  - 9. September 2006                #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 4_fields.t'.      #
#                                                                             #
###############################################################################

use Test::More tests => 20;

BEGIN { use_ok('Geo::Postcodes::DK') };

###############################################################################

my @fields  = qw(postcode location address owner type type_verbose);

my @fields1 = Geo::Postcodes::DK::get_fields();
my @fields2 = Geo::Postcodes::DK->get_fields();

is_deeply(\@fields, \@fields1, "Geo::Postcodes::DK::get_fields()");
is_deeply(\@fields, \@fields2, "Geo::Postcodes::DK->get_fields()");

foreach (@fields)
{
  ok (Geo::Postcodes::DK::is_field($_), "Geo::Postcodes::DK::is_field()");
  ok (Geo::Postcodes::DK->is_field($_), "Geo::Postcodes::DK->is_field()");
}

foreach (qw (just kidding))
{
  ok (! Geo::Postcodes::DK::is_field($_), "Geo::Postcodes::DK::is_field()");
  ok (! Geo::Postcodes::DK->is_field($_), "Geo::Postcodes::DK->is_field()");
}

is (Geo::Postcodes::DK::selection("kidding", "1299"), undef);