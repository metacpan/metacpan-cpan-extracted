#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  62-tie_test.t
# ---------------------------------------------------------------------
# This test script validates that we can trap messages written
# to STDERR & STDOUT and then write them to fish!
# ---------------------------------------------------------------------

my $start_level;
my $global_tie_stderr_flag = 0;
my $global_tie_stdout_flag = 0;
my $fish_paused = 0;
my $fish_disabled;

my ($myok, $myok3);

sub my_warn
{
   $myok3->(0, "There was an expected warning!  Check fish.");
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

   unless (use_ok ( "Fred::Fish::DBUG::TIE" )) {         # Test # 5
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::TIE" );
      exit (0);
  }
}

BEGIN {
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () != 0 ) ? 1 : 0;
   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   my $who_called = 1;
   DBUG_PUSH ( get_fish_log(), off => ${off}, who_called => ${who_called} );

   $myok  = $who_called ? \&ok9 : \&ok2;
   $myok3 = $who_called ? \&ok9 : \&ok3;

   $fish_disabled = $off;

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   $myok->($lvl == $start_level, "In the BEGIN block ...");

   $myok->( dbug_active_ok_test () );

   $myok->( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   # Only call OK if encountering errors!
   # We're not supposed to do any testing in this end block!
   my $lvl = test_fish_level ();
   unless ( $lvl == $start_level ) {
      $myok->(0, "In the END block ...");
   }

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# The start of the MAIN program!
# ----------------------------------------------------------------

{
   DBUG_ENTER_FUNC (@ARGV);

   $myok3->(1, "In the MAIN program ...");

   my $lvl = test_fish_level ();
   $myok->($lvl == $start_level, "MAIN Level Check");

   DBUG_PRINT ("-----", "------------------------------");
   write_stderr_test ();
   DBUG_PRINT ("-----", "------------------------------");
   write_stdout_test ();
   DBUG_PRINT ("-----", "------------------------------");
   write_stdout_missing_test ();
   DBUG_PRINT ("-----", "------------------------------");
   write_pause_test ();
   DBUG_PRINT ("-----", "------------------------------");
   write_both_tests ();
   DBUG_PRINT ("-----", "------------------------------");
   write_nested_tests ();
   DBUG_PRINT ("-----", "------------------------------");

   $lvl = test_fish_level ();
   $myok->($lvl == $start_level, "Last MAIN Level Check");

   done_testing ();

   DBUG_LEAVE (0);
}

# ----------------------------------------------------------------
sub is_fish_on
{
   my $active;

   if ( $fish_disabled ) {
      $active = ! $fish_paused;
   } else {
      $active = DBUG_ACTIVE ();
   }

   return ( $active );
}

sub my_stderr_callback
{
   DBUG_ENTER_FUNC ();
   ++$global_tie_stderr_flag  if ( is_fish_on () );
   DBUG_RETURN (1);
}

sub my_stdout_callback
{
   DBUG_ENTER_FUNC ();
   ++$global_tie_stdout_flag   if ( is_fish_on () );
   DBUG_RETURN (1);
}

sub fish_status {
   my $msg = shift;
   return ( "${msg}  (STDOUT:${global_tie_stdout_flag}, STDERR:${global_tie_stderr_flag})" );
}

sub fish_clear {
   $global_tie_stderr_flag = $global_tie_stdout_flag = 0;
   return (0);
}

# ----------------------------------------------------------------
sub write_stderr_test
{
   DBUG_ENTER_FUNC (@_);

   my ($yes, $no) = ("STDERR is going to fish!", "STDERR is NOT going to fish.");
   my ($y2, $n2) = ("-----> ${yes}", "-----> ${no}");

   fish_clear ();
   print STDERR "${n2}\n";
   $myok->( ! $global_tie_stderr_flag, fish_status($no) );

   DBUG_TIE_STDERR ( \&my_stderr_callback );
   fish_clear ();
   print STDERR "${y2}\n";
   $myok->( $global_tie_stderr_flag, fish_status($yes) );
   DBUG_UNTIE_STDERR ();

   fish_clear ();
   print STDERR "${n2}\n";
   $myok->( ! $global_tie_stderr_flag, fish_status($no) );

   DBUG_TIE_STDERR ( \&my_stderr_callback );
   fish_clear ();
   print STDERR "${y2}\n";
   $myok->( $global_tie_stderr_flag, fish_status($yes) );
   DBUG_UNTIE_STDERR ();

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
sub write_stdout_test
{
   DBUG_ENTER_FUNC (@_);

   my ($yes, $no) = ("STDOUT is going to fish!", "STDOUT is NOT going to fish.");
   my ($y2, $n2) = ("-----> ${yes}", "-----> ${no}");

   fish_clear ();
   print STDOUT "${n2}\n";
   $myok->( ! $global_tie_stdout_flag, fish_status($no) );

   DBUG_TIE_STDOUT ( \&my_stdout_callback );
   fish_clear ();
   print STDOUT "${y2}\n";
   $myok->( $global_tie_stdout_flag, fish_status($yes) );
   DBUG_UNTIE_STDOUT ();

   $global_tie_stderr_flag = $global_tie_stdout_flag = 0;
   print STDOUT "${n2}\n";
   $myok->( ! $global_tie_stdout_flag, fish_status($no) );

   DBUG_TIE_STDOUT ( \&my_stdout_callback );
   fish_clear ();
   print STDOUT "${y2}\n";
   $myok->( $global_tie_stdout_flag, fish_status($yes) );
   DBUG_UNTIE_STDOUT ();

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
sub write_stdout_missing_test
{
   DBUG_ENTER_FUNC (@_);

   my ($yes, $no) = ("STDOUT is going to fish!", "STDOUT is NOT going to fish.");
   my ($y2, $n2) = ("-----> ${yes}", "-----> ${no}");

   fish_clear ();
   print "${n2}\n";
   $myok->( ! $global_tie_stdout_flag, fish_status($no) );

   DBUG_TIE_STDOUT ( \&my_stdout_callback );
   fish_clear ();
   print "${y2}\n";
   $myok->( $global_tie_stdout_flag, fish_status($yes) );
   DBUG_UNTIE_STDOUT ();

   fish_clear ();
   print "${n2}\n";
   $myok->( ! $global_tie_stdout_flag, fish_status($no) );

   DBUG_TIE_STDOUT ( \&my_stdout_callback );
   fish_clear ();
   print "${y2}\n";
   $myok->( $global_tie_stdout_flag, fish_status($yes) );
   DBUG_UNTIE_STDOUT ();

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
sub write_pause_test
{
   DBUG_ENTER_FUNC (@_);

   DBUG_PAUSE ();

   # So the callbacks will work correctly when fish is off!
   $fish_paused = 1;

   my $no = "Nothing goes to fish ...";
   my $n2 = "-----> ${no}";

   fish_clear ();
   print "${n2}\n";
   $myok->( ! $global_tie_stdout_flag, fish_status($no) );

   DBUG_TIE_STDOUT ( \&my_stdout_callback );
   fish_clear ();
   print "${n2}\n";
   $myok->( ! $global_tie_stdout_flag, fish_status($no) );
   DBUG_UNTIE_STDOUT ();

   $fish_paused = 0;

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
sub write_both_tests
{
   DBUG_ENTER_FUNC (@_);

   my ($yes, $no) = ("STDOUT and STDERR are both going to fish!", "Neither STDOUT nor STDERR are going to fish.");
   my ($y2, $n2) = ("-----> ${yes}", "-----> ${no}");

   fish_clear ();
   print "${n2}\n";
   print STDERR "${n2}\n";
   $myok->( $global_tie_stderr_flag == 0 && $global_tie_stdout_flag == 0, fish_status($no));

   DBUG_TIE_STDERR ( \&my_stderr_callback );
   DBUG_TIE_STDOUT ( \&my_stdout_callback );

   my $fail = fish_clear ();

   print "${y2}\n";
   $fail = 1  unless ( $global_tie_stdout_flag == 1 && $global_tie_stderr_flag == 0 );
   print STDERR "${y2}\n";
   $fail = 1  unless ( $global_tie_stdout_flag == 1 && $global_tie_stderr_flag == 1 );
   $myok->( ! $fail, fish_status($yes) );

   DBUG_UNTIE_STDERR ();
   DBUG_UNTIE_STDOUT ();

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
sub write_nested_tests
{
   DBUG_ENTER_FUNC (@_);

   my $fail = fish_clear ();

   DBUG_TIE_STDOUT ( \&my_stdout_callback );
   myTieTest::tie_stdout ();
   DBUG_TIE_STDOUT ( \&my_stdout_callback, 0, 1 );

   print STDOUT "----->Did we write to fish three times?\n";
   $fail = 1  unless ( $global_tie_stdout_flag == 3 && $global_tie_stderr_flag == 0 );
   $myok->( ! $fail, "Did we write to fish three times?" . fish_status (""));

   DBUG_UNTIE_STDOUT ();

   $fail = fish_clear ();

   print STDOUT "----->We didn't write to fish?\n";
   $fail = 1  unless ( $global_tie_stdout_flag == 0 && $global_tie_stderr_flag == 0 );
   $myok->( ! $fail, "We didn't write to fish?" . fish_status (""));

   DBUG_VOID_RETURN ();
}

#------------------------------------------------------------------------------
# A local TIE example.
# Demonstrates I can tie & chain STDOUT multiple times in my test cases.
# Just shows that DBUG_TRAP_STDERR() overrides tie_stsdout()!
# But I have no idea on how to make the chained tie the main one again after
# untying it.
#-----------------------------------------------------------------------------
package myTieTest;

use strict;
use warnings;

use Fred::Fish::DBUG;

sub tie_stdout
{
   my $hd;
   my $sts = open ( $hd, '>&', *STDOUT );

   my $t = tied (*STDOUT) || "";
   DBUG_PRINT ("CHAIN-TIE", "Tying Stdout via test function: %s", $t);

   if ( $sts ) {
      my $h = tie ( *STDOUT, __PACKAGE__, $hd, $t );
      $sts = ( ref ($h) eq __PACKAGE__ );
   }
   return ($sts);
}

sub TIEHANDLE {
   my $class = shift;    # Should be __PACKAGE__ ...
   my $which = shift;    # The file handle to write to.
   my $pkg   = shift;    # Package to forward to.

   my $self = bless ( { myfh => $which, mychain => $pkg }, $class );

   return ( $self );
}

sub PRINT {
   my $self = shift;
   my @args = @_;

   # Would prove this PRINT was called!
   DBUG_PRINT ( "STDCHAIN", "%s", join ("", @args) );

   my $sts;
   if ( $self->{mychain} && $self->{mychain}->can ("PRINT") ) {
      $sts = $self->{mychain}->PRINT (@args);

   } elsif ( $self->{myfh} ) {
      my $fh = $self->{myfh};
      $sts = print $fh @args;

   } else {
      DBUG_PRINT ("???", "Mising key myfh for PRINT!");
   }

   # So the call gets counted in the tests above ...
   $sts = main::my_stdout_callback ( @args )   if ( $sts );


   return ( $sts );
}

