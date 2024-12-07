#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:: 27-return_misc.t
# ------------------------------------------------------------------
# This test script demonstrates how DBUG_RETURN() works when you
# use it in some unusal context.
# ------------------------------------------------------------------

my $compile_warn;

sub ignore_compile_warnings
{
   chomp (my $msg = shift);
   dbug_ok (1, "__WARN___: " . $msg);
   ++$compile_warn;
}

sub my_warn
{
   dbug_ok (0, "There was an expected warning!");
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {     # Test # 2
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::Dbug qw / " .
             join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Used options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }
}

BEGIN {
   $compile_warn = 0;

   # So can detect if the module generates any warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off );

   DBUG_ENTER_FUNC ();

   my $a = dbug_ok (1, "In the BEGIN block ...");

   dbug_ok ( dbug_active_ok_test () );

   dbug_ok (1, "Fish File: " . DBUG_FILE_NAME ());

   # Done to trap the compile time warnings so they
   # are not treated as failed test cases.
   # The warnings are caused by the 1st few calls to return_test()!
   # And are thrown before the call to DBUG_TRAP_SIGNAL()!
   $SIG{__WARN__} = \&ignore_compile_warnings;

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
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   DBUG_ENTER_FUNC (@ARGV);

   my $lvl1 = test_fish_level ();

   dbug_is ($compile_warn, 2, "There were only 2 compiler warnings!");

   # --------------------------------------------------------------
   DBUG_PRINT ("----", "%s", "-"x50);
   DBUG_PRINT ("----", "The DBUG_RETURN Void Tests ...");
   # --------------------------------------------------------------
   return_test ();
   dbug_ok (1, "Ignoring the return values");

   # This generates compile time warnings if not disabled ...
   (return_test ())[0];
   dbug_ok (1, "Ignoring the return values");

   # This generates compile time warnings if not disabled ...
   (return_test ())[0,2,4];
   dbug_ok (1, "Ignoring the return values");

   # --------------------------------------------------------------
   DBUG_PRINT ("----", "%s", "-"x50);
   DBUG_PRINT ("----", "The DBUG_RETURN Reverse Tests ...");
   # --------------------------------------------------------------

   my @reverse = qw / g f e d c b a /;
   my $rev = join (", ", @reverse);

   my @lst = reverse return_test ();
   my $res = join (", ", @lst);
   dbug_is ($rev, $res, "The list reversed OK.  $res");

   # --------------------------------------------------------------
   DBUG_PRINT ("----", "%s", "-"x50);
   DBUG_PRINT ("----", "The DBUG_RETURN Index Tests ...");
   # --------------------------------------------------------------
   my $cnt;

   @lst = (return_test ())[1,3,5];
   $cnt = @lst;
   $res = join (", ", @lst);
   dbug_is ($cnt, 3, "List contains 3 entries in it.");
   dbug_ok ($lst[0] eq "b" && $lst[1] eq "d" && $lst[2] eq "f",
                   "All 3 values were correct!  $res");

   DBUG_PRINT ("----", "%s", "-"x50);

   @lst = (return_test ())[-1];
   $cnt = @lst;
   $res = join (", ", @lst);
   dbug_is ($cnt, 1, "List contains 1 entries in it.");
   dbug_is ($lst[0], "g", "It held the correct last value.  $res");

   DBUG_PRINT ("----", "%s", "-"x50);

   @lst = (return_test ())[-2,1];
   $cnt = @lst;
   $res = join (", ", @lst);
   dbug_is ($cnt, 2, "List contains 2 entries in it.");
   dbug_ok ($lst[0] eq "f" && $lst[1] eq "b",
                   "It held the correct values.  $res");

   DBUG_PRINT ("----", "%s", "-"x50);

   my $lvl2 = test_fish_level ();
   dbug_is ( $lvl2, $lvl1, "Fish Levels are good!" );

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# The return value test function ...
# -----------------------------------------------
# Normal Usage ...

sub return_test
{
   DBUG_ENTER_FUNC (@_);
   my @ret = qw / a b c d e f g /;
   DBUG_RETURN (@ret);
}

