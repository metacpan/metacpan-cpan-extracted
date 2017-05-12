###############################################################################
#                                                                             #
#                  Geo::Postcodes Test Suite 4 - Exporter                     #
#            --------------------------------------------------               #
#             Arne Sommer - perl@bbop.org - 11. September 2006                #
#                                                                             #
###############################################################################

# Note that the module do not export anything at present. This may change.    #

use Test::More tests => 6;

BEGIN { use_ok('Geo::Postcodes', 0.30) };

###############################################################################

my @validity = qw(valid legal);
can_ok('Geo::Postcodes', @validity);

can_ok('Geo::Postcodes', 'get_postcodes');

can_ok('Geo::Postcodes', 'get_fields', 'is_field');

my @fields = Geo::Postcodes::get_fields();
can_ok('Geo::Postcodes', @fields);

my @selection = qw(selection
                   selection_loop
                   verify_selectionlist
                   get_selectionmodes get_initial_selectionmodes 
                   is_legal_selectionmode is_legal_initial_selectionmode);

can_ok('Geo::Postcodes', @selection);

