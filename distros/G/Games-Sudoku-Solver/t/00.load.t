#
#===============================================================================
#
#         FILE:  00.load.t
#
#  DESCRIPTION:  module load test
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr.-Ing. Fritz Mehner (Mn), <mehner@fh-swf.de>
#      COMPANY:  Fachhochschule Südwestfalen, Iserlohn
#      VERSION:  1.0
#      CREATED:  30.05.2007 13:52:47 CEST
#     REVISION:  $Id: 00.load.t,v 1.1.1.1 2007/05/30 12:05:03 mehner Exp $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

BEGIN {
use_ok( 'Games::Sudoku::Solver' );
}

diag( "Testing Games::Sudoku::Solver $Games::Sudoku::Solver::VERSION" );
