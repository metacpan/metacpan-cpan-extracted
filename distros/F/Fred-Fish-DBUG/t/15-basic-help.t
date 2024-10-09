#!/user/bin/perl

# Program:  15-basic-help.t
#    Tests out the t/off/helper1234.pm module that is central to setting up
#    the environment for the remainder of the tests!
#    It uses $ENV{FISH_OFF_FLAG} to control this logic & other common
#    initialization!

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

# BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
# use helper1234;

my $start_level;

sub my_warn
{
   done_testing ();
   BAIL_OUT ( "An Unexpected Warning was trapped!");
   exit (0);
}

# BEGIN { $ENV{FISH_OFF_FLAG} = -1; }

BEGIN {
   # Can't use any of the constants or funcs defined by this module
   # unless we use them in a separate BEGIN block!

   push (@INC, File::Spec->catdir (".", "t", "off"));

   # Helper module makes sure DIE & WARN traps are set ...
   unless (use_ok ("helper1234")) {
      done_testing ();
      BAIL_OUT ( "Can't load helper1234" );   # Test # 1
      exit (0);
   }
   #   ok (1, "use helper1234;");
}

BEGIN {
   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   my %usr1 = find_fish_users ();
   my $cnt1 = keys %usr1;
   cmp_ok ($cnt1, '==', 1, "Found ${cnt1} users of DBUG (1).");

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {      # Test # 2
      bail ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
             join (" ", @opts) . " /" );
   }

   ok (1, "Used options qw / " . join (" ", @opts) . " /" );

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
      exit (0);
  }

   my %usr2 = Fred::Fish::DBUG::find_all_fish_users ();
   my $cnt2 = keys %usr2;
   cmp_ok ($cnt2, '==', 2, "Found ${cnt2} users of DBUG (2).");
}

# List of registered uses of this module.
sub chk_members {
   my $opt = shift;
   my %h = @_;

   my @msgs;
   for ( sort keys %h ) {
      my $msg = $_ . ' ==> ' . $h{$_} . "\n";
      push (@msgs, $msg);
   }

   if ( $opt) {
      ok (1, "Helper list of users of module");
      diag (@msgs);
      my $unk = Fred::Fish::DBUG::_find_module ("IGNORE-ME");
   } else {
      ok (1, "Local list of users of module");
      diag (@msgs);
   }

   return;
}

BEGIN {
   # Overrides the default trap for warnings ...
   # So can treat warnings as errors!
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $sts = get_fish_state ();

   my $off = ( $sts != 0 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off );

   my $lvl = ( $sts == -1 ) ? -1 : 1;

   DBUG_ENTER_FUNC ();

   # Test # 3 ...
   $start_level = test_fish_level ();
   is2 ($start_level, $lvl, "Level Check In the BEGIN block ...");

   chk_members ( 1, find_fish_users(1) );
   chk_members ( 0, Fred::Fish::DBUG::find_all_fish_users () );

   ok3 ( dbug_active_ok_test () );                    # Test # 4

   my $f = DBUG_FILE_NAME ();                         # Test # 5
   ok3 (1, "Fish File: $f");

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

   ok3 (1, "In the MAIN program ...");  # Test # 6 ...

   # -----------------------------------
   # Test # 7 & 8 ...
   # -----------------------------------
   my $msg = "Hello World!\n";
   my $ans = DBUG_PRINT ("INFO", "%s", $msg);
   is2 ($ans, $msg, "The print statement returned the formatted string!");

   $ans = DBUG_PRINT ("INFO", $msg);
   is2 ($ans, $msg, "The print statement returned the formatted string again!");

   # Test # 9 ...
   is2 (test_fish_level(), $start_level, "Level Check");

   DBUG_MODULE_LIST (qw / 0 1 2 3 /);

   helper_tests ();
   is2 (test_fish_level(), $start_level, "Level Check");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# Testing the helper1234 module ...
# -----------------------------------------------

sub helper_tests
{
   my $name = DBUG_ENTER_FUNC (@_);

   my $n = test_func_name_no_warn ($name);
   is2 ($n, $name, "Current function is ==> $name");

   my $lvl = test_fish_level_no_warn (2);
   is2 ($lvl, 2, "Level Check ($lvl)");

   ok3 (1, "is-hires_supported: " . is_hires_supported());
   ok3 (1, "is_threads_supported: " . is_threads_supported());
   ok3 (1, "is_fork_supported: " . is_fork_supported());

   my $cnt = test_mask_return ();
   is2 ($cnt, 0, "There are no masked return values ($cnt)");

   $cnt = test_mask_args ();
   is2 ($cnt, 0, "There are no masked arguments ($cnt)");

   helper_2 ();     # This is where $who points to!

   $lvl = test_fish_level_no_warn (2);
   is2 ($lvl, 2, "Level Check ($lvl)");

   DBUG_VOID_RETURN ();
}

sub helper_2
{
   DBUG_ENTER_FUNC (@_);

   my $who = Fred::Fish::DBUG::dbug_called_by (1, 1);
   ok3 (1, "called by ($who)");

   my $n = Fred::Fish::DBUG::dbug_indent ("?");
   ok3 (1, "Indent string is ($n)");

   DBUG_VOID_RETURN ();
}

