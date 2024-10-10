#!/user/bin/perl

# Program:  19-open_close.t
#    Tests out the "autoopen" feature that does an open/write/close for each
#    DBUG call.  Also tests adding the PID-thread id to each line of the log.

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

my $start_level;

sub my_warn
{
   ok3 (0, "There were no unexpected warnings!");
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {      # Test # 2
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

   my $sts = get_fish_state ();   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( $sts == 1 ) ? 1 : 0;

   # Open/Close fish logs between calls to DBUG.  Also Print PID to fish.
   DBUG_PUSH ( get_fish_log(), off => $off, autoopen => 1, multi => 1 );

   my $lvl = ( $sts == -1 ) ? -1 : 1;

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   is2 ($start_level, $lvl, "In the BEGIN block ...");   # Test # 3

   ok3 ( dbug_active_ok_test () );

   DBUG_VOID_RETURN ();
}

END {
   DBUG_ENTER_FUNC (@_);

   # Can no longer call ok3() in an END block unless it fails!

   my $end_level = test_fish_level ();
   if ( $start_level != $end_level ) {
      ok3 (0, "In the END block ... ($start_level vs $end_level)");
   }

   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   ok3 (1, "In the MAIN program ...");  # Test # 5 ...

   # -----------------------------------
   # Tests # 6 to 9 ...
   # -----------------------------------
   my $msg = "Hello World!\n";
   my $ans = DBUG_PRINT ("INFO", "%s", $msg);
   is2 ($ans, $msg, "The print statement returned the formatted string!");

   ok3 ( chdir ("t"), "Entered the test directory \"t\".");
   DBUG_PRINT ("INFO", "%s", "Good Bye!");

   ok3 (1, "Fish File: " . DBUG_FILE_NAME ());

   is2 (test_fish_level(), $start_level, "Level Check");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------

