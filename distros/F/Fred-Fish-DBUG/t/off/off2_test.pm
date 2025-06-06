##
## Stub to demo the mixture of Fred::Fish::DBUG::ON & Fred::Fish::DBUG::OFF
## modules being used in the same Perl program.
##

package off2_test;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Fred::Fish::DBUG::OFF;
use Fred::Fish::DBUG::Signal;
use Fred::Fish::DBUG::Test;
use helper1234;

$VERSION = "2.09";
@ISA = qw( Exporter );

@EXPORT = qw( OFF2_FILE OFF2_BAD_SIGNAL OFF2_PRINT1 OFF2_PRINT2 OFF2_WARN_TEST );

@EXPORT_OK = qw( );

BEGIN
{
  my $mod = get_fish_module (__FILE__);
  dbug_ok ($mod =~ m/::Unknown$/,
           "Loaded ${mod} via Fred::Fish::DBUG::OFF in " . __PACKAGE__); 
}

END
{
}

sub OFF2_FILE
{
   return ( __FILE__ );
}

my $total = 0;
sub my_off_signal_func
{
   DBUG_ENTER_FUNC (@_);
   dbug_ok (1, "Signal Trapped in: off_test::my_off_signal_func! (" . ++$total . ")");
   DBUG_VOID_RETURN ();
}

sub OFF2_BAD_SIGNAL
{
   DBUG_ENTER_FUNC (@_);

   my $res = DBUG_TRAP_SIGNAL ("BAD+INT");

   $res = DBUG_TRAP_SIGNAL ("INT", DBUG_SIG_ACTION_LOG, "my_off_signal_func");

   DBUG_VOID_RETURN ();
}

sub OFF2_PRINT1
{
   DBUG_ENTER_FUNC (@_);

   DBUG_PRINT ("INFO", "Hello World!");
   DBUG_PRINT ("INFO", "How are you?");

   dbug_ok (1, "In OFF module - Func 1!");

   DBUG_FILTER ( DBUG_FILTER_LEVEL_ERROR );

   DBUG_PRINT ("INFO", "Shouldn't print since filtered out!");

   DBUG_VOID_RETURN ();
}

sub OFF2_PRINT2
{
   DBUG_ENTER_FUNC (@_);

   DBUG_FILTER ( DBUG_FILTER_LEVEL_OTHER );

   DBUG_PRINT ("INFO", "Good Bye Cruel World!");
   DBUG_PRINT ("INFO", "I hope you're satisfied now!");

   dbug_ok (1, "In OFF module - Func 2!");

   DBUG_RETURN ("a", "b", "c", "d", "e");
}

sub local_warn_trap
{
   chomp (my $msg = shift);
   dbug_ok (1, $msg);
}

sub OFF2_WARN_TEST
{
   DBUG_ENTER_FUNC (@_);
   my ($action, @funcs) = DBUG_FIND_CURRENT_TRAPS ("__WARN__");
   DBUG_TRAP_SIGNAL ("__WARN__", DBUG_SIG_ACTION_LOG, \&local_warn_trap);
   warn ("Trapping warning in OFF2_WARN_TEST!");
   DBUG_TRAP_SIGNAL ("__WARN__", $action, @funcs);
   DBUG_VOID_RETURN ();
}

# ============================================================
#required if module is included w/ require command;
1;

