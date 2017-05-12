#
#===============================================================================
#
#         FILE: 00.load.t
#
#  DESCRIPTION: module load test
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Dr. Fritz Mehner (fgm), mehner.fritz@web.de
#      VERSION: 1.0
#      CREATED: 06.06.2007 19:51:15 CEST
#===============================================================================

use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

BEGIN {
    use_ok( 'Graphics::GnuplotIF' );
}

diag( "Testing GnuplotIF $Graphics::GnuplotIF::VERSION" );
