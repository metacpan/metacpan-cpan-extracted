###############################################################################
#                                                                             #
#                Geo::Postcodes::DK Test Suite 8 - Exporter                   #
#            --------------------------------------------------               #
#             Arne Sommer - perl@bbop.org - 11. September 2006                #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 8_exporter.t'.    #
#                                                                             #
###############################################################################

# Note that the module do not export anything at present. This may change.    #

use Test::More tests => 6;

BEGIN { use_ok('Geo::Postcodes::DK', 0.30) };

###############################################################################

my @validity = qw(valid legal);
can_ok('Geo::Postcodes::DK', @validity);

can_ok('Geo::Postcodes::DK', 'get_postcodes');

can_ok('Geo::Postcodes::DK', 'get_fields', 'is_field');

my @fields = Geo::Postcodes::DK::get_fields();
can_ok('Geo::Postcodes::DK', @fields);

my @selection = qw(selection selection_loop);

can_ok('Geo::Postcodes::DK', @selection);

