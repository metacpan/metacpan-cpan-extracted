#
#===============================================================================
#
#         FILE:  pod.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Frank Lyon Cox (Dr), <frank@pwizardry.com>
#      COMPANY:  Practial Wizardry
#      VERSION:  1.0
#      CREATED:  11/18/2009 12:15:52 PM Pacific Standard Time
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing Pod" if $@;
all_pod_files_ok();
