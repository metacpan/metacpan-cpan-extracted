###
###  Copyright (c) 2016 - 2024 Curtis Leach.  All rights reserved.
###
###  Based on the Fred Fish DBUG macros in C/C++.
###  The Algorithm is in the public domain!
###
###  Module: Fred::Fish::DBUG::OFF

=head1 NAME

Fred::Fish::DBUG::OFF - Fred Fish Stub library for Perl

=head1 SYNOPSIS

  use Fred::Fish::DBUG  qw / OFF /;
    or
  require Fred::Fish::DBUG;
  Fred::Fish::DBUG->import (qw / OFF /);

 Depreciated way.
   use Fred::Fish::DBUG::OFF;
     or
   require Fred::Fish::DBUG::OFF;

=head1 DESCRIPTION

F<Fred::Fish::DBUG::OFF> is a pure Perl implementation of the C/C++ Fred Fish
macro libraries when the macros are B<turned off>!  It's intended to be a pure
drop and replace to the F<Fred::Fish::DBUG::ON> module so that any module that
is uploaded to CPAN doesn't have to have their module code writing to B<fish>
when used by an end user's program that also uses the F<Fred::Fish::DBUG>
module.

Using this module directly has been depreciated.  You should be using
F<Fred::Fish::DBUG> instead.  See that module on how to disable B<fish> for your
module.

When B<fish> has ben disabled (turned off) most of the functions are overridden
with stubs or do minimal work to avoid breaking your code that depend on side
effects.  But overall this module does as little work as possible.

The undocumented validation methods used by the B<t/*.t> test cases don't work
for F<Fred::Fish::DBUG::OFF>.  So those test scripts must detect that these
undocumented functions are broken and handle any checks appropriately.

=head1 FUNCTIONS IN Fred::Fish::DBUG BUT NOT IN Fred::Fish::DBUG::OFF.

There are several functions listed in the POD of the 1st module that doesn't
show up in the POD of the 2nd module.

This was by design.  All the missing functions do is automatically call the
corresponding function in L<Fred::Fish::DBUG::ON> for you.  Since this module
inherits the missing functions from L<Fred::Fish::DBUG::ON>.

The exposed constants falls into this category so your code won't break
when swapping between the two modules in the same program.

So feel free to always reference the POD from L<Fred::Fish::DBUG> and/or
L<Fred::Fish::DBUG:::ON> when using any of the DBUG modules.

=head1 SWAPPING BETWEEN FISH MODULES

There is a fairly simple way to have B<fish> available when you run your test
suite and have it always disabled when an end user runs code using your module.
this is done via:

  use Fred::Fish::DBUG qw / on_if_set FISH /;

This way your module will only use B<fish> if someone sets this environment
variable (Ex: B<FISH>) before your module is sourced in.  Such as in your test
scripts when you are debugging your code.  When anyone else uses your module it
won't write to the B<fish> logs at all, even if they are also using the
B<DBUG> module in their code base.  In most cases they are not interested in
seeing traces of your module.

Another reason for doing this is that this module is significantly faster
when run in OFF mode than when run in the ON mode.  This is true even when
logging is turned off.  The more your module writes to B<fish>, the better the
performance gain.

=head1 FUNCTIONS

=over 4

=cut 

package Fred::Fish::DBUG::OFF;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use FileHandle;

$VERSION = "2.06";
@ISA = qw( Exporter );
@EXPORT = qw( );
@EXPORT_OK = qw( );

my (@imports, @override);

BEGIN
{
   # -------------------------------------------------------------------------
   # Put the list of methods we are overriding via the OFF module!
   # Anything missing will just call the same method in Fred::Fish::DBUG::ON
   # instead!  (Such as all those pesky exposed constant values.)
   # -------------------------------------------------------------------------
   @override = qw( DBUG_PUSH          DBUG_POP
                   DBUG_ENTER_FUNC    DBUG_ENTER_BLOCK    DBUG_PRINT
                   DBUG_RETURN        DBUG_ARRAY_RETURN
                   DBUG_VOID_RETURN   DBUG_RETURN_SPECIAL
                   DBUG_LEAVE         DBUG_CATCH          DBUG_PAUSE
                   DBUG_MASK          DBUG_MASK_NEXT_FUNC_CALL
                   DBUG_FILTER        DBUG_SET_FILTER_COLOR
                   DBUG_CUSTOM_FILTER DBUG_CUSTOM_FILTER_OFF
                   DBUG_ACTIVE        DBUG_EXECUTE
                   DBUG_FILE_NAME     DBUG_FILE_HANDLE    DBUG_ASSERT
                   DBUG_MODULE_LIST
                 );

   my %list;
   @list{@override} = (1 .. scalar(@override));

   # Now load the module & only expose the remaining methods & constants.
   require Fred::Fish::DBUG::ON;
   @imports = grep { ! $list{$_} } @Fred::Fish::DBUG::ON::EXPORT;
   Fred::Fish::DBUG::ON->import (@imports);
}


# Now finish off exporting everything initialized by the above BEGIN block ...
push (@EXPORT, @override);   # Locally defined routines ...
push (@EXPORT, @imports);    # From Fred::Fish::DBUG::ON ...


# These hash variables holds all the global variables used by this module.
my %dbug_off_global_vars;     # The current fish frame ...
my %dbug_off_return_vars;     # How DBUG_RETURN behaves for the given package.


# --------------------------------
BEGIN
{
   # Other variables used ...
   $dbug_off_global_vars{mask_return_count} = 0;
   $dbug_off_global_vars{mask_last_argument_count} = 0;
   $dbug_off_global_vars{mask_func_call} = 0;
   $dbug_off_global_vars{mask_return_flag} = 0;
   $dbug_off_global_vars{main} = Fred::Fish::DBUG::ON::MAIN_FUNC_NAME;
}


# --------------------------------
# DBUG::OFF Code
# 
# I have tried to keep the functions in in the same order as listed in
# Fred::Fish::DBUG::ON to make it easier to support this stub version of
# this module.
#
# But if I skip over a function, it will mean that I used the function
# from Fred::Fish::DBUG::ON instead!
# --------------------------------

=item DBUG_PUSH ( [$file [, %opts]] )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_PUSH
{
   return;
}


=item DBUG_POP ( )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_POP
{
   return;
}


=item DBUG_ENTER_FUNC ( [@arguments] )

This stub just returns the name of the calling function.  It won't honor the
I<strip> option in the return value.

=cut

# ==============================================================
sub DBUG_ENTER_FUNC
{
   my $func = (caller (1))[3] || $dbug_off_global_vars{main};

   return ( DBUG_ENTER_BLOCK ($func, @_) );
}


=item DBUG_ENTER_BLOCK ( $name [, @arguments] )

This stub just returns the B<$name> passed to it.  It won't honor the
I<strip> option in the return value.

=cut

# ==============================================================
sub DBUG_ENTER_BLOCK
{
   my $block_name = shift;
   my @args       = @_;

   $block_name = "[undef]"  unless ( defined $block_name );

   # Did we make a masking request ...
   if ( $dbug_off_global_vars{mask_func_call} ) {
      $dbug_off_global_vars{mask_last_argument_count} = ($#args == -1) ? 0 : -1;
      $dbug_off_global_vars{mask_func_call} = 0;
   } else {
      $dbug_off_global_vars{mask_last_argument_count} = 0;   # Nope!
   }

   return ( $block_name );
}


=item DBUG_PRINT ( $tag, $fmt [, $val1 [, $val2 [, ...]]] )

This function is usually a no-op unless you are examining the return value.
In that case it will return the formatted string the same as it does for
I<Fred::Fish::DBUG::ON::DBUG_PRINT>.

It also doesn't honor the B<delay> request from I<DBUG_PUSH> since it will
never write to the B<fish> file.

=cut

# ==============================================================
# Make as efficient as possible since this is the most frequently called method!
# And usually the return value is tossed!
# ------------------------------------------------------------------
sub DBUG_PRINT
{
   # If undef, the caller wasn't interested in any return value!
   return (undef)  unless ( defined wantarray );

   my ($keyword, $fmt, @values) = @_;

   # Build the message that we want to return.
   my $msg;
   if ( ! defined $fmt ) {
      $msg = "";
   } elsif ( $#values == -1 ) {
      $msg = $fmt;
   } else {
      # Get rid of undef warnings for sprintf() ...
      foreach (@values) {
         $_ = ""   unless ( defined $_ );
      }
      $msg = sprintf ( $fmt, @values );
   }

   my @lines = split ( /[^\S\n]*\n/, $msg );  # Split on "\n" & trim!
   push (@lines, "")   if ( $#lines == -1 );  # Must have at least one line!
   $msg = join ( "\n", @lines ) . "\n";       # Put back together trimmed!

   return ( $msg );     # Here's the requested formatted message ...
}


=item DBUG_RETURN ( ... )

Returns the parameter(s) passed as arguments back to the calling function.
Since this is a function, care should be taken if called from the middle of
your function's code.  In that case use the syntax:
S<"return DBUG_RETURN( value1 [, value2 [, ...]] );">.

It uses Perl's B<wantarray> feature to determine what to return the the caller.
IE scalar mode (only the 1st value) or list mode (all the values in the list).
Which is not quite what many perl developers might expect.

EX: return (wantarray ? (value1, value2, ...) ? value1);

=cut

# ==============================================================
sub DBUG_RETURN
{
   my @args = @_;

   # Did we request masking ...
   my $flg = $dbug_off_global_vars{mask_return_flag};
   $dbug_off_global_vars{mask_return_count} = $flg ? -1 : 0;
   $dbug_off_global_vars{mask_return_flag} = 0;

   if ( wantarray ) {
      return ( @args );        # Array context ...
   } else {
      return ( $args[0] );     # Scalar/void context ...
   }
}

=item DBUG_ARRAY_RETURN ( @args )

A variant of S<"DBUG_RETURN()"> that behaves the same as perl does natively when
returning a list to a scalar.  IE it returns the # of elements in the @args
array.

It always assumes @args is a list, even when provided a single scalar value.

=cut

# ==============================================================
sub DBUG_ARRAY_RETURN
{
   my @args = @_;

   # Did we request masking ...
   my $flg = $dbug_off_global_vars{mask_return_flag};
   $dbug_off_global_vars{mask_return_count} = $flg ? -1 : 0;
   $dbug_off_global_vars{mask_return_flag} = 0;

   # I can't tell apart DBUG_ARRAY_RETURN("a") & DBUG_ARRAY_RETURN(qw/a/)
   # so always assume 2nd example if arg count is 1.
   # my $cnt = @args;

   # Let Perl handle the mess of returning a list or a count,
   return ( @args );
}

=item DBUG_VOID_RETURN ( )

Just a void return stub.  If called in the middle of your function, do as:
S<"return DBUG_VOID_RETURN();">.

=cut

# ==============================================================
sub DBUG_VOID_RETURN
{
   # Nothing masked ...
   $dbug_off_global_vars{mask_return_count} = 0;
   $dbug_off_global_vars{mask_return_flag} = 0;
   return (undef);   # Undef just in case someone looks!
}


=item DBUG_RETURN_SPECIAL ( $scalar, @array )

This I<DBUG_RETURN> variant allows you to differentiate between what to return
when your function is called in a scalar context vs an array context vs void
context.

If called in an array context, the return value is equivalent to
S<I<DBUG_RETURN (@array)>.>

If called in a scalar context, the return value is equivalent to
S<I<DBUG_RETURN ($scalar)>.>  With a few special case exceptions.

=over

Special case # 1: If I<$scalar> is set to the predefined constant value
B<DBUG_SPECIAL_ARRAYREF>, it returns the equivalent to
S<I<DBUG_RETURN (\@array)>.> Feel free to modify the contents of the referenced
array, it can't hurt anything.  It's a copy.

Special case # 2: If I<$scalar> is set to the predefined constant value
B<DBUG_SPECIAL_COUNT>, it returns the equivalent to
S<I<DBUG_RETURN (scalar (@array))>,> the number of elements in the array.

Special case # 3: If I<$scalar> is set to the predefined constant value
B<DBUG_SPECIAL_LAST>, it returns the equivalent to
S<I<DBUG_RETURN ($array[-1])>,> the last element in the array.

Special case # 4: If I<$scalar> is a CODE ref, it returns the equivalent to
S<I<DBUG_RETURN (scalar ($scalar-E<gt>(@array)))>.>

=back

If called in a void context, the return value is equivalent to
S<I<DBUG_VOID_RETURN ()>.>

=cut

sub DBUG_RETURN_SPECIAL
{
   my $scalar = shift;

   # Did we request masking ...
   my $flg = $dbug_off_global_vars{mask_return_flag};
   $dbug_off_global_vars{mask_return_count} = $flg ? -1 : 0;
   $dbug_off_global_vars{mask_return_flag} = 0;

   unless ( defined wantarray ) {
      return ( undef );
   } elsif  ( wantarray ) {
      return ( @_ );
   }

   # If you get here you are returning a scalar value ...
   if ( defined $scalar ) {
      if ( ref ($scalar) eq "CODE" ) {
         my $res = $scalar->( @_ );
         return ( $res );
      } elsif ( $scalar eq DBUG_SPECIAL_ARRAYREF ) {
         my @args = @_;
         return ( \@args );
      } elsif ( $scalar eq DBUG_SPECIAL_COUNT ) {
         return ( scalar (@_) );
      } elsif ( $scalar eq DBUG_SPECIAL_LAST ) {
         return ( $_[-1] );
      }
   }

   # Returning a literal value, not one of the exceptions ...
   return ( $scalar );
}


=item DBUG_LEAVE ( [$status] )

This function terminates your program with a call to I<exit()>.  It expects a
numeric parameter to use as the program's I<$status> code.  If not provided,
it assumes an exit status of zero!

=cut

# ==============================================================
sub DBUG_LEAVE
{
   my $status = shift || 0;

   Fred::Fish::DBUG::ON::_dbug_leave_cleanup ();

   exit ($status);        # Exit the program!  (This isn't trappable by eval!)
}


=item DBUG_CATCH ( )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_CATCH
{
   return;
}

=item DBUG_PAUSE ( )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_PAUSE
{
   return;
}


=item DBUG_MASK ( @offsets )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_MASK
{
   $dbug_off_global_vars{mask_return_flag} = 1;
   return;
}


=item DBUG_MASK_NEXT_FUNC_CALL ( @offsets )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_MASK_NEXT_FUNC_CALL
{
   $dbug_off_global_vars{mask_func_call} = 1;
   return;
}


=item DBUG_FILTER ( $lvl )

This stub does nothing except return the current I<level> and
the passed I<$lvl>.  You can't change the level while using
this module.

=cut

# ==============================================================
sub DBUG_FILTER
{
   my $new_lvl = shift;

   my $old_lvl = Fred::Fish::DBUG::ON::DBUG_FILTER ();
   return ( wantarray ? ( $old_lvl, $new_lvl ) : $old_lvl );
}


=item DBUG_CUSTOM_FILTER ( @levels )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_CUSTOM_FILTER
{
   return;
}


=item DBUG_CUSTOM_FILTER_OFF ( @levels )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_CUSTOM_FILTER_OFF
{
   return;
}


=item DBUG_SET_FILTER_COLOR ( $level [, $color] )

This stub always returns B<0> since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_SET_FILTER_COLOR
{
   return (0);
}


=item DBUG_ACTIVE ( )

This stub always returns B<0> since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_ACTIVE
{
   return (0);    # Fish is always turned off.
}


=item DBUG_EXECUTE ( $tag )

This function always returns B<0> since B<fish> can't be turned on for this
module.

=cut

# ==============================================================
sub DBUG_EXECUTE
{
   return (0);    # Fish is always turned off.
}


=item DBUG_FILE_NAME ( )

Always returns the empty string since B<fish> can't be turned on for this
module.

=cut

# ==============================================================
sub DBUG_FILE_NAME
{
   return ("");    # Fish is always turned off.
}


=item DBUG_FILE_HANDLE ( )

Always returns B<undef> since B<fish> is never turned on with this module.

=cut;

# ==============================================================
sub DBUG_FILE_HANDLE
{
   return (undef);
}


=item DBUG_ASSERT ( $expression [, $always_on [, $msg]] )

This function works similar to the C/C++ I<assert> function except that it
can't tell you what the boolean expression was.

This function is a no-op unless I<$always_on> is true.

So if the I<$expression> is false, and I<$always_on> is true, it will write to
B<STDERR> the assert message and abort your program with an exit status code of
B<14>.  Meaning this exit can't be trapped by I<eval>.

=cut

# ==============================================================
sub DBUG_ASSERT
{
   my $bool      = shift;
   my $always_on = shift;
   my $msg       = shift;

   return  if ( $bool );           # The assertion is true ... (no-op)
   return unless ( $always_on );   # If not always on ... (no-op)

   # Tell where the assertion was made!
   my $str = "Assertion Violation: " . _dbug_called_by (1);

   print STDERR "\n", $str, "\n";
   print STDERR $msg, "\n"  if ( $msg );
   print STDERR "\n";
   DBUG_LEAVE (14);
}


=item DBUG_MODULE_LIST ( )

This stub does nothing since B<fish> can't be turned on for this module.

=cut

# ==============================================================
sub DBUG_MODULE_LIST
{
   return;
}


# ==============================================================================
# Start of Internal DBUG methods ...
# ==============================================================================

sub _dbug_called_by
{
   my $flg = shift;

   # Hack based on how some t/*.t programs called this function ...
   # It's why the functions below need to take care with arguments!
   $flg = shift  if ( defined $flg && $flg eq __PACKAGE__ );

   return ( Fred::Fish::DBUG::ON::_dbug_called_by ($flg, @_) );
}

# ==============================================================================
# Start of Helper methods designed to help test out this module's functionality.
# ==============================================================================

# ==================================================================
# Not exposed on purpose, so they don't polute Perl's naming space!
# ==================================================================
# Undocumented helper functions exclusively for use by the "t/*.t" programs!
# Not intended for use by anyone else.
# So subject to change without notice!
# They are used to help them validate that this module is working as expected
# in these test programs!
# ==================================================================
# For the OFF module, most of them are broken and usually return invalid
# values ... (-1)
# And the t/*.t programs know this & work arround it when needed!
# ==================================================================
# So don't use them in your code!  You've been warned!
# ==================================================================
# NOTE: Be carefull how they are called in the t/*.t programs.  If called
#       the wrong way the HINT parameter won't be handled properly!
# ==================================================================
# ASSUMES: That there are no fish logs open when called.  So it's safe to
#          temporarily disable trapping warnings so that custom warn methods
#          are not called to log the warnings as unexpected and trigger failed
#          test cases.
#          This is not in general true when called outside the t/*.t programs.
#          So it's another reason to not call them in your own code base!
# ==================================================================

# The current FISH function on the stack ...
sub dbug_func_name
{
   my $hint = shift;
   if ( defined $hint ) {
      local $SIG{__WARN__} = "";    # Disable so won't call the custom warn funcs in tests!
      warn ("Using the Cheat value ($hint) to replace the unknown function name!\n");
      return ( $hint );
   }
   return ( undef );     # Still unknown!
}

# Number of fish functions on the stack
sub dbug_level
{
   my $hint = shift;
   if ( defined $hint && $hint =~ m/^\d+$/ ) {
      local $SIG{__WARN__} = "";    # Disable so won't call the custom warn funcs in tests!
      warn ("Using the Cheat value ($hint) to replace the unknown 'dbug_level' value!\n");
      return ( $hint );
   }
   return ( -1 );     # Still unknown!
}

# In Fred::Fish::DBUG::ON, it gives the number of masked return values written
# to fish from the last call to DBUG_RETURN() / DBUG_VOID_RETURN() /
# DBUG_RETURN_SPECIAL().

# But this module doesn't collect this information for these methods.  So in
# most caes it returns -1, telling the caller it's unknown!

# See Fred::Fish::DBUG::ON::dbug_mask_return_counts() for more of my thinking
# on it.

sub dbug_mask_return_counts
{
   my $hint = shift;

   # Will always be 0 or -1!!!
   if ( $dbug_off_global_vars{mask_return_count} == 0 ) {
      return (0);       # Masking wasn't used ...

   } elsif ( defined $hint && $hint =~ m/^\d+$/ ) {
      local $SIG{__WARN__} = "";    # Disable so won't call the custom warn funcs in tests!
      warn ("Using the Cheat value ($hint) to replace the unknown return masking count!\n");
      return ( $hint );
   }

   return ( -1 );     # Still unknown!
}

# In Fred::Fish::DBUG::ON, it gives the number of masked arguments written to
# fish from the last call to DBUG_ENTER_FUNC() or DBUG_ENTER_BLOCK().

# But this module doesn't collect this information for either ENTER function.
# So in many cases it returns -1, telling the caller the count is unknown!

sub dbug_mask_argument_counts
{
   my $hint = shift;

   # Will always be 0 or -1!!!
   if ( $dbug_off_global_vars{mask_last_argument_count} == 0 ) {
      return (0);       # Masking wasn't used ...

   } elsif ( defined $hint && $hint =~ m/^\d+$/ ) {
      local $SIG{__WARN__} = "";    # Disable so won't call the custom warn funcs in tests!
      warn ("Using the Cheat value ($hint) to replace the unknown argument masking count!\n");
      return ( $hint );
   }

   return ( -1 );     # Still unknown!
}


# These 3 functions actually work as advertised!

sub dbug_threads_supported
{
   return ( Fred::Fish::DBUG::ON::dbug_threads_supported() );
}

sub dbug_fork_supported
{
   return ( Fred::Fish::DBUG::ON::dbug_fork_supported() );
}

sub dbug_time_hires_supported
{
   return ( Fred::Fish::DBUG::ON::dbug_time_hires_supported() );
}

# -----------------------------------------------------------------------------
# End of Fred::Fish::DBUG::OFF ...
# -----------------------------------------------------------------------------

=back

=head1 CREDITS

To Fred Fish for developing the basic algorithm and putting it into the
public domain!  Any bugs in its implementation are purely my fault.

=head1 SEE ALSO

L<Fred::Fish::DBUG> - The controling module which you should be using instead
of this one.

L<Fred::Fish::DBUG::ON> - The live version of the OFF module.

L<Fred::Fish::DBUG::TIE> - Allows you to trap and log STDOUT/STDERR to B<fish>.

L<Fred::Fish::DBUG::Signal> - Allows you to trap and log signals to B<fish>.

L<Fred::Fish::DBUG::SignalKiller> - Allows you to implement action
DBUG_SIG_ACTION_LOG for B<die>.  Really dangerous to use.  Will break most
code bases.

L<Fred::Fish::DBUG::Tutorial> - Sample code demonstrating using DBUG module.


=head1 COPYRIGHT

Copyright (c) 2016 - 2024 Curtis Leach.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ==============================================================
#required if module is included w/ require command;
1;
