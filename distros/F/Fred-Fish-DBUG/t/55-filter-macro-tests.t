#!/user/bin/perl

use strict;
use warnings;

use Test::More;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  55-filter-macro-tests.t
# -----------------------------------------------------------------------
# This script tests out the DBUG_FILTER, DBUG_SET_FILTER_COLOR &
# DBUG_EXECUTE() logic in determining what gets written to fish!
# -----------------------------------------------------------------------
# Does the same tests as "t/40-filter-tests.t" except uses color MACROS!
# So can do:  diff t/fish/40-filter-tests.fish.txt t/fish/45-filter-macro-tests.fish.txt | less -R
# -----------------------------------------------------------------------

my $start_level;


sub my_warn
{
   my $msg = shift;
   chomp($msg);
   if ( $msg ne "Hello World!") {
      dbug_ok (0, "There was an expected warning!  Check fish.");
   } else {
      dbug_ok (1, "Hit expected warning for: ${msg}");
   }
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {    # Test # 2
      dbug_BAIL_OUT ( "Can't load $fish_module vi Fred::Fish::DBUG qw / " .
                      join (" ", @opts) . qw " /" );
   }

   dbug_ok (1, "Used options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }
}

BEGIN {
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;
   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   # Supress the printing out of FISH for the END blocks ...
   DBUG_PUSH ( get_fish_log(), kill_end_trace => 1, off => ${off} );

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   dbug_is ($start_level, $lvl, "In the BEGIN block ...");   # Test # 2

   dbug_ok ( dbug_active_ok_test () );

   dbug_ok ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


# Load the color module so I can use the color constants.
# Terminates the test if the module isn't installed since
# we'd get perl compilation errors otherwise.
BEGIN {
   DBUG_ENTER_FUNC ();
   eval {
      if ( $^O eq "MSWin32" ) {
         # Windows needs this module for Term::ANSIColor will work.
         require Win32::Console::ANSI;
         Win32::Console::ANSI->import ();
      }

      require Term::ANSIColor;
      Term::ANSIColor->import (':constants');
      # Term::ANSIColor->import (':constants256');   # Works also!
      dbug_ok (1, "Color MACROS are supported!");
   };
   if ($@) {
      dbug_ok (1, "Color MACROS are NOT supported!");
      done_testing ();
      DBUG_LEAVE (0);
   }
   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   # Only call OK if encountering errors!
   # We're not supposed to do any testing in this end block!
   my $lvl = test_fish_level ();
   if ( $start_level != $lvl ) {
      dbug_ok (0, "In the END block ...");
   }

   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   # Sets color & returns if color is actually supported or not.
   my $bool = DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_FUNC,  BOLD, GREEN, ON_RED);

   DBUG_ENTER_FUNC (@ARGV);

   my $lvl = test_fish_level ();
   dbug_is ($lvl, $start_level, "In the MAIN program ...");  # Test # 4 ...

   # If coloring is supported ...
   if ( $bool ) {
      # Unexposed constant value ...
      my $bad_lvl = get_fish_module()->DBUG_FILTER_LEVEL_MAX + 1;
      my $bad_tst = DBUG_SET_FILTER_COLOR ($bad_lvl, BOLD, BLUE, ON_BLACK);
      dbug_is ( $bad_tst, 0, "Unable to set colors for unknown filter level ($bad_lvl)" );
   }

   # Tag everything to use colors if available ...
   dbug_ok (1, "Using color strings ...")  if ( $bool );
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_FUNC,     BOLD, GREEN, ON_BLACK);
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_ARGS,     YELLOW, ON_BLACK);
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_ERROR,    RED, ON_BLACK);
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_WARN,     BOLD, "red", ON_YELLOW);
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_DEBUG,    BLACK, ON_WHITE);
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_INFO,     BLUE, ON_GREEN);
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_OTHER,    BOLD, BLUE, ON_BLACK);
   DBUG_SET_FILTER_COLOR (DBUG_FILTER_LEVEL_INTERNAL, BOLD, "white", ON_BLACK);

   # Test with colors ... (if available)
   $ENV{ANSI_COLORS_DISABLED} = 0;
   run_all_tests ( ($start_level + 1), 1, 2, 3 );

   # Test without colors ...
   if ( $bool ) {
      local $ENV{ANSI_COLORS_DISABLED} = 1;
      dbug_ok (1, "------------- No Color --------------------");
      run_all_tests ( ($start_level + 1), 'a', 'b', 'c', 'd' );
      dbug_ok (1, "------------- End No Color ----------------");
   }

   $lvl = test_fish_level ();
   dbug_is ($lvl, $start_level, "MAIN Level Final Check ...");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

sub run_all_tests
{
   my $func = DBUG_ENTER_FUNC (@_);
   my $new_level = shift;
   my @args = @_;

   warn ("Hello World!\n");

   my @ans;
   my $cnt = 0;
   DBUG_FILTER (DBUG_FILTER_LEVEL_FUNC);
   ($cnt, @ans) = test_case (@args);
   dbug_ok (comp(\@args, \@ans), "Filtered Return Values OK ($cnt)");
   dbug_ok (fcmp ($cnt, 0), "Wrote the correct number of lines to fish.");

   DBUG_FILTER (DBUG_FILTER_LEVEL_ARGS);
   push (@args, 4);
   ($cnt, @ans) = test_case (@args);
   dbug_ok (comp(\@args, \@ans), "Filtered Return Values OK ($cnt)");
   dbug_ok (fcmp ($cnt, 0), "Wrote the correct number of lines to fish.");

   DBUG_FILTER (DBUG_FILTER_LEVEL_ERROR);
   push (@args, 5);
   ($cnt, @ans) = test_case (@args);
   dbug_ok (comp(\@args, \@ans), "Filtered Return Values OK ($cnt)");
   dbug_ok (fcmp ($cnt, 2), "Wrote the correct number of lines to fish.");

   DBUG_FILTER (DBUG_FILTER_LEVEL_WARN);
   push (@args, 6);
   ($cnt, @ans) = test_case (@args);
   dbug_ok (comp(\@args, \@ans), "Filtered Return Values OK ($cnt)");
   dbug_ok (fcmp ($cnt, 4), "Wrote the correct number of lines to fish.");

   DBUG_FILTER (DBUG_FILTER_LEVEL_DEBUG);
   push (@args, 7);
   ($cnt, @ans) = test_case (@args);
   dbug_ok (comp(\@args, \@ans), "Filtered Return Values OK ($cnt)");
   dbug_ok (fcmp ($cnt, 6), "Wrote the correct number of lines to fish.");

   DBUG_FILTER (DBUG_FILTER_LEVEL_INFO);
   push (@args, 8);
   ($cnt, @ans) = test_case (@args);
   dbug_ok (comp(\@args, \@ans), "Filtered Return Values OK ($cnt)");
   dbug_ok (fcmp ($cnt, 7), "Wrote the correct number of lines to fish.");

   DBUG_FILTER (DBUG_FILTER_LEVEL_OTHER);
   push (@args, 9);
   $cnt = test_case (@args);
   dbug_ok (fcmp ($cnt, 9), "Filtered Return Values OK ($cnt)");

   # Skip this test for Fred::Fish::DBUG::OFF ...
   if ( $new_level ) {
      my $lvl = test_fish_level ();
      dbug_is ($new_level, $lvl, "${func} Level Check (level: $lvl)");

      my $blk = DBUG_ENTER_BLOCK ("block");
      $lvl = test_fish_level ();
      dbug_is ( ($new_level + 1), $lvl, "${blk} Level Check (level: $lvl)");
      DBUG_VOID_RETURN ();
   }

   DBUG_VOID_RETURN ();    # For the main function ...
}

# -----------------------------------------------
# Tells how many data rows to expect!
sub fcmp
{
   my $cnt      = shift;    # Rows writen to fish ...
   my $expected = shift;    # Rows expected to fish ...

   my $ok = 0;
   if ( $ENV{FISH_OFF_FLAG} ) {
      $ok = ( $cnt == 0 ) ? 1 : 0;
   } else {
      $ok = ( $cnt == $expected ) ? 1 : 0;
   }

   return ($ok);
}

# -----------------------------------------------

sub test_case
{
   DBUG_ENTER_FUNC (@_);

   my $cnt = 0;    # Should return between 0 and 9!

   DBUG_ENTER_BLOCK ("What's up?");
   $cnt += my_print ("error", "Error Message # 1");      # Cnt 1
   $cnt += my_print ("ERROR", "Error Message # 2");      # Cnt 2
   $cnt += my_print ("WARN", "Warning Message # 1");     # Cnt 3
   $cnt += my_print ("WARNing", "Warning Message # 2");  # Cnt 4
   $cnt += my_print ("DBUG", "Debugging Message # 1");   # Cnt 5
   $cnt += my_print ("debug", "Debugging Message # 2");  # Cnt 6
   $cnt += my_print ("Info", "Inforation Message # 1");  # Cnt 7
   $cnt += my_print ("Help", "Other Message!");          # Cnt 8
   $cnt += my_print (get_fish_module (), "Should never print!");

   # Not counted since PAUSE turns writing to fish off.
   DBUG_PAUSE ();
   $cnt += my_print ("Hello", "World!");
   $cnt += my_print ("Big", "Easy!");
   $cnt += my_print (get_fish_module (), "Should never print!");
   DBUG_VOID_RETURN ();    # Should terminate the pause request!

   $cnt += my_print ("=======", "Don't forget to count this entry!");  # Cnt 9
   $cnt += my_print (get_fish_module (), "Should never print!");

   DBUG_RETURN ($cnt, @_);
}

# -----------------------------------------------
# Returns true if the tag is printed out, false if nothing written to fish.
sub my_print
{
   my $tag = shift;

   DBUG_PRINT ( $tag, @_ );

   return ( DBUG_EXECUTE ( $tag ) );    # returns:  1 or 0
}

# -----------------------------------------------
# Tells if two arrays are equivalent.
sub comp
{
   my $src = shift;
   my $ret = shift;

   return (0)  if ( $#{$src} != $#{$ret} );

   foreach ( 0.. $#{$src} ) {
      return (0)  if ( $src->[$_] ne $ret->[$_] );
   }

   return (1);
}

# -----------------------------------------------

