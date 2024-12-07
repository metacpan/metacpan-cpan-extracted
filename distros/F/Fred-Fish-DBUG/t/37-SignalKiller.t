#!/user/bin/perl

# Program:  37-SignalKiller.t
# NOTE: Uses t/off/helper1234.pm to deterrmine which DBUG module to use.
#       It uses $ENV{FISH_OFF_FLAG} to do this logic & other common inits!
#       This test doesn't do the same tests as the other t/00-*.t progs do.

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

my $start_level;

sub my_warn
{
   dbug_BAIL_OUT ( "An Unexpected Warning was trapped!" );
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {              # Test # 2
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
                      join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Used options qw / " . join (" ", @opts) . " /");   # Test # 3

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {           # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
   }

   unless (use_ok ("Fred::Fish::DBUG::SignalKiller")) {       # Test # 5
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::SignalKiller" );
   }
}

BEGIN {
   # Overrides the default trap for warnings ...
   # So can treat warnings as errors!
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   my $sts = get_fish_state ();   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( $sts != 0 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off );

   my $lvl = ( $sts == -1 ) ? -1 : 1;

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   dbug_is ($start_level, $lvl, "In the BEGIN block ...");   # Test # 5

   dbug_ok ( dbug_active_ok_test () );                    # Test # 6

   my $f = DBUG_FILE_NAME ();                         # Test # 7
   dbug_ok (1, "Fish File: $f");

   DBUG_VOID_RETURN ();
}

my $try_tiny_flag;

BEGIN {
   DBUG_ENTER_FUNC (@_);

   $try_tiny_flag = 0;

   # Ignore the fancy overrides for the DIE signal ...
   local $SIG{__DIE__} = "DEFAULT";

   eval {
      require Try::Tiny;
      Try::Tiny->import ();

      dbug_ok (1, "Try::Tiny is installed.");
      $try_tiny_flag = 1;
   };

   if ( $@ ) {
      dbug_ok (1, "Try::Tiny isn't installed, so skipping those tests!");
   }

   DBUG_VOID_RETURN ();
}

END {
   DBUG_ENTER_FUNC (@_);

   # Can no longer call ok2() in an END block unless it fails!

   my $end_level = test_fish_level ();
   if ( $start_level != $end_level ) {
      dbug_ok (0, "In the END block ... ($start_level vs $end_level)");
   }

   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 7 ...

   # -----------------------------------
   # A normal die trap ...
   # -----------------------------------
   DBUG_PRINT ("----", "-"x40);
   DBUG_TRAP_SIGNAL ("DIE", DBUG_SIG_ACTION_DIE);
   eval {
      die ("Act 1: Why oh why did we have to die!", "ACTION_DIE", "\n");
      dbug_ok (0, "We should get here!");
   };

   my $worked = 0;
   if ($@) { $worked = 1; }
   dbug_ok ($worked, "EVAL was trapped as expected.");

   # -----------------------------------
   # A non-normal die trap ...
   # -----------------------------------
   DBUG_PRINT ("----", "-"x40);
   DBUG_TRAP_SIGNAL ("DIE", DBUG_SIG_ACTION_LOG);
   eval {
      die ("Act 2: Why oh why didn't we die!", "ACTION_LOG", "\n");
      dbug_ok (1, "We should get here!");
   };
   $worked = 1;
   if ($@) { $worked = 0; }
   dbug_ok ($worked, "2nd EVAL was ignored as expected.");

   # -----------------------------------
   # A back to a normal die trap again!
   # Wihout any logging!
   # -----------------------------------
   {
      DBUG_PRINT ("----", "-"x40);
      local $SIG{__DIE__} = "IGNORE";
      eval {
         die ("Act 3: Why oh why did we have to die!", "IGNORE", "\n");
         dbug_ok (0, "We should get here!");
      };
      $worked = 0;
      if ($@) { $worked = 1; }
      dbug_ok ($worked, "3rd EVAL was trapped as expected.  And the die wasn't logged!");
   }

   # -----------------------------------
   # The 3 try tiny tests ...
   # -----------------------------------
   if ( $try_tiny_flag ) {
      DBUG_PRINT ("----", "="x40);
      DBUG_TRAP_SIGNAL ("DIE", DBUG_SIG_ACTION_DIE);
      try_tiny_test ("<==>ACTION_DIE", 1, "4th");

      DBUG_PRINT ("----", "="x40);
      DBUG_TRAP_SIGNAL ("DIE", DBUG_SIG_ACTION_LOG);
      try_tiny_test ("<==>ACTION_LOG", 0, "5th");

      DBUG_PRINT ("----", "="x40);
      local $SIG{__DIE__} = "IGNORE";
      try_tiny_test ("<==>SKIP-LOGGING", 1, "6th");
   }

   DBUG_PRINT ("----", "-"x40);

   dbug_is (test_fish_level(), $start_level, "Level Check");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------

sub try_tiny_test
{
   DBUG_ENTER_FUNC(@_);
   my $msg        = shift;
   my $catch_call = shift;
   my $tst_num    = shift;

   my $called_catch = 0;
   my $called_finally = 0;
   try {
      DBUG_ENTER_BLOCK ("TRY-TRY-TRY-TRY-TRY-TRY-TRY-TRY-TRY");
      die ("$tst_num: Did we die yet?", $msg, "\n");
      DBUG_VOID_RETURN ();
   } catch {
      DBUG_ENTER_BLOCK ("CATCH-CATCH-CATCH-CATCH-CATCH-CATCH-CATCH-CATCH-CATCH");
      $called_catch = 1;
      DBUG_VOID_RETURN ();
   } finally {
      DBUG_ENTER_BLOCK ("FINALLY-FINALLY-FINALLY-FINALLY-FINALLY-FINALLY-FINALLY-FINALLY-FINALLY");
      $called_finally = 1;
      DBUG_VOID_RETURN ();
   };

   if ( $catch_call ) {
      dbug_ok ( $called_catch, "We caught the $tst_num die request correctly" );
   } else {
      dbug_ok ( ! $called_catch, "We ignored the $tst_num die request correctly" );
   }

   dbug_ok ( $called_finally, "We also called finally!" );

   DBUG_VOID_RETURN ();
}

