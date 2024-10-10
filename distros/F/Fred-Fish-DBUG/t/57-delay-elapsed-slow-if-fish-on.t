#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  57-delay-elapsed-slow-if-fish-on.t
# -----------------------------------------------------------------------
# This script tests out the delay & elapsed option to DBUG_PUSH()!
# Uses color to help with the analysis.
# -----------------------------------------------------------------------

my $delay;          # How long to delay ...
my $start_level;
my $start_time;

sub my_warn
{
   my $msg = shift;
   chomp($msg);
   ok2 (0, "There was an expected warning!  Check fish.");
}

BEGIN {
   eval {
      require Time::HiRes;
      Time::HiRes->import ( qw(time sleep) );
   };

   $start_time = time ();
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
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () != 0 ) ? 1 : 0;
   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   $delay = 2.5;     # Must be > 1.0 for the tests to work properly.

   DBUG_PUSH ( get_fish_log(), delay => ${delay}, elapsed => 1, off => ${off} );

   if ( $off ) {
      $delay = 0;               # There is no delay ...
   } elsif ( ! is_hires_supported () ) {
      $delay =~ s/[.]\d+$//;    # Truncate the delay value ...
   }

   # Sets the color on the lines we're interested in validating ...
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_FUNC, "bold red on_black");

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   is2 ($start_level, $lvl, "In the BEGIN block ...");   # Test # 2

   ok2 ( dbug_active_ok_test () );

   ok2 ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   # Only call OK if encountering errors!
   # We're not supposed to do any testing in this end block!
   my $lvl = test_fish_level ();
   if ( $start_level != $lvl ) {
      ok2 (0, "In the END block ...");
   }

   DBUG_VOID_RETURN ();
}

END {
   my $end_time = time ();
   if ( $delay != 0 ) {
      open (DELAY_FILE, ">", get_delay_file ()) or
               die ("Can' open delay file: " . get_delay_file () . "($!)\n");
      print DELAY_FILE ( $end_time - $start_time) . "\n";
      close (DELAY_FILE);
   }
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   my $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "In the MAIN program ...");

   test_1 ();
   test_2 ();
   test_pause ();

   $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "MAIN Level Final Check ...");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------------------
# Returns:  numer-of-tests, the elapsed time.
# -----------------------------------------------------------
sub delay_test
{
   DBUG_ENTER_FUNC (@_);

   my $begin = time ();
   ok2 (1, "First Wait Test");
   ok2 (1, "Second Wait Test");
   ok2 (1, "Third Wait Test");
   my $end = time ();

   DBUG_RETURN ( 3, $end - $begin );
}

sub test_1
{
   DBUG_ENTER_FUNC (@_);

   my ($cnt, $elapsed) = delay_test ();

   # Expected elapsed time ...
   my $total = ($cnt * $delay);

   # Allow for rounding errors in total sleep time!
   $total -= 0.5  if ( $delay );

   ok2 ( $elapsed >= $total, "Elapsed time for ${cnt} tests was greater than ${total} second(s)." );

   DBUG_VOID_RETURN ();
}

sub test_2
{
   DBUG_ENTER_FUNC (@_);

   my ($ttl_cnt, $ttl_elapsed) = (0, 0);
   foreach (0..3) {
      my ($cnt, $elapsed) = delay_test ();
      $ttl_cnt += $cnt;
      $ttl_elapsed += $elapsed;
   }

   # Expected elapsed time ...
   my $total = DBUG_ACTIVE () ? ($ttl_cnt * $delay) : 0;

   # Allow for rounding errors in total sleep time!
   $total -= 0.5  if ( $delay && DBUG_ACTIVE() );

   ok2 ( $ttl_elapsed >= $total, "Elapsed time for ${ttl_cnt} tests was greater than ${total} second(s)." );

   DBUG_VOID_RETURN ();
}

sub test_pause
{
   DBUG_ENTER_FUNC (@_);
   DBUG_PAUSE ();
   ok2 (1, "Pause is turned on ...");
   test_2 ();
   DBUG_VOID_RETURN ();
}

