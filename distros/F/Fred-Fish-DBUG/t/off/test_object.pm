#
# A really, really simple object oriented module.
# Also testing special functions ...
#

package test_object;

use strict;
use warnings;

use vars qw ( $VERSION @EXPORT );
use base ( 'Exporter' );

@EXPORT = qw ();
$VERSION = 2.01;

# Always uses the regular module on purpose.
# Using the OFF module breaks sub print()!
use Fred::Fish::DBUG::ON;

# Never call this function in your program!
sub print_phase
{
   Fred::Fish::DBUG::ON::_dbug_print_no_delay_or_caller ("Phase", "%s", ${^GLOBAL_PHASE});
}

sub import
{
   Fred::Fish::DBUG::ON::_dbug_print_no_delay_or_caller ("Import", "%s", ${^GLOBAL_PHASE});
}

# ----------------------------------------------------
# The order the 5 special functions are called in:
# This is regardless of the order defined in this file!
# There can be multiple instances of each of them!
#  1)  BEGIN            START phase
#  2)  UNITCHECK        START phase
#  3)  CHECK            CHECK phase
#  4)  INIT             INIT  phase
#  5)  END              END   phase
# All other functions are called in the RUN phase!
# ----------------------------------------------------

# Called when the module is sourced in ...
BEGIN {
   DBUG_ENTER_FUNC (@_);
   print_phase ();
   DBUG_VOID_RETURN ();
}

# Called right after BEGIN is ...
# Introduced in Perl 5.9.5
UNITCHECK {
   DBUG_ENTER_FUNC (@_);
   print_phase ();
   DBUG_VOID_RETURN ();
}

# Called when the module is sourced in ...
BEGIN {
   DBUG_ENTER_FUNC (@_);
   print_phase ();
   DBUG_VOID_RETURN ();
}

# Called when the module is ????
INIT {
   DBUG_ENTER_FUNC (@_);
   print_phase ();
   DBUG_VOID_RETURN ();
}

# Called when the module is ????
CHECK {
   DBUG_ENTER_FUNC (@_);
   print_phase ();
   DBUG_VOID_RETURN ();
}

# Called when the module goes out of scope ...
END {
   DBUG_ENTER_FUNC (@_);
   print_phase ();
   DBUG_VOID_RETURN ();
}

# --------------------------------------------------------------
# Called when the created object goes out of scope ...
# This special function is just passed a reference to the
# object going out of scope!
# There can only be one of these per module!
# --------------------------------------------------------------
DESTROY {
   DBUG_ENTER_FUNC (@_);
   my $self = shift;
   $self->print ("DESTROY", "Msg = %s", $self->{msg});
   print_phase ();
   DBUG_VOID_RETURN ();
}

# --------------------------------------------------------------
# Another special function caled when you call a non-existant
# function for this class!
# There can only be one of these per module!
# --------------------------------------------------------------
AUTOLOAD {
   DBUG_ENTER_FUNC (@_);
   my $self = shift;
   our $AUTOLOAD;
   $self->print ("AUTOLOAD", "Really Called As = %s ()", $AUTOLOAD);
   print_phase ();
   DBUG_RETURN (1);
}

# -------------------------------------------------------
# Called to create a new object ....
# When the return value goes out of scope, DESTROY
# is called against it.
# -------------------------------------------------------
sub new {
   DBUG_ENTER_FUNC (@_);
   my $self = shift;
   my $type = ref ($self) || $self;
   my $msg = shift;

   my %data;
   $data{msg} = $msg;
   my $obj = \%data;

   bless ( $obj, $type );
   print_phase ();

   DBUG_RETURN ($obj);
}

# -------------------------------------------------------
sub talk {
   DBUG_ENTER_FUNC (@_);
   my $self = shift;
   print_phase ();
   DBUG_RETURN (1);
}

# -------------------------------------------------------
# This method is why we can't use Fred::Fish::DBUG::OFF !!!
# Also didn't use ENTER/RETURN methods on purpose!
# -------------------------------------------------------
sub print {
   my $self = shift;
   my $lbl  = shift;
   my $fmt  = shift;
   my @msg  = @_;

   Fred::Fish::DBUG::ON::_dbug_print_no_delay_or_caller ($lbl, $fmt, @msg);

   return;
}

