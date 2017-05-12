###############################################################################
#                                                                             #
#              Geo::Postcodes::DK Test Suite 7 - Pod Coverage                 #
#        -----------------------------------------------------------          #
#             Arne Sommer - perl@bbop.org  - 7. September 2006                #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 7_pod_coverage.t'.#
#                                                                             #
###############################################################################
#                                                                             #
# Note that the tests in this file file requires 'List::MoreUtils' to work.   #
# Thet will be skipped otherwise.                                             #
#                                                                             #
###############################################################################

use Test::More;

eval "use Test::Pod::Coverage 1.00";

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

all_pod_coverage_ok();

###############################################################################
