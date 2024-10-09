###
###  Copyright (c) 2019 - 2024 Curtis Leach.  All rights reserved.
###
###  Based on the Fred Fish DBUG macros in C/C++.
###  This Algorithm is in the public domain!
###
###  Module: Fred::Fish::DBUG::TIE

=head1 NAME

Fred::Fish::DBUG::TIE - Fred Fish library extension to trap STDERR & STDOUT.

=head1 SYNOPSIS

  use Fred::Fish::DBUG::TIE;
    or
  require Fred::Fish::DBUG::TIE;

=head1 DESCRIPTION

F<Fred::Fish::DBUG::TIE> is an extension to the Fred Fish DBUG module that
allows your program to trap all output written to STDOUT & STDERR to also be
merged into your B<fish> logs.

It's very usefull when a module that doesn't use B<Fish> writes it's logging
information to your screen and you want to put this output into context with
your program's B<fish> logs.

This is implemented via Perl's B<tie> feature.  Please remember that perl only
allows one B<tie> per filehandle.  But if multiple ties are required, this
module provides a way to chain them together.

=head1 FUNCTIONS

=over 4

=cut 

package Fred::Fish::DBUG::TIE;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

# TIE always assumes Fish calls are live.
use Fred::Fish::DBUG::ON;

# use Perl::OSType ':all';
# use FileHandle;
# use File::Basename;
# use Cwd 'abs_path';
# use Config qw( %Config );
# use Sub::Identify 'sub_fullname';

$VERSION = "2.07";
@ISA = qw( Exporter );

@EXPORT = qw( 
              DBUG_TIE_STDERR     DBUG_TIE_STDOUT
              DBUG_UNTIE_STDERR   DBUG_UNTIE_STDOUT
	  );

# ==============================================================================
# Start of TIE to STDOUT/STDERR Extenstion to this module ...
# ==============================================================================
# NOTE:  You may not use AUTOLOAD in this modue.  It will break the TIE Logic

# Helper functions to make it easier to call things in Fred::Fish::DBUG::ON
# that are not exposed.

sub _dbug_hack     { return ( Fred::Fish::DBUG::ON::_dbug_hack (@_) ); }
sub _get_func_info { return ( Fred::Fish::DBUG::ON::_get_func_info (@_) ); }


=item DBUG_TIE_STDERR ( [$callback_func [, $ignore_chaining [, $caller ]]] )

This method ties what's written to STDERR to also appear in the B<fish> logs
with the tag of "B<STDERR>".  This B<tie> will happen even if the B<fish>
logging is currently turned off.

If the B<tie> is already owned by this module then future calls just steals
the old B<tie's> chain if not told to ignore it.

It returns B<1> on a successful setup, and B<0> or B<undef> on failure.

If I<$callback_func> is provided, each time you call a B<print> command against
STDERR, it will call this function for you after it first writes the message to
B<fish> and then chains to the previous B<tie> or prints to STDERR.  If either
step encounters any errors, the callback will not be made.

The number of arguments the callback function expects is based on the context
of the print request.  S<"print @list"> passes the callback @list.  But
S<"printf $fmt, @values"> passes you the single S<pre-formatted> print message.

Your callback should return B<1> on success or B<0>/B<undef> on failure.  Any
failure is reported as the return value of the original B<print> command.  If
B<fish> has been redirected to your screen, B<fish> will be disabled during
the callback.

If I<$ignore_chaining> is true, it will ignore any existing B<tie> against this
file handle.  The default is to chain to it if a B<tie> exists.  Assuming that
if you already have an established B<tie> that it must be important.  So it
won't toss it in favor of this logging unless you explicitly tell it to do so!

If I<$caller> is true, it will identify where in the code the trapped print
request can be found.  If 0 it will surpress caller info.  If undef it will use
the current I<who_called> setting from DBUG_PUSH to make this decision.

=cut

# ==============================================================

sub DBUG_TIE_STDERR
{
   my $callback     = shift;
   my $ignore_chain = shift;
   my $caller       = shift;

   my $hd;
   my $sts = open ( $hd, '>&', *STDERR );

   if ( $sts ) {
      my $func = _get_func_info ($callback, "tie STDERR callback");

      # Get the previous tie if it exists & it was asked for.
      my $old_tie = $ignore_chain ? "" : (tied (*STDERR) || "");

      my $h = tie ( *STDERR, __PACKAGE__, $hd, "STDERR", $func, $old_tie, $caller );
      $sts = ( ref ($h) eq __PACKAGE__ );
   }

   return ( $sts );
}


=item DBUG_TIE_STDOUT ( [$callback_func [, $ignore_chaining [, $caller ]]] )

This method ties what's written to STDOUT to also appear in the B<fish> logs
with the tag of "B<STDOUT>".  This B<tie> will happen even if the B<fish>
logging is currently turned off.

If the B<tie> is already owned by this module then future calls just steals
the old B<tie's> chain if not told to ignore it.

It returns B<1> on a successful setup, and B<0> or B<undef> on failure.

See DBUG_TIE_STDERR for more info on the parameters.

=cut

# ==============================================================

sub DBUG_TIE_STDOUT
{
   my $callback     = shift;
   my $ignore_chain = shift;
   my $caller       = shift;

   my $hd;
   my $sts = open ( $hd, '>&', *STDOUT );

   if ( $sts ) {
      my $func = _get_func_info ($callback, "tie STDOUT callback");

      # Get the previous tie if it exists & it was asked for.
      my $old_tie = $ignore_chain ? "" : (tied (*STDOUT) || "");

      my $h = tie ( *STDOUT, __PACKAGE__, $hd, "STDOUT", $func, $old_tie, $caller );
      $sts = ( ref ($h) eq __PACKAGE__ );
   }

   return ( $sts );
}


=item DBUG_UNTIE_STDERR ( )

This method breaks the tie between STDERR and the B<fish> logs.  Any writes to
STDERR after this call will no longer be written to B<fish>.  It will not call
B<untie> if someone else owns the STDERR B<tie>.

It returns B<1> on success, and B<0> on failure.

Currently if it's chaining STDERR to a previous B<tie> it can't preserve that
inforation.

=cut

# ==============================================================

sub DBUG_UNTIE_STDERR
{
   my ($sts, $chain);
   my $t = tied ( *STDERR );   # Can't untie while $t is still in scope!
   my $pkg = ref ( $t );

   if ( $pkg eq "" ) {
      $sts = 1;          # Nothing tied ...

   } elsif ( $pkg ne __PACKAGE__ ) {
      warn ("You can't use DBUG_UNTIE_STDERR to untie from package $pkg!\n");
      $sts = 0;

   } else {
      $chain = $t->{chain};
      my $fh = $t->{fh};
      close ( $fh );
      $t = undef;        # Force out of scope ... so untie will work!
      untie ( *STDERR );
      $sts = 1;
   }

   if ( $chain ) {
      # TODO: Put $chain as the new tie if I can figure out how to do it!
   }

   return ($sts);
}


=item DBUG_UNTIE_STDOUT ( )

This method breaks the tie between STDOUT and the B<fish> logs.  Any writes to
STDOUT after this call will no longer be written to B<fish>.  It will not call
B<untie> if someone else owns the STDOUT B<tie>.

It returns B<1> on success, and B<0> on failure.

Currently if it's chaining STDOUT to a previous B<tie> it can't preserve that
inforation.

=cut

# ==============================================================

sub DBUG_UNTIE_STDOUT
{
   my ($sts, $chain);
   my $t = tied ( *STDOUT );   # Can't untie while $t is still in scope!
   my $pkg = ref ( $t );

   if ( $pkg eq "" ) {
      $sts = 1;          # Nothing tied ...

   } elsif ( $pkg ne __PACKAGE__ ) {
      warn ("You can't use DBUG_UNTIE_STDOUT to untie from package $pkg!\n");
      $sts = 0;

   } else {
      $chain = $t->{chain};
      my $fh = $t->{fh};
      close ( $fh );
      $t = undef;        # Force out of scope ... so untie will work!
      untie ( *STDOUT );
      $sts = 1;
   }

   if ( $chain ) {
      # TODO: Put $chain as the new tie if I can figure out how to do it!
   }

   return ($sts);
}

# ===========================================================================
# The required functions to implement the TIE ...
# ===========================================================================
# See:  https://perldoc.perl.org/functions/tie.html
# ---------------------------------------------------------------------------

# Initializes the tie ...
sub TIEHANDLE {
   my $class    = shift;
   my $which    = shift;   # Linked file handle to *STDERR or *STDOUT ...
   my $tag      = shift;   # "STDERR" or "STDOUT" ...
   my $callback = shift;   # An optional calback function to call ...
   my $pkg      = shift;   # Current holder of the tie ... (or "" for none)
   my $line     = shift;   # Include caller info in fish ... ?

   # Can't chain to myself, so just steal it's chain setting ...
   $pkg = $pkg->{chain}  if ( $pkg eq $class );

   my $self = bless ( { fh       => $which,
                        tag      => $tag,
                        callback => $callback,
                        chain    => $pkg,
                        who      => $line
                      }, $class );

   return ( $self );
}


# -------------------------------------------------------------
# Handles all calls to:  "print STDxxx @args"

sub PRINT {
   my $self = shift;
   my @args = @_;

   my $fh = $self->{fh};  # The untied file handle to print to.

   # -------------------------------------------------------------
   # Were we called by something from within the DBUG module?
   # If so we don't want to do anything with it besides writing
   # this info the the proper file handle.  Do anything else
   # and we risk infinite recursion!
   # -------------------------------------------------------------
   my $ind = ( $self->{called_by_other_print_func} ) ? 2 : 1;
   my $called_by = (caller($ind))[3] || "";
   local $self->{called_by_other_print_func} = 0;

   if ( $called_by =~ m/^Fred::Fish::DBUG::/ ) {
      return ( print $fh @args );
   }

   # -------------------------------------------------------------
   # Check if we trapped a print from the callback function itself!
   # DBUG_PRINT results in infinite recursion if writing to screen!
   # -------------------------------------------------------------
   my $recursion = 0;
   if ( $self->{callback_recursion} ) {
      $recursion = 1;
   } else {
      my $other = ( $self->{tag} eq "STDERR" ) ? tied (*STDOUT) : tied (*STDERR);
      $recursion = 1   if ( $other && $other->{callback_recursion} );
   }

   if ( $recursion ) {
      # Only write to fish if it's going to a file ...
      if ( DBUG_EXECUTE ( $self->{tag} ) == 1 ) {
         _dbug_hack ( delay => 0, who_called => $self->{who},
                      \&DBUG_PRINT, $self->{tag}, join ("", @args) );
      }
      # Notice we didn't chain for the callback function ...
      # Or loop back to the callback function again.
      return ( print $fh @args );
   }

   # -------------------------------------------------------------
   # Handles print requests from everyone else ...
   # -------------------------------------------------------------

   # Calling the internal "hack" method instead of the public method due to
   # some possible option combinations I want to avoid here.
   # DBUG_PRINT ( $self->{tag}, $msg );
   _dbug_hack ( delay => 0, who_called => $self->{who},
                \&DBUG_PRINT, $self->{tag}, join ("", @args) );

   my $res;

   # Did we previously tie this file handle to something else?
   if ( $self->{chain} && $self->{chain}->can ("PRINT") ) {
      $res = $self->{chain}->PRINT ( @args );

   # Else print the message to the original file handle ...
   } else {
      $res = print $fh @args;
   }

   # Will pause fish in the callback if fish is writting to the screen.
   # This prevents potential infinite loop situations.
   if ( $res && $self->{callback} ) {
      my $pause;
      local $self->{callback_recursion} = 1;     # See test for it above!
      $pause = 1   if ( DBUG_ACTIVE () == -1 );  # Screen test.
      $res = _dbug_hack ( pause => ${pause}, $self->{callback}, @args );
   }

   return ($res);
}


# -------------------------------------------------------------
# Handles all calls to:  "printf STDxxx $fmt, @args"

sub PRINTF {
   my $self = shift;
   my $fmt  = shift;
   my @lst  = shift;

   # So I'm not blamed for calling PRINT().
   local $self->{called_by_other_print_func} = 1;

   my $data = sprintf ( $fmt, @lst );
   return ( $self->PRINT ( $data ) );
}


# -------------------------------------------------------------
# Used during calls to syswrite() ...

sub WRITE {
   my $self   = shift;
   my $scalar = shift;    # Required.
   my $length = shift;    # Optional ...
   my $offset = shift;    # Optional, may only be used if $length is uses 1st!

   my $len = length ( $scalar );

   my $data;
   unless ( defined $length ) {
      $data = $scalar;

   } elsif ( (! defined $offset) || $offset == 0 ) {
      my $max = ($len < $length) ? $len : $length;
      $data = substr ( $scalar, 0, $max );

   } elsif ( abs ($offset) > $len ) {
      $data = "";     # Offset was out of bounds ...

   } elsif ( $offset < 0 ) {
      $len = -$offset;
      my $max = ($len < $length) ? $len : $length;
      $data = substr ( $scalar, $offset, $max );

   } else {
      $len = $len - $offset;
      my $max = ($len < $length) ? $len : $length;
      $data = substr ( $scalar, $offset, $max );
   }

   # So I'm not blamed for calling PRINT().
   local $self->{called_by_other_print_func} = 1;

   return ( $self->PRINT ( $data ) );
}

# ---------------------------------------------------------------------------
# End of Fred::Fish::DBUG::TIE ...
# ---------------------------------------------------------------------------

=back

=head1 CREDITS

To Fred Fish for developing the basic algorithm and putting it into the
public domain!  Any bugs in its implementation are purely my fault.

=head1 SEE ALSO

L<Fred::Fish::DBUG> - The controling module which you should be using to enable
this module.

L<Fred::Fish::DBUG::ON> - The live version of the DBUG module.

L<Fred::Fish::DBUG::OFF> - The stub version of the DBUG module.

L<Fred::Fish::DBUG::Signal> - Allows you to trap and log signals to B<fish>.

L<Fred::Fish::DBUG::SignalKiller> - Allows you to implement action
DBUG_SIG_ACTION_LOG for B<die>.  Really dangerous to use.  Will break most
code bases.

L<Fred::Fish::DBUG::Tutorial> - Sample code demonstrating using DBUG module.

=head1 COPYRIGHT

Copyright (c) 2019 - 2024 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ============================================================
#required if module is included w/ require command;
1;
 
