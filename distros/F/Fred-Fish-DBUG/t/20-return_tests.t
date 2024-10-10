#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  20-return_tests.t
# ------------------------------------------------------------------
# This test script validates that DBUG_RETURN() & DBUG_VOID_RETURN()
# Work as advertised!
# ------------------------------------------------------------------

my $start_level;

sub my_warn
{
   ok2 (0, "There were no unexpected warnings!");
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {  # Test # 2
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

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off );

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();

   my $a = ok2 (1, "In the BEGIN block ...");
   ok2 (ok2 ($a, "First Return value check worked!"),
                 "Second Return value check worked!");

   my $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "Begin Block Level Check");

   ok2 ( dbug_active_ok_test () );

   ok2 ( 1, "Fish File: " . DBUG_FILE_NAME () );

   DBUG_VOID_RETURN ();
}

END {
   DBUG_ENTER_FUNC (@_);

   # Can no longer call ok2() in an END block unless it fails!
   my $end_level = test_fish_level ();
   if ( $start_level != $end_level ) {
      ok2 (0, "In the END block ... ($start_level vs $end_level)");
   }

   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   ok2 (1, "In the MAIN block ...");

   my ($res, @lst, $a, $b, $cnt, %h);

   my $lvl = test_fish_level ();

   # --------------------------------------------------------------
   DBUG_PRINT ("----", "The Void Return Tests ...\n%s", '-'x50);
   # --------------------------------------------------------------
   $res = void_return_test_1 ();
   ok2 ( (! defined $res), "Void Return Test # 1 succeeded!");

   $res = void_return_test_2 ();
   ok2 ( (! defined $res), "Void Return Test # 2 succeeded!");

   @lst = void_return_test_2 ();
   ok2 ( ($#lst == -1),    "Void Return Test # 3 succeeded!");

   $res = void_return_test_3 ();
   ok2 ( (! defined $res), "Void Return Test # 4 succeeded!");

   @lst = void_return_test_3 ();
   ok2 ( ($#lst == -1),    "Void Return Test # 5 succeeded!");

   $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "Level 1 check!");

   # --------------------------------------------------------------
   DBUG_PRINT ("----", "The Value Return Tests ...\n%s", '-'x50);
   # --------------------------------------------------------------
   $res = return_scalar_test ();
   is2 ( $res, "scalar",        "Value Return Test # 1 succeeded!");

   @lst = return_scalar_test ();
   ok2 ( ($#lst == 0),          "Value Return Test # 2 succeeded!");
   ok2 ( ($lst[0] eq "scalar"), "Value Return Test # 3 succeeded!");

   $b = return_scalar_test (0);
   ok2 ( $res eq $b, "Value Return Test # 4, masking successful!");

   $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "Level 2 check!");

   # --------------------------------------------------------------
   DBUG_PRINT ("----", "The List Return Tests ...\n%s", '-'x50);
   # --------------------------------------------------------------
   $res = return_list_test_1 ();
   is2 ($res, "a",     "List Return Test # 1 succeeded!");

   @lst = return_list_test_1 ();
   $cnt = @lst;
   is2 ( $cnt, 10,     "List Return Test # 2 succeeded! ($cnt values)");
   ok2 ( ( $lst[0] eq "a" && $lst[1] eq "b" && (! defined $lst[2]) &&
           $lst[3] eq "d" && (!defined $lst[4]) && $lst[5] eq "f" &&
           ref ($lst[6]) eq "HASH" && ref ($lst[7]) eq "ARRAY" &&
           ref ($lst[8]) eq "SCALAR" && ref ($lst[9]) eq "CODE" ),
         "List Return Test # 3 succeeded!" );

   ($a, $b) = return_list_test_1 ();
   ok2 ( ($a eq "a" && $b eq "b"), "List Return Test # 4 - collected 1st 2 vals as scalars!");

   $res = return_list_test_2 ();
   is2 ($res, "a",       "List Return Test # 5 succeeded!");

   @lst = return_list_test_2 ();
   $cnt = @lst;
   ok2 ( $#lst == 6,     "List Return Test # 6 succeeded! ($cnt values)");
   ok2 ( $lst[0] eq "a", "List Return Test # 7 succeeded!");

   ($a, $b) = return_list_test_2 ();
   ok2 ( ($a eq "a" && $b eq "b"), "List Return Test # 8 - collected 1st 2 vals as scalars!");

   my @lst2 = return_list_test_2 (1, 3, 5, 7, 9, 11);
   $cnt = test_mask_return(3);
   ok2 ( compare (\@lst, \@lst2 ), "List Retrun Test # 9 - Masking works OK!" );
   ok2 ( 3 == $cnt, "Masked ${cnt} return values!");

   @lst2 = return_list_test_2 (-1);
   $cnt = test_mask_return(7);
   ok2 ( compare (\@lst, \@lst2 ), "List Retrun Test # 10 - Masking works OK!" );
   ok2 ( 7 == $cnt, "Masked ${cnt} return values!");

   return_list_test_2 (2, 4, 5, 8, 10);
   $cnt = test_mask_return(0);
   ok2 ( 1, "List Return test # 11 - Masking with no return value expected!");
   ok2 ( 0 == $cnt, "Masked ${cnt} return values!");

   $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "Level 3 check!");

   # --------------------------------------------------------------
   DBUG_PRINT ("----", "The Hash Return Tests ...\n%s", '-'x50);
   # --------------------------------------------------------------
   %h = return_hash_test ();
   $a = keys %h;
   $cnt = test_mask_return(0);
   ok2 ( $a == 4, "Hash Return Test # 1 - Collected the right number of entries ($a keys)!");
   ok2 ( 0 == $cnt, "Masked ${cnt} return values!");

   $res = return_hash_test ();
   $cnt = test_mask_return(0);
   ok2 ( exists $h{$res}, "Hash Return Test # 2 - Returned a valid hash key! ($res, $h{$res})!");
   ok2 ( 0 == $cnt, "Masked ${cnt} return values!");

   ($a, $b) = return_hash_test ();
   $cnt = test_mask_return(0);
   ok2 ( exists $h{$a} && $b == $h{$a}, "Hash Return Test # 3 - Returned the 1st key/value pair!");
   ok2 ( 0 == $cnt, "Masked ${cnt} return values!");

   my %h2 = return_hash_test ("BIG", "!", "BIG-FOOT");
   $cnt = test_mask_return(2);
   ok2 (compare_hash (\%h, \%h2), "Hash Return Test # 4 - Masking the hash works OK!");
   ok2 ( 2 == $cnt, "Masked ${cnt} return values!");

   my %h3 = return_hash_test ( -1, "BIG" );
   $cnt = test_mask_return(8);
   ok2 (compare_hash (\%h, \%h3), "Hash Return Test # 5 - Masking everything in the hash works OK!");
   ok2 ( 8 == $cnt, "Masked ${cnt} return values!");

   $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "Level 4 check!");

   # Terminate the test case.
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# Compares 2 arrays ...
# -----------------------------------------------
sub compare
{
   my $one = shift;
   my $two = shift;

   my $cnt = scalar @{$one};
   my $cnt2 = scalar @{$two};
   return (0)  if ( $cnt != $cnt2 );

   foreach ( 0..${cnt} ) {
      if ( ! defined $one->[$_] ) {
         return (0)  if ( defined $two->[$_] );
      } elsif ( ! defined $two->[$_] ) {
         return (0);    # Already know $one's defined!
      } elsif ( $one->[$_] ne $two->[$_] ) {
         return (0);
      }
   }

   return ($cnt);  # The lists were the same!
}

# -----------------------------------------------
# Compares 2 hashes ...
# -----------------------------------------------

sub compare_hash
{
   my $one = shift;
   my $two = shift;

   # Keep sorted to compare key arrays propertly ...
   my @key1 = sort keys %{$one};
   my @key2 = sort keys %{$two};

   # The key list differs ???
   return (0)  unless ( compare (\@key1, \@key2) );

   foreach my $k (@key1) {
      if (! defined $one->{$k} ) {
         return (0)  if ( defined $two->{$k} );
      } elsif ( ! defined $two->{$k} ) {
         return (0);    # Already know $one's value is defined!
      } elsif ( $one->{$k} ne $two->{$k} ) {
         return (0);
      }
   }

   return (1);
}

# -----------------------------------------------
# The void return value test functions ...
# -----------------------------------------------

sub void_return_test_1
{
   DBUG_ENTER_FUNC (@_);

   my $a = 4 + 3;

   DBUG_VOID_RETURN ();
}

sub void_return_test_2
{
   DBUG_ENTER_FUNC (@_);

   my $a = 4 + 3;

   DBUG_RETURN ();
}

sub void_return_test_3
{
   DBUG_ENTER_FUNC (@_);
   my @lst;       # Note: Never initialized array ...
   DBUG_RETURN (@lst);
}

# -----------------------------------------------
# The return a scalar value test function ... 
# -----------------------------------------------

sub return_scalar_test
{
   DBUG_ENTER_FUNC (@_);
   DBUG_MASK (@_);
   DBUG_RETURN ("scalar");
}

# -----------------------------------------------
# The return a list of values test functions ...
# -----------------------------------------------
sub return_list_test_1
{
   DBUG_ENTER_FUNC (@_);
   my (%res1, @res2, $res3);
   DBUG_RETURN ("a", "b", undef, "d", undef, "f", \%res1, \@res2, \$res3, \&return_scalar_test);
}

sub return_list_test_2
{
   DBUG_ENTER_FUNC (@_);
   DBUG_MASK (@_);
   my @res = qw / a b c d e f g /;
   DBUG_RETURN (@res);
}

# -----------------------------------------------
# The return a hash test function ...
# -----------------------------------------------
sub return_hash_test
{
   DBUG_ENTER_FUNC (@_);
   DBUG_MASK (@_);
   my %res = ( BIG => 1, BAD => 2, WOLF => 3, "!" => 4 );
   DBUG_PRINT ("INFO", "The return order of key/value pairs in a hash are undefined in Perl!");
   DBUG_RETURN (%res);
}

