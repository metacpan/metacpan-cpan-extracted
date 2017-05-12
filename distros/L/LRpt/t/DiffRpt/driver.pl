#!/usr/bin/perl -w
##########################################################################
#
# $Id: driver.pl,v 1.15 2006/09/17 07:59:57 pkaluski Exp $
# $Name: Stable_0_16 $
#
# Tests for LRpt::DiffRpt object
#
# $Log: driver.pl,v $
# Revision 1.15  2006/09/17 07:59:57  pkaluski
# Added tests for new command line switches and environment variables
#
# Revision 1.14  2006/09/10 18:44:28  pkaluski
# Added new test for chunking. Modified all tests to accommodate new parameters layout.
#
# Revision 1.13  2006/04/09 18:42:44  pkaluski
# Fixed bug in regression test suite, related to placing full path in diffs.txt file
#
# Revision 1.12  2006/04/09 17:09:23  pkaluski
# Removed useless use statements
#
# Revision 1.11  2006/04/09 15:42:58  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
# Revision 1.10  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.9  2006/01/14 21:06:03  pkaluski
# Tests adjusted to new design.
#
# Revision 1.8  2006/01/14 13:55:33  pkaluski
# New tool design in progress
#
# Revision 1.7  2005/01/28 22:52:24  pkaluski
# Got rid of DBSource and Config. They are almost not used
#
# Revision 1.6  2004/12/17 22:19:16  pkaluski
# Where keys are not given in the form of xml files any more.
#
# Revision 1.5  2004/12/10 21:51:35  pkaluski
# Corrected directory comparison results checking
#
# Revision 1.4  2004/11/02 21:32:30  pkaluski
# Changed DiffRpt to operate on 2 Report objects. Added tests for it. Tests pass
#
# Revision 1.3  2004/10/17 18:22:43  pkaluski
# Added test for unkeyed A-E comparison. The test pass.
#
# Revision 1.2  2004/10/15 21:51:11  pkaluski
# Added test case for logging when comparing with expecations. Fixed some bugs.
#
# Revision 1.1.1.1  2004/10/02 11:31:13  pkaluski
# Changed the naming convention. All packages start with LRpt
#
#
#
##########################################################################

use strict;
use DBI;
use File::Path;
use test_support;
use Test::Simple tests => 11;
use LRpt::CSVDiff;

test_support::store_test_dir();

ok( test_std_creation_bef_aft_1(), "Standard creation of the report ".
                                   "before-after" );
ok( test_std_creation_exp_act_1(), "Standard creation of the report ".
                                   "expected-actual" );
ok( test_std_creation_exp_act_2(), "Standard creation of the report ".
                                   "expected-actual with logging" );
ok( test_std_creation_exp_act_3(), "Standard creation of the report ".
                                   "expected-actual with logging with " . 
                                   "unkeyed expectations" );
ok( test_std_creation_bef_aft_chk_1(), "Standard creation of the report ".
                                   "before-after, chunked" );

ok( test_bef_aft_key(), "Creation of before-after, with key option" );
ok( test_bef_aft_key_cols(), "Creation of before-after, " . 
                             "with key_cols option" );
ok( test_bef_aft_global_keys(), "Creation of before-after, " . 
                              "with global_keys option" );
ok( test_bef_aft_skip_cols(), "Creation of before-after," . 
                               " with skip_cols option" );
ok( test_bef_aft_skip_cols_file(), "Creation of before-after, " . 
                                   "with skip_cols_file option" );

ok( test_bef_aft_schema_diff(), "Creation of before-after," .
                                 "Different schemas" );

#
# Test scenario:
# Create a report of some tables. Then change contents of some tables.
# Then create a report again. Changes should be correctly marked.
# Compares the generated document with the expected document.
# Compares tables' dumps.
# Since it reads from the database, the database should contain the right
# data for the test to pass
#
sub test_std_creation_bef_aft_1
{
    my $test_dir = "t/DiffRpt/t1";
    #my $test_dir = test_support::get_test_dir() . "/DiffRpt/t1";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    mkdir( "$act_dir/before" ) or 
        die "Cannot create directoty $act_dir/before: $!";
    mkdir( "$act_dir/after" ) or 
        die "Cannot create directoty $act_dir/after: $!";

    system( "lks.pl --keys=$test_dir/keys.txt " . 
                   "$test_dir/selects.txt " .
                   ">$act_dir/sel_subs.txt" );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_bef.txt " . 
                   "--path=$act_dir/before " .
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_aft.txt " . 
                   "--path=$act_dir/after " . 
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdiff.pl --all --keys_file=$test_dir/rkeys.txt " .
            "$act_dir/before $act_dir/after > $act_dir/diffs.txt" );
    system( "lrptxml.pl --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/before " .
            " > $act_dir/report_bef.xml" );
    system( "lrptxml.pl --diffs --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/diffs.txt " .
            " > $act_dir/report_aft.xml" );
 
    return test_support::compare_dirs( $exp_dir, $act_dir );

}    


############################################################################
# Generates a report and checks that the reported rows are as expected.
#
# Scenario plan:
# After the change:
# 1st table: 
#     2 new rows
#     3 rows removed
#     2 rows with changed values
#     2 rows unchanged
#
#     Comparison with expectations:
#     1 additional row (unexpected)
#     2 missing rows
#     2 rows with unexpected values
#
# 2nd table:
#     0 new rows
#     2 rows removed
#     1 row with changed values
#
#     expectations:
#     0 additional
#     2 missing
#     0 rows with unexpected values
#
sub test_std_creation_exp_act_1
{
    my $test_dir = "t/DiffRpt/t2";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    mkdir( "$act_dir/before" ) or 
        die "Cannot create directoty $act_dir/before: $!";
    mkdir( "$act_dir/after" ) or 
        die "Cannot create directoty $act_dir/after: $!";
 
    system( "lks.pl --keys=$test_dir/keys.txt " . 
                   "$test_dir/selects.txt " .
                   ">$act_dir/sel_subs.txt" );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_bef.txt " . 
                   "--path=$act_dir/before " .
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_aft.txt " . 
                   "--path=$act_dir/after " . 
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdiff.pl --all --keys_file=$test_dir/rkeys.txt " .
            "$act_dir/before $act_dir/after > $act_dir/diffs.txt" );
    system( "lrptxml.pl --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/before " .
            " > $act_dir/report_bef.xml" );
    system( "lrptxml.pl --diffs --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/diffs.txt " .
            " > $act_dir/report_aft.xml" );
    system( "lcsveadiff.pl --keys_file=$test_dir/rkeys.txt " . 
            "--expectations=$test_dir/exp.xml " .
            "--cmp_rules=$test_dir/cmp_rules.xml $act_dir/after " .
            "> $act_dir/eadiffs.xml" );
    
    return test_support::compare_dirs( $exp_dir, $act_dir );

}    

############################################################################
# Generates a report and checks that the reported rows are as expected.
# Scenario is similar to scenario test_std_creation_exp_act_1. The only
# difference is that not every field is defined in expectations, so the
# differences are logged.
#
# Scenario plan:
# After the change:
# 1st table: 
#     2 new rows
#     3 rows removed
#     2 rows with changed values
#     2 rows unchanged
#
#     Comparison with expectations:
#     1 additional row (unexpected)
#     2 missing rows
#     2 rows with unexpected values
#
# 2nd table:
#     0 new rows
#     2 rows removed
#     1 row with changed values
#
#     expectations:
#     0 additional
#     2 missing
#     0 rows with unexpected values
#
    
sub test_std_creation_exp_act_2
{
    my $test_dir = "t/DiffRpt/t3";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    mkdir( "$act_dir/before" ) or 
        die "Cannot create directoty $act_dir/before: $!";
    mkdir( "$act_dir/after" ) or 
        die "Cannot create directoty $act_dir/after: $!";
 
    system( "lks.pl --keys=$test_dir/keys.txt " . 
                   "$test_dir/selects.txt " .
                   ">$act_dir/sel_subs.txt" );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_bef.txt " . 
                   "--path=$act_dir/before " .
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_aft.txt " . 
                   "--path=$act_dir/after " . 
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdiff.pl --all --keys_file=$test_dir/rkeys.txt " .
            "$act_dir/before $act_dir/after > $act_dir/diffs.txt" );
    system( "lrptxml.pl --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/before " .
            " > $act_dir/report_bef.xml" );
    system( "lrptxml.pl --diffs --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/diffs.txt " .
            " > $act_dir/report_aft.xml" );
    system( "lcsveadiff.pl --keys_file=$test_dir/rkeys.txt " . 
            "--expectations=$test_dir/exp.xml " .
            "--cmp_rules=$test_dir/cmp_rules.xml $act_dir/after " .
            "--log_file=$act_dir/diff_msg.log > $act_dir/eadiffs.xml" );
    
    if( test_support::compare_logs( "$test_dir/actual/diff_msg.log",
                                    "$test_dir/expected/diff_msg.log" ) and 
        test_support::compare_dirs( $exp_dir, $act_dir, [ "diff_msg.log" ]) )
    {
         return 1;
    }else{   
        return 0;
    }
}    
    
############################################################################
# Generates a report and checks that the reported rows are as expected.
# Scenario is similar to scenario test_std_creation_exp_act_1. The only
# difference is that not every field is defined in expectations, so the
# differences are logged. Moreover, some rows defined in expectations do
# not have a key specified.
#
# Scenario plan:
# After the change:
# 1st table: 
#     2 new rows
#     3 rows removed
#     2 rows with changed values
#     2 rows unchanged
#
#     Comparison with expectations:
#     1 additional row (unexpected)
#     2 missing rows
#     2 rows with unexpected values
#
# 2nd table:
#     0 new rows
#     2 rows removed
#     1 row with changed values
#
#     expectations:
#     0 additional
#     2 missing
#     0 rows with unexpected values
#
    
sub test_std_creation_exp_act_3
{
    my $test_dir = "t/DiffRpt/t4";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    mkdir( "$act_dir/before" ) or 
        die "Cannot create directoty $act_dir/before: $!";
    mkdir( "$act_dir/after" ) or 
        die "Cannot create directoty $act_dir/after: $!";
 
    system( "lks.pl --keys=$test_dir/keys.txt " . 
                   "$test_dir/selects.txt " .
                   ">$act_dir/sel_subs.txt" );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_bef.txt " . 
                   "--path=$act_dir/before " .
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_aft.txt " . 
                   "--path=$act_dir/after " . 
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdiff.pl --all --keys_file=$test_dir/rkeys.txt " .
            "$act_dir/before $act_dir/after > $act_dir/diffs.txt" );
    system( "lrptxml.pl --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/before " .
            " > $act_dir/report_bef.xml" );
    system( "lrptxml.pl --diffs --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/diffs.txt " .
            " > $act_dir/report_aft.xml" );
    system( "lcsveadiff.pl --keys_file=$test_dir/rkeys.txt " . 
            "--expectations=$test_dir/exp.xml " .
            "--cmp_rules=$test_dir/cmp_rules.xml $act_dir/after " .
            "--log_file=$act_dir/diff_msg.log > $act_dir/eadiffs.xml" );

    if( test_support::compare_logs( "$test_dir/actual/diff_msg.log",
                                    "$test_dir/expected/diff_msg.log" ) and 
        test_support::compare_dirs( $exp_dir, $act_dir, [ "diff_msg.log" ]) )
    {
        return 1;
    }else{   
        return 0;
    }
}    

sub test_std_creation_bef_aft_chk_1
{
    my $test_dir = "t/DiffRpt/t5";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";

    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    mkdir( "$act_dir/before" ) or 
        die "Cannot create directoty $act_dir/before: $!";
    mkdir( "$act_dir/after" ) or 
        die "Cannot create directoty $act_dir/after: $!";

    system( "lks.pl --keys=$test_dir/keys.txt " . 
                   "$test_dir/selects.txt " .
                   ">$act_dir/sel_subs.txt" );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_bef.txt " . 
                   "--path=$act_dir/before --chunk_size=2 " .
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdmp.pl --conn_file=$test_dir/conn_file_aft.txt " . 
                   "--path=$act_dir/after --chunk_size=2 " .
                   "$act_dir/sel_subs.txt " );
    system( "lcsvdiff.pl --all --keys_file=$test_dir/rkeys.txt " .
            "--chunk_size=2 $act_dir/before $act_dir/after > " .
            "$act_dir/diffs.txt" );
    system( "lrptxml.pl --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/before " .
            " > $act_dir/report_bef.xml" );
    system( "lrptxml.pl --diffs --selects=$act_dir/sel_subs.txt " . 
            "--keys_file=$test_dir/rkeys.txt $act_dir/diffs.txt " .
            " > $act_dir/report_aft.xml" );
 
    return test_support::compare_dirs( $exp_dir, $act_dir );

}    


sub test_bef_aft_key
{
    my $test_dir = "t/DiffRpt/t6";
    my $inp_dir = "t/DiffRpt/t6/input";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    
    local @ARGV = ( '--all', 
                    '--key=2,1', 
                    '--key=4n8',
                    "$inp_dir/before.txt",
                    "$inp_dir/after.txt" );
    
    test_support::redirect_stdout( "$act_dir/diffs.txt" );
    diff( @ARGV );
    test_support::restore_stdout( "$act_dir/diffs.txt" );
    $LRpt::RKeysRdr::rkeys_data = "";
    $LRpt::Config::settings = "";

    return test_support::compare_dirs( $exp_dir, $act_dir );

}    

sub test_bef_aft_key_cols
{
    my $test_dir = "t/DiffRpt/t7";
    my $inp_dir = "t/DiffRpt/t7/input";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    
    local @ARGV = ( '--all', 
                    '--key_cols=Text2,Text1', 
                    '--key_cols=Numeric4:8',
                    "$inp_dir/before.txt",
                    "$inp_dir/after.txt" );
    
    test_support::redirect_stdout( "$act_dir/diffs.txt" );
    diff( @ARGV );
    test_support::restore_stdout( "$act_dir/diffs.txt" );

    $LRpt::RKeysRdr::rkeys_data = "";
    $LRpt::Config::settings = "";
    return test_support::compare_dirs( $exp_dir, $act_dir );

}    

sub test_bef_aft_global_keys 
{
    my $test_dir = "t/DiffRpt/t8";
    my $inp_dir = "t/DiffRpt/t8/input";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    $ENV{ 'LRPT_GLOBAL_KEYS_FILE' } = "$test_dir/key_path/keys.txt";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    
    local @ARGV = ( '--all',  '--global_keys', 
                    "$inp_dir/before",
                    "$inp_dir/after" );
    
    test_support::redirect_stdout( "$act_dir/diffs.txt" );
    diff( @ARGV );
    test_support::restore_stdout( "$act_dir/diffs.txt" );

    $LRpt::RKeysRdr::rkeys_data = "";
    $LRpt::Config::settings = "";
    delete $ENV{ 'LRPT_GLOBAL_KEYS_FILE' };
    return test_support::compare_dirs( $exp_dir, $act_dir );

}    

sub test_bef_aft_skip_cols 
{
    my $test_dir = "t/DiffRpt/t9";
    my $inp_dir = "t/DiffRpt/t9/input";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    
    local @ARGV = ( '--key_cols=Text2,Text1', 
                    '--key_cols=Numeric4:8',
                    '--skip_cols=Text3,Numeric5',
                    "$inp_dir/before",
                    "$inp_dir/after" );
    
    test_support::redirect_stdout( "$act_dir/diffs.txt" );
    diff( @ARGV );
    test_support::restore_stdout( "$act_dir/diffs.txt" );

    $LRpt::RKeysRdr::rkeys_data = "";
    $LRpt::Config::settings = "";
    return test_support::compare_dirs( $exp_dir, $act_dir );

}    

sub test_bef_aft_skip_cols_file 
{
    my $test_dir = "t/DiffRpt/t10";
    my $inp_dir = "t/DiffRpt/t10/input";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    
    local @ARGV = ( '--key_cols=Text2,Text1', 
                    '--key_cols=Numeric4:8',
                    "--skip_cols_file=$test_dir/skip_file.txt",
                    "$inp_dir/before",
                    "$inp_dir/after" );
    
    test_support::redirect_stdout( "$act_dir/diffs.txt" );
    diff( @ARGV );
    test_support::restore_stdout( "$act_dir/diffs.txt" );

    $LRpt::RKeysRdr::rkeys_data = "";
    $LRpt::Config::settings = "";
    $LRpt::CSVDiff::rkeys_rdr = "";
    %LRpt::CSVDiff::skip_cols = ();
    $LRpt::CSVDiff::print_all = "";

    return test_support::compare_dirs( $exp_dir, $act_dir );
}    

sub test_bef_aft_schema_diff 
{
    my $test_dir = "t/DiffRpt/t11";
    my $inp_dir = "t/DiffRpt/t11/input";
    my $act_dir  = $test_dir . "/actual";
    my $exp_dir  = $test_dir . "/expected";
    
    if( -d $act_dir ){
        rmtree( $act_dir ) or die "Cannot delete directory $act_dir: $!"; 
    }
    mkdir( $act_dir ) or die "Cannot create directoty $act_dir: $!";
    
    local @ARGV = ( '--key_cols=Text2,Text1', 
                    '--key_cols=Numeric4:8',
                    "$inp_dir/before",
                    "$inp_dir/after" );
    
    test_support::redirect_stdout( "$act_dir/diffs.txt" );
    diff( @ARGV );
    test_support::restore_stdout( "$act_dir/diffs.txt" );

    $LRpt::RKeysRdr::rkeys_data = "";
    $LRpt::Config::settings = "";
    return test_support::compare_dirs( $exp_dir, $act_dir );
}    

