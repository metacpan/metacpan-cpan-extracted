#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  24-return_special_scalar_count.t
# ------------------------------------------------------------------
# This test script demonstrates how DBUG_RETURN_SPECIAL() works when you
# use it in various contexts.  Always passes tests.  You need to
# manually review the fish files to verify if everything worked
# as expected.
# See:
#   Normal Usage     :  return_test_1()
#   Virtual Usage    :  return_test_2()
#   Old Work Arround :  return_test_4() - For when Virtual Usage was broken.
#   Masking Test     :  return_test_mask()
# ------------------------------------------------------------------
# Uses return special, returns array reference in scalar mode.
# ------------------------------------------------------------------

# The return values for all return_test_*() functions ...
my @ret_val = qw / a b c /;

sub my_warn
{
   ok2 (0, "There were no unexpected warnings!");
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {     # Test # 2
      bail ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
             join (" ", @opts) . " /" );
   }

   ok (1, "Used options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
      exit (0);
  }
}

BEGIN {
   # So can detect if the module generates any warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off );

   DBUG_ENTER_FUNC ();

   my $a = ok2 (1, "In the BEGIN block ...");

   ok2 ( dbug_active_ok_test () );

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

   test_wrapper ( \&return_test_1,    "The basic DBUG_RETURN_SPECIAL Tests" );
   test_wrapper ( \&return_test_2,    "The automatic indirect DBUG_RETURN_SPECIAL Tests" );
   test_wrapper ( \&return_test_4,    "The old indirect DBUG_RETURN_SPECIAL Work Arround Tests" );
   test_wrapper ( \&return_test_mask, "What each section does masking the 1st value" );

   DBUG_PRINT ("----", "-"x50);
   my $no = no_dbug ();
   ok2 ( $no eq 3, "Returned the count of return values: ${no} (ans: 3)" );
   my ($m, $n) = no_dbug();
   ok2 ($m eq "a" && $n eq "b", "Keeping 2 of 3 values ($m, $n)");

   DBUG_PRINT ("----", "-"x50);

   ok2 (1, "Manually check the fish logs to verify that everything is OK!\n----  " . DBUG_FILE_NAME ());

   my $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl1, "Fish Levels are good!" );

   ok2 (1, "Done!");

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
   ok2 (1, "Ignoring the return values");

   my $cnt = $func->();
   ok2 ( $cnt == 3, "Returned the correct count of array members ${cnt} (of 3)" );

   my ($m, $n) = $func->();
   ok2 ($m eq "a" && $n eq "b", "Keeping 2 of 3 values ($m, $n)");

   my ($x, $y, $z) = $func->();
   ok2 ($x eq "a" && $y eq "b" && $z eq "c", "Keeping all 3 values ($x, $y, $z)");

   DBUG_VOID_RETURN ();
}

# ------------------------------------------------------------
# Demonstrates what happens when you don't use fish.
# ------------------------------------------------------------
sub no_dbug
{
   return ( @ret_val );
}

# ------------------------------------------------------------
# The return value test functions ...
# ------------------------------------------------------------
# All test functions are called 4 times!
# Expecting a different number of return values each time!
# ------------------------------------------------------------

# Normal Usage ... without masking
sub return_test_1
{
   DBUG_ENTER_FUNC (@_);
   DBUG_RETURN_SPECIAL (DBUG_SPECIAL_COUNT, @ret_val);
}

# Virtual usage.
# A case where you'd try this is if you'd like to make the call to
# DBUG_RETURN & DBUG_ENTER_FUNC conditional or don't actually want to
# do a return at that point in your code.
sub return_test_2
{
   DBUG_ENTER_FUNC (@_);

   # Prints to fish the expected return values, but doesn't actually return
   # anything since used in a void context.
   DBUG_RETURN_SPECIAL (DBUG_SPECIAL_COUNT, @ret_val);

   # Do some more work here ...

   # This is what DBUG_RETURN_SPECIAL() does ... in this case
   return ( wantarray ? @ret_val : scalar(@ret_val) );
}

# Old style work arround from when "return_test_2()" didn't work as expected!
sub return_test_4
{
   DBUG_ENTER_FUNC (@_);

   my ($ans, @lst);

   if ( ! defined wantarray ) {
      DBUG_RETURN_SPECIAL (DBUG_SPECIAL_COUNT, @ret_val);
   } elsif ( wantarray ) {
      @lst = DBUG_RETURN_SPECIAL (DBUG_SPECIAL_COUNT, @ret_val);
   } else {
      $ans = DBUG_RETURN_SPECIAL (DBUG_SPECIAL_COUNT, @ret_val);
   }

   # This is what DBUG_RETURN_SPECIAL() does ... in this case
   return ( wantarray ? @lst : $ans );
}

# Normal Usage ... with masking
sub return_test_mask
{
   DBUG_ENTER_FUNC (@_);
   DBUG_MASK (0);
   DBUG_RETURN_SPECIAL (DBUG_SPECIAL_COUNT, @ret_val);
}

