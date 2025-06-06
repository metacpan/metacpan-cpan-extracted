#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  21-return_simple.t
# ------------------------------------------------------------------
# This test script demonstrates how DBUG_RETURN() works when you
# use it in various contexts.  Always passes tests.  You need to
# manually review the fish files to verify if everything worked
# as expected.
# See:
#   Normal Usage     :  return_test_1()
#   Virtual Usage 1  :  return_test_2() - Early reporting
#   Virtual Usage 2  :  return_test_3() - Conditional in sub-block
#   Old Work Arround :  return_test_4() - For when Virtual Usage was broken.
#   Masking Test     :  return_test_mask()
# ------------------------------------------------------------------
# Uses standard return mode.
# ------------------------------------------------------------------

# The return values for all return_test_*() functions ...
my @ret_val = qw / a b c /;

my $fish_module;

sub my_warn
{
   dbug_ok (0, "There were no unexpected warnings!");
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {     # Test # 2
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
                      join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Used options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }
}

BEGIN {
   # So can detect if the module generates any warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off );

   DBUG_ENTER_FUNC ();

   my $a = dbug_ok (1, "In the BEGIN block ...");

   dbug_ok ( dbug_active_ok_test () );

   DBUG_VOID_RETURN ();
}

END {
   DBUG_ENTER_FUNC (@_);
   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   my $lvl1 = test_fish_level ();

   test_wrapper ( \&return_test_1,    "The basic DBUG_RETURN Tests" );
   test_wrapper ( \&return_test_2,    "The automatic indirect DBUG_RETURN Tests" );
   test_wrapper ( \&return_test_3,    "The conditional indirect DBUG_RETURN Tests" );
   test_wrapper ( \&return_test_4,    "The old indirect DBUG_RETURN Work Arround Tests" );
   test_wrapper ( \&return_test_mask, "What each section does masking the 1st value" );

   DBUG_PRINT ("----", "-"x50);
   dbug_ok (1, "Manually check the fish logs to verify that everything is OK!\n----  " . DBUG_FILE_NAME ());

   my $lvl2 = test_fish_level ();
   dbug_is ( $lvl2, $lvl1, "Fish Levels are good!" );

   dbug_ok (1, "Done!");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# ---------------------------------------------------
# Controls how many times each test func is called.
# ---------------------------------------------------
sub test_wrapper
{
   DBUG_PRINT ("----", "-"x50);
   DBUG_ENTER_FUNC (@_);
   my $func = shift;
   my $msg  = shift;

   $func->();
   dbug_ok (1, "Ignoring the return values");

   my $a = $func->();
   dbug_is ($a, "a", "*** Keeping just the 1st value ($a) ***");

   my ($m, $n) = $func->();
   dbug_ok ($m eq "a" && $n eq "b", "Keeping 2 of 3 values ($m, $n)");

   my ($x, $y, $z) = $func->();
   dbug_ok ($x eq "a" && $y eq "b" && $z eq "c", "Keeping all 3 values ($x, $y, $z)");

   DBUG_VOID_RETURN ();
}

# ------------------------------------------------------------
# The return value test functions ...
# ------------------------------------------------------------
# All test functions are called 4 times!
# Expecting a different number of return values each time!
# ------------------------------------------------------------

# Normal Usage ...
sub return_test_1
{
   DBUG_ENTER_FUNC (@_);
   DBUG_RETURN (@ret_val);
}

# Virtual usage # 1.
# A case where you'd try this is if you'd like to make the call to
# DBUG_RETURN & DBUG_ENTER_FUNC early before all work is done.
sub return_test_2
{
   DBUG_ENTER_FUNC (@_);

   # Test to prove waantarray works aas epectected.
   unless (defined wantarray) {
      dbug_ok (1, "wantarray is <udef>");
   } elsif (wantarray == 0)  {
      dbug_ok (1, "wantarray is 0 (scalar)");
   } elsif (wantarray == 1)  {
      dbug_ok (1, "wantarray is 1 (array)");
   } else {
      dbug_ok (0, "ERROR: wantarray is " . wantarray);
   }

   # Prints to fish the expected return values, but doesn't actually return
   # anything since used in a void context.
   DBUG_RETURN (@ret_val);

   # Do some more work here ...

   # This is what DBUG_RETURN() does ... by default.
   return ( wantarray ? @ret_val : $ret_val[0] );
}

# Virtual usage # 2.
# A case where you'd try this is if you'd like to make the call to
# DBUG_RETURN & DBUG_ENTER_FUNC conditional.
sub return_test_3
{
   DBUG_ENTER_FUNC (@_);

   # Being inside a sub-block shouldn't change things ...
   if ( 1 == 1 ) {
      DBUG_RETURN (@ret_val);
   }

   # Do some more work here ...

   # This is what DBUG_RETURN() does ... by default.
   return ( wantarray ? @ret_val : $ret_val[0] );
}

# Old style work arround from when "return_test_2()" didn't work as expected!
sub return_test_4
{
   DBUG_ENTER_FUNC (@_);

   if ( ! defined wantarray ) {
      DBUG_RETURN (@ret_val);
   } elsif ( wantarray ) {
      my @a = DBUG_RETURN (@ret_val);
   } else {
      my $s = DBUG_RETURN (@ret_val);
   }

   # This is what DBUG_RETURN() does ... by default.
   return ( wantarray ? @ret_val : $ret_val[0] );
}

# Normal Usage ...
sub return_test_mask
{
   DBUG_ENTER_FUNC (@_);
   DBUG_MASK (0);
   DBUG_RETURN (@ret_val);
}

