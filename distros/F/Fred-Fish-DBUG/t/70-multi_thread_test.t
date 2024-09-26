#!/user/bin/perl

use strict;
use warnings;

# use Test::More 0.88;    # Will load instead in the 1st BEGIN block!
use File::Spec;
use File::Basename;
use Config qw( %Config );

# Program:  70-multi_thread_test.t
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
# But if fish is already open when you spawn a new thread the trace
# may be difficult to follow without using option "multi" and using
# a tool such as grep to filter out the other threads.  Since all
# threds will write to the same fish log file.
# ---------------------------------------------------------------------
# PURPOSE:  To have all threads write to a single fish log file!
# ---------------------------------------------------------------------

# OUT OF MEMORY ISSUS:  (particularly under Unix!)
#  This doesn't always mean you ran out of system memory.  Quite often
#  it really means you've hit a hard resource limit set for your account!
#  Some user accounts limit the amount of resources a process can use.
#  This can vary from account to account on the same server.  Meaning
#  that under one account you'll get an out of memory error, while
#  everything works fine under another account.

#  So if you get an out of memory error reduce the constant below!

use constant ulimit_max_threads => 44;       # Never set under 15!

BEGIN {
   my $allow_threads = 0;

   # Test not 100% correct ... You can get false positives!
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
      BAIL_OUT ( "Can't load helper1234" );
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

sub my_warn
{
   chomp (my $msg = shift);
   my $sts = ( $msg =~ m/^In a depth of \d+/ ) ? 1 : 0;
   ok3 ($sts, "There was an expected warning!  Check fish. (Thread " . threads->tid() . ")");

   # Get where the origial warn happened!
   # Skipp over the DBUG code.
   my $ind = 1;
   my @c = (caller($ind))[1,2];
   my $f = basename ($c[0]);
   while ( $f eq "DBUG.pm" || $f eq "Signal.pm" || $f eq "ON.pm" || $f eq "OFF.pm" ) {
      @c = (caller(++$ind))[1,2];
      $f = basename ($c[0]);
   }
   diag ("  at $c[0] line $c[1].\n");
}

BEGIN {
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   my $os = $^O;
   my $windows = ($os eq "MSWin32");

   DBUG_PUSH ( get_fish_log(), multi => 1, off => ${off}, limit => 0 );

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level_no_warn (1);
   is2 ($start_level, 1, "In the BEGIN block ...");

   ok3 ( dbug_active_ok_test () );

   ok3 ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   # Checking the exit status to verify all tests have passed.
   # If anything failed, this test is likely to fail as well!
   # So skipping on failure to avoid confusing this with real failures.

   if ( $? == 0 ) {
      my $end_level = test_fish_level_no_warn ($start_level);

      # Only print out on failure!  All other tests have already passed!
      unless ( $start_level == $end_level ) {
         ok3 (0, "In the END block ... Level test worked!");
      }
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

   my $fish_file = DBUG_FILE_NAME ();

   ok2 (1, "NOTE: All threads will write to the same fish logs.  So it's a mess to follow!");

   DBUG_PRINT ("NOTE", "%s\n%s\n%s",
                       "Threads 8 & 9 are unbalanced to make sure the program finishes all other tests before those 2 threads complete!",
                       "It looks as if all child threads get killed when the parent thread terminates and leaves behind trash files.",
                       "So the last thing this program does is wait until those rouge threads complete.");

   is2 (test_fish_level_no_warn($start_level), $start_level, "In the MAIN program ...");

   my $res = new_thread (0, "Not a thread call!");
   ok2 (1, "Function returned: $res");

   my $thr1 = threads->create ( \&new_thread, 3, "one", "test" );
   my $thr2 = threads->create ( \&new_thread, 2, "two", "test" );

   $res = threads->create ( \&new_thread, 1, "three", "test" )->join ();
   ok2 (1, "Thread 3 returned: $res");

   my $thr4 = threads->create ( \&undef_thread, 2, "four", "test" );

   $res = $thr2->join ();
   ok2 ( defined $res, "Thread 2 returned: $res" );
   $res = $thr1->join ();
   ok2 ( defined $res, "Thread 1 returned: $res" );
   $res = $thr4->join ();
   ok2 ( ! defined $res, "Thread 4 returned: <undef>" );

   ok2 (1, "-----------------------------------------------------");

   my $thr5 = threads->create ( \&recursive_thread_wrapper, 10, 5 );
   my $thr6 = threads->create ( \&recursive_thread_wrapper, 4, 4 );
   my $thr7 = threads->create ( \&recursive_thread_wrapper, 2, 3 );
   catch_all_pending_threads ("FIRST");

   ok2 (1, "-----------------------------------------------------");
   ok3 (1, "Running detached thread tests ...");

   # These tests must be threads 9, 10, 11!  Please update the
   # NOTE above if this ever changes.  As well as updating this comment!
   my $thr8 = threads->create ( \&new_thread, 25, "eight", "test" );
   my $thr9 = threads->create ( \&new_thread, 21, "nine", "test" );
   my $thr10 = threads->create ( \&new_thread, 5, "ten", "test" );
   sleep (1);

   # These threads will stop writting to fish if this main thread
   # closes fish before they finish sleeping ...
   # My best guess why is that the main thread kills the child threads!
   $thr8->detach ();
   $thr9->detach ();

   # This one should finish before the program terminates.
   $thr10->detach ();

   ok2 (1, "-----------------------------------------------------");

   # If we're not thread safe, this should proove it!
   # If you get "Out of memory!" errors just reduce the count!
   my $next_tid = call_threads (11..ulimit_max_threads);
   catch_all_pending_threads ("SECOND");

   ok2 (1, "-----------------------------------------------------");

   # Handles threads calling threads ... 3 deep ...
   $next_tid = multi_threads ( $next_tid, 3 );

   ok2 (1, "-----------------------------------------------------");

   # Uncomment if you'd like to give the detached threads a chance
   # to write to the fish logs ...
   # sleep (15);

   if ( DBUG_ACTIVE () ) {
      ok3 (1, "Examine the logs for how safe it is!\nOn unix use 'grep ^[0-9]*-<id>: ${fish_file}',\nwhere <id> is the thread tid you'd like to follow.");
   }

   is2 (test_fish_level_no_warn($start_level), $start_level, "Ending the MAIN program ...");

   # If we don't wait for this thread to complete it will leave trash on the file system.
   # Since when the main thread exits, it automatically terminates any running threads!
   while ( $thr8->is_running () ) {
      ok3 ( 1, "Detached Thread 8 is still running!" );
      sleep (2);
   }
   ok3 ( 1, "Detached Thread 8 has stopped running!" );

   # warn ("This is an error!\n");

   # Tell Test::More we're done with the testing!
   done_testing ();

   DBUG_LEAVE (0);
}

# ----------------------------------------------------------------
# Makes sure all threads log fish 2 fuctions deap!
# Assumes all thread ids are assigneed sequentially ...
# Returns: The next Thread-Id to use.

sub call_threads
{
   DBUG_ENTER_FUNC ();    # Didn't pass @_ on purpose

   ok2 (1, sprintf ("Starting threads %d..%d",  $_[0], $_[-1]));

   my $last_kid = -1;
   foreach (@_) {
      my $kid = threads->create ( \&recursive_thread_wrapper, 2, 2 );
      last  unless ( $kid );   # Stop if we can't create a new thread!
      $last_kid = $_;          # Should be same as $kid->tid();
   }

   if ( $last_kid == -1 ) {
      ok2 (0, "We were able to kick off at least one thread in the bulk request!");
      done_testing ();
      DBUG_LEAVE(0);
   }

   DBUG_RETURN ( $last_kid + 1 );
}

# ----------------------------------------------------------------
# Waits for all active theads to complete!
# Ignores all threads in a detached status!
# ----------------------------------------------------------------
sub catch_all_pending_threads
{
   DBUG_ENTER_FUNC (@_);

   foreach my $thr ( threads->list () ) {
      my $tid = $thr->tid ();
      my $res = $thr->join ();
      if ( defined $res ) {
         ok2 (1, "Thread ${tid} returned: $res");
      } else {
         ok2 (0, "Thread ${tid} returned: <die called in thread>");
      }
   }

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# What each thread is actually doing ...
# ----------------------------------------------------------------
sub new_thread
{
   DBUG_ENTER_FUNC (@_);
   my $sleep = shift;

   # Returns an object referncing the current thread ...
   # my $self = threads->self();

   my $id = threads->tid();

   if ( $sleep > 0 ) {
      ok2 (1, "In Thread-$_[0]: ($$, $id).   Sleeping for ${sleep} second(s)");
      sleep ($sleep);
      ok2 (1, "In Thread-$_[0]: ($$, $id).   Slept for ${sleep} second(s)");
   } else {
      ok2 (1, "In Thread-$_[0]: ($$, $id).   Not sleeping!");
   }

   # If we're running in a thread instead of the main program ...
   # if ( $id > 0 ) { ... }

   DBUG_RETURN ( join (", ", reverse @_) );
}

# ----------------------------------------------------------------
sub undef_thread
{
   DBUG_ENTER_FUNC (@_);
   my $tid = threads->tid();
   ok2 (1, "In Thread-$tid: ($$, $tid).   Not sleeping!");
   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
sub recursive_thread
{
   DBUG_ENTER_FUNC (@_);
   my $level    = shift;
   my $how_deep = shift;
   my $sleep    = shift;

   my $res;
   if ( $how_deep <= 0 ) {
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

   # -----------------------------------------------------------------------
   # Uncomment if you'd like to prove BAIL_OUT() works in threads!
   # IE it causes the entire test program to abort!  Not just the thread!
   # Fred::Fish::DBUG::END() doesn't seem to be called!
   # BAIL_OUT ("Thread Bail Out!\n");

   # -----------------------------------------------------------------------
   # Just causes the thread to die, it doesn't kill off the main thread!
   # In fact threads->join () returns <undef> to the parent thread!
   # die ("Thread failure!!\n");

   # DIE NOTE:
   #    If too many theads call die, you could get an "Out of memory!" error.
   #    Which causes all threads to immediately die & stop writting to fish.
   #    Also appears that no calls to END are made!  I'm assuming this error
   #    message is from Perl itself, not the script.

   # -----------------------------------------------------------------------
   # Eval worked & trapped die!  Then it called BAIL_OUT() as expected!
   # Unlike the untrapped die, this doesn't cause an "Out of memory!" problem
   # if we comment out BAIL_OUT().
   eval {
      # die ("Thread Failure in eval!\n");
   };
   if ( $@ ) {
      # BAIL_OUT ("We caught a die message!  $@");
   }

   DBUG_RETURN ( $res );
}


# ----------------------------------------------------------------
# Calls threads within threads ...
sub multi_threads
{
   DBUG_ENTER_FUNC (@_);
   my $start = shift;
   my $deep  = shift;

   # Must match the RegExp test in my_warn() ...
   warn ("In a depth of ${deep}\n");

   # Break infinite recursion ...
   return DBUG_RETURN ( $start )  if ( $deep <= 0 );

   my $sub_thread = threads->create (\&multi_threads_wrapper, $start + 1, $deep);

   my $id  = $sub_thread->tid ();
   my $res = $sub_thread->join ();
   ok2 ( defined $res, "Thread ${id} returned: ${res}" );

   DBUG_RETURN ( $res );    # The next tid()!
}

sub multi_threads_wrapper
{
   DBUG_ENTER_FUNC (@_);
   my $start = shift;
   my $deep  = shift;

   my $stop = $start + 5;
   my $next_tid = call_threads ($start..$stop);
   catch_all_pending_threads ("MULTI");

   $next_tid = multi_threads ( $next_tid, $deep - 1 );

   DBUG_RETURN ( $next_tid );
}

