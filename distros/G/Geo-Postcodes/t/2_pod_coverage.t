###############################################################################
#                                                                             #
#                Geo::Postcodes Test Suite 2 - Pod Coverage                   #
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

eval "use Test::Pod::Coverage 1.00";

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

all_pod_coverage_ok();

###############################################################################
