###############################################################################
#                                                                             #
#              Geo::Postcodes Test Suite 2 - Pod Verification                 #
#        -----------------------------------------------------------          #
#             Arne Sommer - perl@bbop.org  - 7. September 2006                #
#                                                                             #
###############################################################################
#                                                                             #
# Note that the tests in this file file requires 'List::MoreUtils' to work.   #
# They will be skipped otherwise.                                             #
#                                                                             #
###############################################################################

use Test::More;

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();

###############################################################################
