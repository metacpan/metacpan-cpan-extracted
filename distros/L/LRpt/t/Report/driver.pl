#!/usr/bin/perl -w
##########################################################################
#
# $Id: driver.pl,v 1.9 2006/09/17 08:00:00 pkaluski Exp $
# $Name: Stable_0_16 $
#
# Tests for LRpt::Report object
#
# $Log: driver.pl,v $
# Revision 1.9  2006/09/17 08:00:00  pkaluski
# Added tests for new command line switches and environment variables
#
# Revision 1.8  2006/09/10 18:45:06  pkaluski
# Added new test for chunking. Modified all tests to accommodate new parameters layout.
#
# Revision 1.7  2006/04/09 15:42:59  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
# Revision 1.6  2006/02/10 22:32:18  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.5  2006/01/07 23:50:44  pkaluski
# Unit test for new tool chain implemented. Session manager not needed any more.
#
# Revision 1.4  2005/10/01 22:56:29  pkaluski
# Added tests for StateMgr class
#
# Revision 1.3  2005/01/28 22:52:26  pkaluski
# Got rid of DBSource and Config. They are almost not used
#
# Revision 1.2  2004/12/17 22:19:23  pkaluski
# Where keys are not given in the form of xml files any more.
#
# Revision 1.1.1.1  2004/10/02 11:31:23  pkaluski
# Changed the naming convention. All packages start with LRpt
#
#
#
##########################################################################

use strict;
use DBI;
use File::Path;
use test_support;
use Test::Simple tests => 1;

test_support::store_test_dir();

ok( test_std_creation_1(), "Standard creation of the report" );

#
# Compares the generated document with the expected document.
# Compares tables' dumps.
# Since it reads from the database, the database should contain the right
# data for the test to pass
#
sub test_std_creation_1
{
    my $test_dir = test_support::get_test_dir() . "/Report/t1";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    #
    # Delete results from previous test run
    #
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    mkdir( "$act_dir/Data" ) or 
                     die "Cannot create directoty $act_dir/Data: $!";

    system( "lks.pl --keys=$test_dir/keys.txt " . 
                   "$test_dir/selects.txt " .
                   ">$act_dir/sel_subs.txt" );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file.txt " . 
                   "--path=$act_dir/Data " .
                   "$act_dir/sel_subs.txt " ); 
    system( "lrptxml.pl --selects=$act_dir/sel_subs.txt " .
                   "--keys_file=$test_dir/rkeys.txt " .
                   "$act_dir/Data > $act_dir/report.xml" );

    return test_support::compare_dirs( $exp_dir, $act_dir );

}    
