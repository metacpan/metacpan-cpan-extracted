#!/user/bin/perl

# Program:  15-basic-test-and-helper.t
#    Tests out the Fred-Fish-DBUG-Test module that is central to running the
#    remaining test cases!
#    Also tests out helper1234.pm which is central to to setting up the
#    environment for the remainder of the tests!
#    It uses $ENV{FISH_OFF_FLAG} to control this logic & other common
#    initialization!

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

my $start_level;

sub my_warn
{
   done_testing ();
   BAIL_OUT ( "An Unexpected Warning was trapped!");
   exit (0);
}
# BEGIN { $ENV{FISH_OFF_FLAG} = -1; }

BEGIN {
   unless (use_ok ("Fred::Fish::DBUG::Test")) {
      done_testing ();
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Test" );
      exit (0);
   }
   dbug_ok (1, "use Fred::Fish::DBUG::Test");   # Test # 1
}

BEGIN {
   # Can't use any of the constants or funcs defined by this module
   # unless we use them in a separate BEGIN block!

   push (@INC, File::Spec->catdir (".", "t", "off"));

   # Helper module makes sure DIE & WARN traps are set ...
   unless (use_ok ("helper1234")) {
      dbug_BAIL_OUT ("Can't load helper1234");
   }
   dbug_ok (1, "use helper1234");   # Test # 2
}

BEGIN {
   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   my %usr1 = find_fish_users ();
   my $cnt1 = keys %usr1;
   dbug_cmp_ok ($cnt1, "==", 1, "Found correct # of files listed.");

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {      # Test # 2
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
                      join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Used options qw / " . join (" ", @opts) . " /" );

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }

   my %usr2 = Fred::Fish::DBUG::find_all_fish_users ();
   my $cnt2 = keys %usr2;
   dbug_cmp_ok ($cnt2, "==", 2, "Found correct # of files listed.");
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
      dbug_ok (1, "Helper list of users of module");
      diag (@msgs);
      my $unk = Fred::Fish::DBUG::_find_module ("IGNORE-ME2");
   } else {
      dbug_ok (1, "Local list of users of module");
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

   DBUG_PUSH ( get_fish_log(), off => $off ); my $lvl = ( $sts == -1 ) ? -1 : 1;

   DBUG_ENTER_FUNC ();

   # Test # 3 ...
   $start_level = test_fish_level ();
   dbug_is ($start_level, $lvl, "Level Check In the BEGIN block ...");

   chk_members ( 1, find_fish_users(1) );
   chk_members ( 0, Fred::Fish::DBUG::find_all_fish_users () );

   dbug_ok ( dbug_active_ok_test () );                    # Test # 4

   my $f = DBUG_FILE_NAME ();
   dbug_ok (1, "Fish File: $f");

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   # Can no longer call dbug_ok() in an END block unless it fails!

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

   dbug_ok (1, "In the MAIN program ...");  # Test # 6 ...

   my $p = run_test_funcs_pass ();

   if ( 0  ) {
      my $f = run_test_funcs_fail ();

      dbug_BAIL_OUT ("After failure tests");
   }

   # -----------------------------------
   # Test # 7 & 8 ...
   # -----------------------------------
   my $msg = "Hello World!\n";
   my $ans = DBUG_PRINT ("INFO", "%s", $msg);
   dbug_is ($ans, $msg, "The print statement returned the formatted string!");

   $ans = DBUG_PRINT ("INFO", $msg);
   dbug_is ($ans, $msg, "The print statement returned the formatted string again!");

   # Test # 9 ...
   dbug_is (test_fish_level(), $start_level, "Level Check");

   DBUG_MODULE_LIST (qw / 0 1 2 3 /);

   helper_tests ();
   dbug_is (test_fish_level(), $start_level, "Level Check");

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
   dbug_is ($n, $name, "Current function is ==> $name");

   my $lvl = test_fish_level_no_warn (2);
   dbug_is ($lvl, 2, "Level Check ($lvl)");

   dbug_ok (1, "is-hires_supported: " . is_hires_supported());
   dbug_ok (1, "is_threads_supported: " . is_threads_supported());
   dbug_ok (1, "is_fork_supported: " . is_fork_supported());

   my $cnt = test_mask_return ();
   dbug_is ($cnt, 0, "There are no masked return values ($cnt)");

   $cnt = test_mask_args ();
   dbug_is ($cnt, 0, "There are no masked arguments ($cnt)");

   helper_2 ();     # This is where $who points to!

   $lvl = test_fish_level_no_warn (2);
   dbug_is ($lvl, 2, "Level Check ($lvl)");

   DBUG_VOID_RETURN ();
}

sub helper_2
{
   DBUG_ENTER_FUNC (@_);

   my $who = Fred::Fish::DBUG::dbug_called_by (1, 1);
   dbug_ok (1, "called by ($who)");

   my $n = Fred::Fish::DBUG::dbug_indent ("?");
   dbug_ok (1, "Indent string is ($n)");

   DBUG_VOID_RETURN ();
}

sub run_test_funcs_pass
{
   DBUG_ENTER_FUNC (@_);

   my @ans;

   push (@ans, dbug_ok ( 1, "Basic OK Test" ));

   push (@ans, dbug_is ( 2, 2, "Basic is number test" ));
   push (@ans, dbug_is ( 'a', 'a', "Basic is character test" ));
   push (@ans, dbug_is ( undef, undef, "Basic is undef test" ));

   push (@ans, dbug_isnt ( 2, 3, "Basic isn't same number test" ));
   push (@ans, dbug_isnt ( 'a', 'b', "Basic isn't same character test" ));
   push (@ans, dbug_isnt ( undef, 22, "Basic isn't undef test" ));

   push (@ans, dbug_like ("Testing 1234.", qr/1234/, "Basic like test"));
   push (@ans, dbug_unlike ("Testing 2468.", qr/1234/, "Basic unlike test"));

   push (@ans, dbug_cmp_ok ( 12, "==", 12, "Numeric equals test" ));
   push (@ans, dbug_cmp_ok ( 12, "!=", 21, "Numeric not equal test" ));
   push (@ans, dbug_cmp_ok ( "A", "eq", "A", "String equals test" ));
   push (@ans, dbug_cmp_ok ( "a", "ne", "A", "String not equal test" ));

   push (@ans, dbug_can_ok ("Fred::Fish::DBUG::Test", "dbug_ok", "dbug_like"));

   push (@ans, dbug_isa_ok ( \@_, "ARRAY" ));

   # Tested in;   t/42-func_who_called-trace.t
   # my $obj = dbug_new_ok ( $class );
   # push (@array, defined $obj);

   my $res = 1;
   foreach (@ans) {
      $res = ( $res && $_ ) ? 1 : 0;
   }

   DBUG_RETURN ( $res );    # All passed?  Bug if not true!
}

sub run_test_funcs_fail
{
   DBUG_ENTER_FUNC (@_);

   my @ans;
   my $fail = "test should fail";

   push (@ans, dbug_ok (0, "Basic ok $fail"));

   push (@ans, dbug_is ( 2, 3, "Basic is number $fail" ));
   push (@ans, dbug_is ( 'a', 'b', "Basic is character $fail" ));
   push (@ans, dbug_is ( undef, 22, "Basic is undef $fail" ));

   push (@ans, dbug_isnt ( 2, 2, "Basic isn't same number $fail" ));
   push (@ans, dbug_isnt ( 'a', 'a', "Basic isn't same character $fail" ));
   push (@ans, dbug_isnt ( undef, undef, "Basic isn't undef $fail" ));

   push (@ans, dbug_like ("Testing 2468.", qr/1234/, "Basic like $fail"));
   push (@ans, dbug_unlike ("Testing 1234.", qr/1234/, "Basic unlike $fail"));

   push (@ans, dbug_cmp_ok ( 12, "==", 21, "Numeric equals $fail" ));
   push (@ans, dbug_cmp_ok ( 12, "!=", 12, "Numeric not equal $fail" ));
   push (@ans, dbug_cmp_ok ( "a", "eq", "A", "String equals $fail" ));
   push (@ans, dbug_cmp_ok ( "A", "ne", "A", "String not equal $fail" ));

   push (@ans, dbug_can_ok ("Fred::Fish::DBUG::Test", "dbug_ok", "dbug_like", "failure23"));

   push (@ans, dbug_isa_ok ( \@_, "ARRAYx" ));

   # my $obj = dbug_new_ok ( $class );
   # push (@array, ! defined $obj);

   my $res = 0;
   foreach (@ans) {
      $res = ( $res || $_ ) ? 1 : 0;
   }

   DBUG_RETURN ( ! $res );    # All failed?  Bug if not true!
}
