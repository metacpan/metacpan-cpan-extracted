#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  22-return_special_scalar_join.t
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
# Uses return special, returns a scalar value in scalar mode!
# ------------------------------------------------------------------

# The return values for all return_test_*() functions ...
my @ret_val = qw / a b c /;

# Tells if the anonymous function was called!
my $global_flag = 0;

# Shows up as "main::__ANON__" in the fish logs when caled!
my $ret_scalar_func = sub { DBUG_ENTER_FUNC(@_); $global_flag = 1; my $l = join (" ", @_); DBUG_RETURN($l); };


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

   test_wrapper ( \&return_test_1,    1, "The basic DBUG_RETURN_SPECIAL Tests" );
   test_wrapper ( \&return_test_2,    1, "The automatic indirect DBUG_RETURN_SPECIAL Tests" );
   test_wrapper ( \&return_test_4,    0, "The old indirect DBUG_RETURN_SPECIAL Work Arround Tests" );
   test_wrapper ( \&return_test_mask, 1, "What each section does masking the 1st value" );

   # These tests not needed in other specal return test progs!
   test_wrapper ( \&deep_test_1,      2, "Recursive use of DBUG_RETURN_SPECIAL test 1.");
   test_wrapper ( \&deep_test_2,      1, "Recursive use of DBUG_RETURN_SPECIAL test 2.");

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
   my $func    = shift;
   my $chk_flg = shift;
   my $msg     = shift;

   $func->();
   dbug_ok (1, "Ignoring the return values");
   dbug_is ($global_flag, 0, "Global flag not set as expected.")  if ( $chk_flg );

   my $a = $func->();
   if ( $chk_flg == 2 ) {
      dbug_is ($a, "a", "*** Scalar result is NOT a join.  ($a) ***");
      dbug_is ($global_flag, 0, "Global flag was not set as expected.");
   } else {
      dbug_is ($a, "a b c", "*** Scalar result is a join.  ($a) ***");
      dbug_is ($global_flag, 1, "Global flag set as expected.")  if ( $chk_flg );
   }

   my ($m, $n) = $func->();
   dbug_ok ($m eq "a" && $n eq "b", "Keeping 2 of 3 values ($m, $n)");
   dbug_is ($global_flag, 0, "Global flag was not set as expected.")  if ( $chk_flg );

   my ($x, $y, $z) = $func->();
   dbug_ok ($x eq "a" && $y eq "b" && $z eq "c", "Keeping all 3 values ($x, $y, $z)");
   dbug_is ($global_flag, 0, "Global flag was not set as expected.")  if ( $chk_flg );

   DBUG_VOID_RETURN ();
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
   $global_flag = 0;
   DBUG_RETURN_SPECIAL ($ret_scalar_func, @ret_val);
}

# Virtual usage.
# A case where you'd try this is if you'd like to make the call to
# DBUG_RETURN_SPECIAL & DBUG_ENTER_FUNC conditional or don't actually want to
# do a return at that point in your code.
sub return_test_2
{
   DBUG_ENTER_FUNC (@_);

   $global_flag = 0;

   # Prints to fish the expected return values, but doesn't actually return
   # anything since used in a void context.
   DBUG_RETURN_SPECIAL ($ret_scalar_func, @ret_val);

   dbug_is ( $global_flag, 0, "Anonymous function in return_test_2 was handled correctly!" );

   # Do some more work here ...

   $global_flag = 0;

   # This is what DBUG_RETURN_SPECIAL() does ... in this case ...
   # It's why you don't want to do things this way ...
   # I had to know that $ret_scalar_func was a CODE reference!!!
   return ( (! defined wantarray) ? undef : ( wantarray ? @ret_val : $ret_scalar_func->(@ret_val) ) );
}

# Old style work arround from when "return_test_2()" didn't work as expected!
sub return_test_4
{
   DBUG_ENTER_FUNC (@_);

   $global_flag = 0;

   my ($scalar, @lst);
   my $err_flag = 0;

   if ( ! defined wantarray ) {
      # Same as:  DBUG_VOID_RETURN() ...
      DBUG_RETURN_SPECIAL ($ret_scalar_func, @ret_val);
      $err_flag = $global_flag;
   } elsif ( wantarray ) {
      # Same as:  @a = DBUG_RETURN(@ret_val) ...
      @lst = DBUG_RETURN_SPECIAL ($ret_scalar_func, @ret_val);
      $err_flag = $global_flag;
   } else {
      # Same as:  $scalar = $ret_scalar_func->(@ret_val) ... in this case.
      $scalar = DBUG_RETURN_SPECIAL ($ret_scalar_func, @ret_val);
      $err_flag = $global_flag ? 0 : 1;
   }

   dbug_ok ( ! $err_flag, "Anonymous function in return_test_4 was handled correctly!" );

   # This is what DBUG_RETURN_SPECIAL() does ... in this case ...
   return ( wantarray ? @lst : $scalar );
}

# Normal Usage ... with masking
sub return_test_mask
{
   DBUG_ENTER_FUNC (@_);
   DBUG_MASK (0);
   $global_flag = 0;
   DBUG_RETURN_SPECIAL ($ret_scalar_func, @ret_val);
}

# ---------------------------------------------------
# This example works correctly, but not as your intuition might have told you.
# This is because the call to return_test_1() returns its values as the
# arguments to function DBUG_RETURN(), which tells return_test_1() to always
# return the array!  It doesn't know when DBUG_RETURN() will return a scalar
# or void!
#
# Here's what to expect this recursive function to return ...
#   $ret = deep_test_1 () ...  returns "a" ... not "a b c".
#   @ret = deep_test_1 () ...  returns the full array as expected.
#   deep_test_1 () ... returns undef, but not for the reason you might expect.
# ---------------------------------------------------
sub deep_test_1
{
   DBUG_ENTER_FUNC (@_);
   my $deep = shift;
   $deep = 5   unless ( defined $deep );

   if ( $deep <= 0 ) {
      # Calling return_test_1() this way always returns an array, not a scalar!
      return DBUG_RETURN ( return_test_1 () );
   } else {
      return DBUG_RETURN ( deep_test_1 ( --$deep ) );
   }
}


# ---------------------------------------------------
# This example implements how your intuition might have told you the above
# function should work.  But your intuition would be wrong!
#
# Here's what to expect this recursive function to return ...
#   $ret = deep_test_2 () ...  returns "a b c".
#   @ret = deep_test_2 () ...  returns the full array as expected.
#   deep_test_2 ()        ...  returns undef.
# ---------------------------------------------------
sub deep_test_2
{
   DBUG_ENTER_FUNC (@_);
   my $deep = shift;
   $deep = 5   unless ( defined $deep );

   # Returning an array ... "a", "b", "c"
   if ( wantarray ) {
      if ( $deep <= 0 ) {
         return DBUG_RETURN ( return_test_1 () );
      } else {
         return DBUG_RETURN ( deep_test_2 ( --$deep ) );
      }

   # Returning a scalar ... "a b c"
   } elsif ( defined wantarray ) {
      if ( $deep <= 0 ) {
         return DBUG_RETURN ( scalar (return_test_1 ()) );
      } else {
         return DBUG_RETURN ( scalar (deep_test_2 ( --$deep )) );
      }

   # Returns nothing ... undef
   } else {
      if ( $deep <= 0 ) {
         return_test_1 ();
      } else {
         deep_test_2 ( --$deep );
      }
      return DBUG_VOID_RETURN ( );
   }
}

