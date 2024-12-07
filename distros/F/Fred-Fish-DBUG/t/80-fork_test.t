#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;
use Sub::Identify 'sub_fullname';
use Config qw( %Config );

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  80-fork_test.t
# ---------------------------------------------------------------------
# Tests out what happens when used in a process that forks.
# This is not the same as a multi-threaded program!
# ---------------------------------------------------------------------
# My assumption is that this will behave similar to how threads work
# as far as the fish logs are concerned.  Except that thread id (tid)
# will always be zero while the PID ($$) changes!
# ---------------------------------------------------------------------
# It's begining to look like "Fred::Fish::DBUG" may be fork safe.
# But if fish is already open when you fork a new process the trace
# may be difficult to follow without using option "multi" and using
# a tool such as grep to filter out the other threads.  Since all
# forked prcesses will write to the same fish log file.  You need to
# use option "multi" to be able to trace whats happening in fish!
# ---------------------------------------------------------------------
# PURPOSE:  To have all forked processes write to a single fish log file!
# ---------------------------------------------------------------------

# To debug this test case run:
#   1) prove -vb t/70-fork_test.t


my $start_level;

BEGIN {
   my $fork_possible = 1;     # Assume forks are supported ...
   my $threads_possible = 0;  # Assume threads are not supported ...

   # A quick & dirty threads test ... (incomplete)
   $threads_possible = 1  if ( $] >= 5.008001 && $Config{useithreads} );

   unless ( $Config{d_fork} ) {
      $fork_possible = 0  unless ($^O eq 'MSWin32' || $^O eq 'NetWare');
      $fork_possible = 0  if ( $threads_possible == 0 );
      $fork_possible = 0  unless ($Config{ccflags} =~ m/-DPERL_IMPLICIT_SYS/);
   }

   unless ( $fork_possible ) {
      ok (1, "Skipping this test case.  You are not allowed to 'fork' a subprocess!");
      done_testing ();
      exit (0);
   }
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
                      join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Uses options qw / " . join (" ", @opts) . " /");

   if ( is_fork_supported() ) {
     dbug_ok (1, "${fish_module} says forking IS supported!");
   } else {
     dbug_ok (1, "${fish_module} says forking is NOT supported!");
   }

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }
}

sub my_warn
{
   chomp (my $msg = shift);
   my $sts = ( $msg =~ m/^In a depth of \d+/ ) ? 1 : 0;
   dbug_ok ($sts, "There was an expected warning!  Check fish. (Fork $$)");
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
   dbug_is ($start_level, 1, "In the BEGIN block ...");

   dbug_ok ( dbug_active_ok_test () );
   dbug_ok ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   # Only print out on failure!  Tests have aleady ended!
   my $end_level = test_fish_level_no_warn ($start_level);
   unless ( $start_level == $end_level ) {
      dbug_ok (0, "In the END block ... Level test worked!");
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

   my $fish_file = DBUG_FILE_NAME ();

   unless ( is_fork_supported () ) {
      dbug_ok (1, get_fish_module () . " says forks are not supported for your Perl!  Skipping fork tests.");
      done_testing ();
      DBUG_LEAVE (0);
   }

   dbug_ok (1, "NOTE: All forked processes will write to the same fish logs.  So it's a mess to follow!");
   DBUG_PRINT ("NOTE", "%s\n%s\n%s",
                       "This test program waits until all forked processes completes.",
                       "Otherwise the 'make test' case fails with unknown error.",
                       "Even though it doesn't kill the child process or stop it from writing to fish.");

   dbug_is (test_fish_level_no_warn($start_level), $start_level, "In the MAIN program ...");

   my $res = new_fork_func (0, "Not a forked call!");
   dbug_ok (1, "Function returned: $res");

   undef_fork_func (0, "Not a forked call!");
   dbug_ok (1, "Function returned");

   # Has 2 tests ...
   my $sleep = 1;
   my $pid1 = fork_ok (2, \&new_fork_func, $sleep, "One", "Two", "Three");

   # Has 1 test ...
   my $pid2 = fork_ok (1, \&undef_fork_func, "Alpha", "Beta", "Omega");

   # Has 2 tests ...
   $sleep = 5;
   my $pid3 = fork_ok (2, \&new_fork_func, $sleep, "Eeny", "Meeny", "Miny", "Mo");

   # NOTE:  If you don't wait for all children to complete, then
   #        "make test" will say those tests failed!  (Limitation of Make::Test)
   #        Order isn't important!
   DBUG_PRINT ("----", "-"x40);
   waitpid ( $pid3, 0 );
   waitpid ( $pid2, 0 );
   waitpid ( $pid1, 0 );

   # Got the 7 by trial and error!
   DBUG_PRINT ("=====", "="x40);
   my $pid4 = fork_ok (7, \&multiple_forks);
   waitpid ( $pid4, 0 );
   DBUG_PRINT ("=====", "="x40);

   # Turning numbers back on is optional here!
   # But can only do after all child threads have terminated!
   # So that the order of the tests remain unimportant!
   Test::More->builder->use_numbers (1);
   dbug_ok (1, "All forks have completed!");

   # Tell Test::More we're done with the testing!
   done_testing ();

   DBUG_LEAVE (0);
}

# ----------------------------------------------------------------
# Lifted from Test::Fork::fork_ok()
# Rather than requiring this module be loaded ...
sub fork_ok
{
   DBUG_ENTER_FUNC (@_);
   my $num_tests  = shift;    # Number of tests run by child process!
   my $child_func = shift;    # A CODE reference to function call ...
   my @args       = @_;       # The arguments to pass the function.

   # Is fork supported ....
   my $pid;
   eval {
      $pid = fork ();   # Undef, 0, CPID  (fail, child, parrent)
   };
   if ($@) {
      dbug_ok (1, "Fork not supported by this Perl build!  Aborting this test!");
      done_testing ();
      DBUG_LEAVE (0);
   }

   # The fork command exists, but it failed!
   unless ( defined $pid ) {
      dbug_ok (0, "Fork Succeeded!");
      done_testing ();
      DBUG_LEAVE (0);
   }

   if ( $pid ) {
      run_parent ( $pid, $num_tests );

   } else {
      DBUG_PRINT ("----", "-"x40);
      fork_child ( $child_func, @args );
      DBUG_LEAVE (0);
   }

   DBUG_RETURN ( $pid );    # The child's PID
}

sub fork_child
{
   DBUG_ENTER_FUNC (@_);
   my $child_func = shift;
   my @args       = @_;

   Test::More->builder->use_numbers (0);
   Test::More->builder->no_ending (1);

   my $name = sub_fullname ( $child_func );

   # Not counted when counting child test cases!
   dbug_ok (1, "In Child (pid $$) -- $name()");     # The +1 test.

   my @res = $child_func->( @args );

   DBUG_VOID_RETURN ();
}

sub run_parent
{
   DBUG_ENTER_FUNC (@_);
   my ( $pid, $num_tests ) = ( shift, shift );

   Test::More->builder->use_numbers (0);
   my $cnt1 = Test::More->builder->current_test();
   my $cnt2 = Test::More->builder->current_test ($cnt1 + $num_tests + 1);

   dbug_ok (1, "Fork Succeeded!  Running child pid [$$]  ($cnt1 -> $cnt2)");

   # waitpid ( $pid, 0 );

   DBUG_VOID_RETURN ();
}


# ----------------------------------------------------------------
# What each forked job is actually doing ...
# ----------------------------------------------------------------
sub new_fork_func
{
   DBUG_ENTER_FUNC (@_);
   my $sleep = shift;

   # Returns an object referncing the current thread ...
   my $id = "???";

   if ( $sleep > 0 ) {
      dbug_ok (1, "In Fork-$_[0]: ($$).   Sleeping for ${sleep} second(s)");
      sleep ($sleep);
      dbug_ok (1, "In Fork-$_[0]: ($$).   Slept for ${sleep} second(s)");
   } else {
      dbug_ok (1, "In Fork-$_[0]: ($$).   Not sleeping!");
      dbug_ok (1, "Noop");
   }

   # If we're running in a thread instead of the main program ...
   # if ( $id > 0 ) { ... }

   DBUG_RETURN ( join (", ", reverse @_) );
}

# ----------------------------------------------------------------
sub undef_fork_func
{
   DBUG_ENTER_FUNC (@_);
   dbug_ok (1, "In Fork-$_[0]: ($$).   Not sleeping!");
   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# Doesn't update the counts in the main thread ...

sub multiple_forks
{
   DBUG_ENTER_FUNC (@_);

   my $pid1 = fork_ok ( 2, \&new_fork_func, 2, "a", "b", "c" );
   my $pid2 = fork_ok ( 1, \&undef_fork_func,  "x", "y", "z" );

   waitpid ($pid2, 0);
   waitpid ($pid1, 0);

   DBUG_VOID_RETURN ();
}

