#
#===============================================================================
#
#         FILE:  pod-coverage.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Frank Lyon Cox (Dr), <frank@pwizardry.com>
#      COMPANY:  Practial Wizardry
#      VERSION:  1.0
#      CREATED:  11/18/2009 12:22:34 PM Pacific Standard Time
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

all_pod_coverage_ok();

