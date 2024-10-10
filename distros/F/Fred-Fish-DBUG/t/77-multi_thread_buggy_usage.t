#!/user/bin/perl

use strict;
use warnings;

# use Test::More 0.88;    # Will load instead in the 1st BEGIN block!
use File::Spec;
use Config qw( %Config );

# Defered since has to be done after Test::More due to multi-threading.
# BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
# use helper1234;

# Program:  77-multi_thread_buggy_usage.t
# ---------------------------------------------------------------------
# Tests out what happens when used in a multi-threaded process!
# See:  https://perldoc.perl.org/perlthrtut.html
# ---------------------------------------------------------------------
# NOTE: Test::More is only aware of threads if loaded after the
#       the threads module!  Hence the complex BEGIN block below!
#       Complexity needed so tests won't fail for non-threading
#       Perl builds.
# ---------------------------------------------------------------------
# NOTE: All threads share the same PID ($$) since they are all run
#       under the same Perl process.  The only difference being
#       the thread id! (tid)
# ---------------------------------------------------------------------
# It's begining to look like "Fred::Fish::DBUG" may be thread safe.
# In this test each program thread will open its own fish log,
# but the name of the fish file will be the same one used by the
# parrent process.
# In this particular cas using the "multi" option is required to
# follow what is happening.
# The goal is to see how badly the threads step on each other
# when we do this.
# ---------------------------------------------------------------------
# PURPOSE:  To demonstrate what happens when each thread reopens the
#           same fish file used by it's parent!
#           To demonstrate no matter what options are used you can't
#           reliably be thread-safe any more.
#     (The test cases still pass.  Demonstrating how difficult
#      it is to actually prove things are not working!  That
#      despite passing it's tests, it still requiers a manual
#      review of the fish logs to 100% prove the final product
#      is valid.)
# ---------------------------------------------------------------------

BEGIN {
   my $allow_threads = 0;

   # Test not 100% correct ...
   if ( $] >= 5.008001 && $Config{useithreads} ) {
      $allow_threads = 1;
      eval {
         require threads;
         threads->import ();
         $allow_threads = 2;
      };
   }

   # Minimum version required:  0.88
   require Test::More;
   Test::More->import ();

   if ( $allow_threads == 0 ) {
      ok (1, "Skipping this test case.  Your Perl build does not support threads!");
      done_testing ();
      exit (0);
   }

   if ( $allow_threads == 1 ) {
      ok (1, "Skipping this test case.  You do not have the 'threads' module installed!");
      done_testing ();
      exit (0);
   }

   eval {
      Test::More->VERSION ( 0.88 );
   };
   if ( $@ ) {
      ok (1, "You need to upgrade Test::More to at least version 0.88 before running this test!");
      done_testing ();
      exit (0);
   }

   ok (1, "Threads are supported!");

   return;
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   push (@INC, File::Spec->catdir (".", "t", "off"));

   # Helper module makes sure DIE & WARN traps are set ...
   unless (use_ok ("helper1234")) {
      done_testing ();
      BAIL_OUT ( "Can't load helper1234" );   # Test # 1
      exit (0);
   }

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {
      bail ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
             join (" ", @opts) . " /" );
   }

   ok (1, "Used options qw / " . join (" ", @opts) . " /");

   if ( is_threads_supported() ) {
      ok (1, "${fish_module} says threads ARE supported!");
   } else {
      ok (1, "${fish_module} says threads are NOT supported!" );
   }

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
      exit (0);
  }
}


my $start_level;
my $fish_logs;
my %fish_opts;

sub my_warn
{
   ok3 (0, "There was an expected warning!  Check fish.");
}

BEGIN {
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   my $os = $^O;
   my $windows = ($os eq "MSWin32");

   $fish_opts{multi} = 1;
   $fish_opts{limit} = 0;
   $fish_opts{off}   = ${off};

   # The above options are not enough to result in a good fish file!
   $fish_opts{append} = 1;    # Makes it messy but almost does it.
   $fish_opts{autoopen} = 1;  # Makes it a bit more reliable.

   # Not calling DBUG_PUSH() on purpose here!
   # So need to calcualte the names of the fish logs to use!
   $fish_logs = get_fish_log ();
   $fish_logs =~ s/[.](fish[.]txt)$/.XXXXX.$1/;
   unlink ( $fish_logs );

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level_no_warn (1);
   is2 ($start_level, 1, "In the BEGIN block ...");

   ok3 ( ! DBUG_ACTIVE(), "Fish is turned OFF for now." );
   ok3 ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   # Only print out on failure!  Tests have aleady ended!

   my $end_level = test_fish_level_no_warn ($start_level);
   unless ( $start_level == $end_level ) {
      ok3 (0, "In the END block ... Level test worked!");
   }

   DBUG_VOID_RETURN ();
}

# ---------------------------------------------------------------- #
# ---------------------------------------------------------------- #
#          The start of the MAIN program!                          #
# ---------------------------------------------------------------- #
# ---------------------------------------------------------------- #

{
   DBUG_ENTER_FUNC (@ARGV);

   unless ( is_threads_supported () ) {
      ok2 (1, get_fish_module () . " says threads are not supported for your Perl!  Skipping threads tests.");
      done_testing ();
      DBUG_LEAVE (0);
   }

   ok2 (1, "NOTE: Each thread writes to the same fish log in a buggy way.  So it's output is compromised!");

   is2 (test_fish_level_no_warn($start_level), $start_level, "In the MAIN program ...");

   my $thr1 = threads->create ( \&new_thread, 5, "one", "test" );
   my $thr2 = threads->create ( \&new_thread, 3, "two", "test" );
   my $thr3 = threads->create ( \&undef_thread, 2, "three", "test" );
   my $thr4 = threads->create ( \&recursive_thread_wrapper, 6, 5 );
   my $thr5 = threads->create ( \&new_thread, 15, "five", "test-detatch" );
   my $thr6 = threads->create ( \&new_thread, 2, "six", "test-detatch" );

   # ----------------------------------------------------
   # Turns on Fred Fish Logs for the main process!!!
   # Nothing above this line gets logged into fish for
   # the main thread!
   # ----------------------------------------------------
   my $res = new_thread (0, "Not a thread call!");
   ok2 (1, "Function returned: $res");

   DBUG_PRINT ("NOTE", ".\n%s\n%s\n%s\n%s\n.",
               "Thead 5 is detached and designed to run long so that the program will wait until it completes.",
               "Since it looks as if all child threads are killed when the parent thread terminates!",
               "And since killed theads leave behind temp files, we have to wait until they get cleaned up to die!",
               "But it looks like no matter what you do you're not 100% thread-safe this way!"
              );

   # What happens to a tread that doesn't complete
   $thr5->detach ();   # Won't complete before the program does!
   $thr6->detach ();   # Does complete!

   $res = $thr3->join ();
   ok2 ( ! defined $res, "Thread 3 returned: <undef>" );
   $res = $thr2->join ();
   ok2 ( defined $res, "Thread 2 returned: $res" );
   $res = $thr1->join ();
   ok2 ( defined $res, "Thread 1 returned: $res" );
   $res = $thr4->join ();
   ok2 ( defined $res, "Thread 4 returned: $res" );

   ok2 (1, "-----------------------------------------------------");

   ok3 ( 1, "Each thread reopens the same log file!  Can't detect buggy writes!" );
   ok3 ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   is2 (test_fish_level_no_warn($start_level), $start_level, "Ending the MAIN program ...");

   # Must wait until this thread finishes running.  Else when the main thread
   # finishes it will kill thread 5 and leave trash on the file system.
   while ( $thr5->is_running () ) {
      ok3 ( 1, "Detached Thread 5 is still running." );
      sleep (2);
   }
   ok3 ( 1, "Detached Thread 5 has stopped running." );

   # Tell Test::More we're done with the testing!
   done_testing ();

   DBUG_LEAVE (0);
}

# ----------------------------------------------------------------
# What each thread is actually doing ...
# ----------------------------------------------------------------
# Does no fish logging on purpose!
# Doesn' matter since fish isn't turned on yet for the thread!
# Commented out the code that made the fish log name unique!
sub get_fish_name
{
   my $tid = threads->tid();

   my $fish = $fish_logs;
   # $fish =~ s/[.]XXXXX[.]/.TID_${tid}./;

   # unlink ( $fish );

   return ( $fish );
}

# ----------------------------------------------------------------
# Turns fish on inside the new thread!
# Does it in the expected way ...
sub new_thread
{
   # Calcualte the fish log's name for the curreent thread!
   my $fish = get_fish_name ();

   # -----------------------------------
   # The normal order to do things.
   #  1) DBUG_PUSH();
   #  2) DBUG_ENTER_FUNC();
   # -----------------------------------
   DBUG_PUSH ($fish, \%fish_opts);

   DBUG_ENTER_FUNC (@_);
   my $sleep = shift;
   my $lbl   = shift;

   my $tid = threads->tid();
   if ( $sleep > 0 ) {
      ok2 (1, "In Thread-$lbl: ($$, $tid).   Sleeping for ${sleep} second(s)");
      sleep ($sleep);
      ok2 (1, "In Thread-$lbl: ($$, $tid).   Slept for ${sleep} second(s)");
   } else {
      ok2 (1, "In Thread-$lbl: ($$, $tid).   Not sleeping!");
   }

   # If we're running in a thread instead of the main program ...
   # if ( $tid > 0 ) { ... }

   DBUG_RETURN ( join (", ", reverse @_) );
}

# ----------------------------------------------------------------
# Turns fish on inside the new thread!
# Does it in an alternate way ...
sub undef_thread
{
   DBUG_ENTER_FUNC (@_);

   # Calcualte the fish log's name for the curreent thread!
   my $fish = get_fish_name ();

   # Tell fish to redo the DBUG_ENTER_FUNC() call above.
   # But any arguments are lost to fish.
   $fish_opts{before} = 1;

   DBUG_PUSH ($fish, \%fish_opts);

   my $tid = threads->tid();
   ok2 (1, "In Thread-$tid: ($$, $tid).   Not sleeping!");

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# Waits until deep into the thread before turning fish on.
sub recursive_thread
{
   DBUG_ENTER_FUNC (@_);
   my $level    = shift;
   my $how_deep = shift;
   my $sleep    = shift;

   my $res;
   if ( $how_deep <= 0 ) {
      # Actually turns fish on ...
      $res = new_thread ( $sleep, threads->tid(), "test" );
   } else {
      $res = recursive_thread ( $level + 1, --$how_deep, $sleep );
   }

   # Only call's OK on failure!  Otherwise too verbose ...
   if ( $level != test_fish_level_no_warn ($level) ) {
      my $tid = threads->tid ();
      ok3 (0, "Thread ${tid}'s trace balanced out to level ${level}");
   }

   DBUG_RETURN ( $res );
}

# ----------------------------------------------------------------
sub recursive_thread_wrapper
{
   DBUG_ENTER_FUNC (@_);

   my $level = test_fish_level_no_warn (2);

   my $res = recursive_thread ( $level + 1, @_ );

   # Only call's OK on failure!  Otherwise too verbose ...
   if ( $level != test_fish_level_no_warn ($level) ) {
      my $tid = threads->tid ();
      ok3 (0, "Thread ${tid}'s trace balanced out to level ${level}");
   }

   DBUG_RETURN ( $res );
}

