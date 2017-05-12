# Test to see if we can use Geo::ReadGRIB. 
# This will also tell us if the module can find wgrib.exe

use Test::More tests => 1;


###########################################################################
# Exist test
###########################################################################

use_ok('Geo::ReadGRIB');  # If we made it this far, we're ok.



