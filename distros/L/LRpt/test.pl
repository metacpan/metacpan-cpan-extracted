############################################################################
#
# $Id: test.pl,v 1.1.1.1 2004/10/02 11:31:05 pkaluski Exp $
# $Name: Stable_0_16 $
#
# Main test driver
#
# $Log: test.pl,v $
# Revision 1.1.1.1  2004/10/02 11:31:05  pkaluski
# Changed the naming convention. All packages start with LRpt
#
#
# 
############################################################################
use Cwd;
use lib "" . getcwd(). "/..";
use lib "t";
use strict;
use test_support;
use Test::Harness;


runtests( "t/Report/driver.pl", 
          "t/DiffRpt/driver.pl" );

