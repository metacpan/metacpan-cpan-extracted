##
## Stub to demo the mixture of Fred::Fish::DBUG::ON & Fred::Fish::DBUG::OFF
## modules being used in the same Perl program.
##

package on_test;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Fred::Fish::DBUG  qw / ON /;
use Fred::Fish::DBUG::Signal;
use helper1234;

$VERSION = "2.03";
@ISA = qw( Exporter );

@EXPORT = qw( ON_FILE ON_BAD_SIGNAL ON_PRINT1 ON_PRINT2 ON_WARN_TEST );

@EXPORT_OK = qw( );

BEGIN
{
   my $mod = get_fish_module (__FILE__);
   ok2 ($mod =~ m/::ON$/,
        "Loaded ${mod} via Fred::Fish::DBUG qw / ON / in " . __PACKAGE__);
}

END
{
}

sub ON_FILE
{
   return ( __FILE__ );
}

sub ON_BAD_SIGNAL
{
   DBUG_ENTER_FUNC (@_);

   my $res = DBUG_TRAP_SIGNAL ("BAD");

   DBUG_VOID_RETURN ();
}

sub ON_PRINT1
{
   DBUG_ENTER_FUNC (@_);

   DBUG_PRINT ("INFO", "Hello World!");
   DBUG_PRINT ("INFO", "How are you?");

   ok2 (1, "In ON module Func 1");

   DBUG_FILTER ( DBUG_FILTER_LEVEL_WARN );

   DBUG_PRINT ("INFO", "Shouldn't print since filtered out!");

   DBUG_VOID_RETURN ();
}

sub ON_PRINT2
{
   DBUG_ENTER_FUNC (@_);

   DBUG_FILTER ( DBUG_FILTER_LEVEL_INTERNAL );

   DBUG_PRINT ("INFO", "Good Bye Cruel World!");
   DBUG_PRINT ("INFO", "I hope you're satisfied now!");

   ok2 (1, "In ON module Func 2");

   DBUG_RETURN ("a", "b", "c", "d", "e");
}

sub local_warn_trap
{
   chomp (my $msg = shift);
   ok2 (1, $msg);
}

sub ON_WARN_TEST
{
   DBUG_ENTER_FUNC (@_);
   my ($action, @funcs) = DBUG_FIND_CURRENT_TRAPS ("__WARN__");
   DBUG_TRAP_SIGNAL ("__WARN__", DBUG_SIG_ACTION_LOG, \&local_warn_trap);
   warn ("Trapping warning in ON_WARN_TEST!");
   DBUG_TRAP_SIGNAL ("__WARN__", $action, @funcs);
   DBUG_VOID_RETURN ();
}

# ============================================================
#required if module is included w/ require command;
1;

