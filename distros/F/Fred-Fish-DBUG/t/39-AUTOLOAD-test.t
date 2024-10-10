#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  39-AUTOLOAD-test.t
# ------------------------------------------------------------------
# Tests how DBUG works with the special AUTOLOAD function.
# Since it easily demonstrates fish's issues with "goto" statements.
# ------------------------------------------------------------------
# The AUTOLOAD function is so complex since you're only allowed one
# of them per file & I needed 3 different ways to reference it.  I
# could have made it simpler, but then I'd need a minimum of 3
# additional test scripts.  Which would then hide what I'm trying
# to test out!
# ------------------------------------------------------------------
# The moral of this test is to not use "goto" statments in your code!
# ------------------------------------------------------------------

my $start_level;

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

   DBUG_PUSH ( get_fish_log(), off => $off, who_called => 0, strip => 0 );

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   my $a = ok2 (1, "In the BEGIN block ...");
   ok2 (ok2 ($a, "First Return value check worked!"),
                 "Second Return value check worked!");

   my $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "Begin Block Level Check");

   ok2 ( dbug_active_ok_test () );

   ok2 ( 1, "Fish Log: " . DBUG_FILE_NAME () );

   DBUG_VOID_RETURN ();
}

END {
   DBUG_ENTER_FUNC (@_);

   # Can only do failed tests in the END func.
   my $end_level = test_fish_level ();
   if ( $start_level != $end_level) {
      ok2 (0, "In the END block ...");
   }

   DBUG_VOID_RETURN ();
}

my $auto_mode = 0;

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   ok2 (1, "In the MAIN block ...");

   my $lvl = test_fish_level ();

   run_tests ();
   my $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after 1st test run!");

   DBUG_PRINT ("-----", "------------------------------------");
   $auto_mode = 1;
   run_tests ();
   $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after 2nd test run!");

   DBUG_PRINT ("-----", "------------------------------------");
   $auto_mode = -1;
   run_tests ();
   $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after 3rd test run!");

   DBUG_PRINT ("-----", "------------------------------------");
   $auto_mode = 0;
   run_other_tests (1, "Calls AUTOLOAD");
   DBUG_PRINT ("-----", "------------------------------------");
   run_other_tests (0, "Never Calls AUTOLOAD");

   $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after 4th test run!");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# Tests what happens with the special AUTOLOAD function
# trapping undefined function calls.  And how "goto"
# calls cause problems with your fish traces.
# -----------------------------------------------
# Has 3 modes via $auto_mode:
#  -1 : Don't use DBUG_ENTER... & DBUG_RETURN.
#   0 : Use DBUG_ENTER_FUNC & DBUG_RETURN.
#   1 : Use DBUG_ENTER_BLOCK & DBUG_RETURN.
# -----------------------------------------------

AUTOLOAD
{
   our $AUTOLOAD;    # Reference special global variable.

   if ( $auto_mode ) {
      DBUG_ENTER_BLOCK ($AUTOLOAD, @_)  if ( $auto_mode >= 0 );

   } else {
      DBUG_ENTER_FUNC (@_);   # Auto adds "aka $AUTOLOAD" to fish func name!
      # DBUG_PRINT ("INFO", "Undefined function %s().", $AUTOLOAD);
   }

   # Uncomment if you'd like to see infinite recursion!
   # Since your program's symbol table wasn't updated to include it.
   # autoload_recursion ();    # No such function ...

   autoload_stuff ();

   # To demonstrate how "goto" uses @_ ...
   my $save = shift;

   # For these functions, put into the symbol table so we never
   # call AUTOLOAD for them again!
   if ( $AUTOLOAD eq "main::help" ||
        $AUTOLOAD eq "main::helper" ||
        $AUTOLOAD eq "main::helpless" ) {
      no strict;     # So we can update the symbol table.

      # Assumes forget_me_not() uses DBUG_RETURN(), not DBUG_RETURN_SPECIAL()!
      # See t/16-return_special_scalar_join.t for reason why!
      *{$AUTOLOAD} = \&forget_me_not;   # Put into this program's symbol table.

      # Demonstrates an alternative to using the GOTO mess below ...
      # Fish remains easily balanced this way.
      # The cost being the overhead for an extra return the 1st time called!
      if ( $AUTOLOAD eq "main::helpless" ) {
         return DBUG_RETURN ( $AUTOLOAD->(@_) );
      }

      # So fish remains balanced.  I can't get it to happen after the goto
      # in too many instances.  Makes for ugly but balanced fish logs.
      DBUG_VOID_RETURN()  if ( $auto_mode >= 0 );

      # Jump to this function!  It inherits the current @_ variable contents.
      goto &$AUTOLOAD;

      # Ynu never get here!  It's as if AUTOLOAD was never called!
      # Proved by caller() results in forget_me_not!
   }

   my @res = qw /a b c d e f g/;
   if ( $auto_mode >= 0 ) {
      return DBUG_RETURN ( @res );
   } else {
      return (wantarray ? @res : $res[0]);
   }
}

# -----------------------------------------------
# Caller doesn't know the undefined function name being redirected to this one!
# Using DBUG_RETURN() since DBUG_RETURN_SPECIAL() requires more complex logic
# in the AUTOLOAD function ...
# See t/16-return_special_scalar_join.t, t/17-return_special_array_reference.t
# or t/18-return_special_scalar_count.t for some reasons why!
sub forget_me_not
{
   DBUG_ENTER_FUNC (@_);
   my $c1 = (caller(1))[3];
   my $c2 = (caller(0))[3];
   ok2 (1, "We got help!  <====>  Caller: $c1 -> $c2");
   DBUG_RETURN ( qw /1 2 3 4 5 6 7/ );
}

# Just a stub called by AUTOLOAD ...
sub autoload_stuff
{
   DBUG_ENTER_FUNC (@_);
   DBUG_VOID_RETURN ();
}

# -----------------------------------------------
# Only 1st time called does it call AUTOLOAD.
# Afterwards it calls forget_me_not() instead!
# -----------------------------------------------
sub run_other_tests
{
   DBUG_ENTER_FUNC (@_);
   my $print = shift;

   my $lvl = test_fish_level ();

   my @h = help (qw/Did help call forget_me_not? /);
   my $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after trapping undefined function 'help'." );
   DBUG_PRINT ("????", "?????????????????????????????")  if ( $print );

   my $a = helpless ("one", "two");
   $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after trapping undefined function 'helpless'." );
   DBUG_PRINT ("????", "?????????????????????????????")  if ( $print );

   helper ("Says", "He, He!");
   $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after trapping undefined function 'helper'." );

   DBUG_VOID_RETURN;
}

# -----------------------------------------------
# Always calls AUTOLOAD each time called!
# -----------------------------------------------
sub run_tests
{
   DBUG_ENTER_FUNC (@_);

   my $lvl = test_fish_level ();
   my ($a, $b, $c, $lvl2);

   # -------------------------------------------------------
   # From here on down we always call AUTOLOAD!
   # -------------------------------------------------------
   junk_yard_dog (qw / One fine day in May! /);
   $lvl2 = test_fish_level ();
   is2 ( $lvl2, $lvl, "At correct level after trapping undefined function." );

   $a = hocus_pocus (qw / Where's that black cat? /);
   $lvl2 = test_fish_level ();
   is2 ( $a, "a", "hocus_pocus correctly returned it's value.");
   is2 ( $lvl2, $lvl, "At correct level after trapping undefined function." );

   ($a, $b) = two_fish (qw / One fish two fish. /);
   $lvl2 = test_fish_level ();
   ok2 ( $a eq "a" && $b eq "b", "two_fish correctly returned ($a, $b).");
   is2 ( $lvl2, $lvl, "At correct level after trapping undefined function." );

   my @l = many_many_fishes (qw / Who knows what's next? /);
   $lvl2 = test_fish_level ();
   my $cnt = @l;
   ok2 ( $cnt == 7, "many_many_fishes correctly returned $cnt value(s)!");
   my $res = join (",", @l);
   is2 ( $res, "a,b,c,d,e,f,g", "many_many_fishes returned all the correct value(s)!");
   is2 ( $lvl2, $lvl, "At correct level after trapping undefined function." );

   DBUG_VOID_RETURN ();
}

