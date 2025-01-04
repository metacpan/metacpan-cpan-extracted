###
###  Copyright (c) 2024 - 2025 Curtis Leach.  All rights reserved.
###
###  Based on the Fred Fish DBUG macros in C/C++.
###  This Algorithm is in the public domain!
###
###  Module: Fred::Fish::DBUG::Test

=head1 NAME

Fred::Fish::DBUG::Test - Fred Fish library extension to Test::More

=head1 SYNOPSIS

  use Fred::Fish::DBUG::Test;
    or
  require Fred::Fish::DBUG::Test;

=head1 DESCRIPTION

F<Fred::Fish::DBUG::Test> is an extension to the Fred Fish DBUG module that
allows your test programs to write L<Test::More>'s output to your B<fish> logs
as well as your screen.  Only for use by your module's test scripts. (t/*.t)

So see L<Test::More> for more details on the supported functions below.  Most
are not supported.

Also be aware that if B<use threads> has been used, you must source this module
after it to avoid problems.

    use threads;
    use Fred::Fish::DBUG::Test;

All functions return what the corresponding Test::More call does.

=head1 FUNCTIONS

=over 4

=cut 

package Fred::Fish::DBUG::Test;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

# This Test module always assumes the Fish calls are live.
use Fred::Fish::DBUG::ON;

use Test::More 0.88;

$VERSION = "2.10";
@ISA = qw( Exporter );

@EXPORT = qw( 
              dbug_ok       dbug_is       dbug_isnt
              dbug_like     dbug_unlike   dbug_cmp_ok
              dbug_can_ok   dbug_isa_ok   dbug_new_ok
              dbug_BAIL_OUT
	  );


# --------------------------------------------------------------------------

sub _write_to_fish
{
   my $res       = shift;
   my $got       = shift;
   my $oper      = shift;
   my $expected  = shift;
   my $test_name = shift;
   my $diag_flag = shift || 0;

   my $subName = (caller(1))[3];   # which func called me.
   my $lbl = ($subName =~ m/:dbug_(.*)$/) ? $1 : 0;

   my $test = Test::Builder->new()->current_test();

   if ( $res ) {
      DBUG_PRINT ("OK", "%d - %s() - [%s]", $test, $lbl, $test_name);
   } else {
      my @c = (caller(1))[1,2];    # Filename & line # of who called my caller.
      my $line = "  at $c[0] line $c[1].";
      diag ( $line )  if ( $diag_flag );

      $got = (defined $got) ? "'${got}'" : "undef";
      $oper = (defined $oper) ? "'${oper}'" : "undef";
      $expected = (defined $expected) ? "'${expected}'" : "undef";

      my $msg1 = "";
      my $msg2 = "";
      my $msg3 = "";

      if ( $lbl eq "cmp_ok" ) {
         $msg1 = sprintf ("#%12s: %s\n", "got", $got);
         $msg2 = sprintf ("#%12s: %s\n", "operator", $oper);
         $msg3 = sprintf ("#%12s: %s\n", "expected", $expected);
      } elsif ( $lbl eq "is" || $lbl eq "isnt" ) {
         $msg1 = sprintf ("#%12s: %s\n", "got", $got);
         $msg3 = sprintf ("#%12s: %s\n", "expected", $expected);
      } elsif ( $lbl eq "like" || $lbl eq "unlike" ) {
         $msg1 = sprintf ("#%12s: %s\n", "got", $got);
         $msg2 = sprintf ("#%12s: %s\n", "RegExpr", $oper);
      }
      # else - ok, can_ok, isa_ok, new_ok.

      if ( Fred::Fish::DBUG::ON::dbug_get_frame_value ("who_called") ) {
         $line = "";      # Fish will automatically get the caller info itself.
      } else {
         $line = '#' . $line . "\n";
      }

      DBUG_PRINT ("NOT OK", "%d - %s() - [%s]\n%s%s%s%s",
                   $test, $lbl, $test_name, $line, $msg1, $msg2, $msg3);
   }

   return;
}

# =============================================================================

=item dbug_ok ( $status, $test_name )

Writes the message to B<fish> and then calls Test::More::ok().

=cut

sub dbug_ok
{
   my $status    = shift;
   my $test_name = shift;

   # my $res = ok ( $status, $test_name );
   my $res = Test::Builder->new()->ok ( $status, $test_name );

   _write_to_fish ($res, undef, undef, undef, $test_name, 0);

   return ( $res );
}

# =============================================================================

=item dbug_is ( $got, $expected. $test_name )

Writes the message to B<fish> and then calls Test::More::is().

=cut

sub dbug_is
{
   my $got       = shift;
   my $expected  = shift;
   my $test_name = shift;

   # my $res = is ( $got, $expected, $test_name );
   my $res = Test::Builder->new()->is_eq ( $got, $expected, $test_name );

   _write_to_fish ($res, $got, undef, $expected, $test_name, 0);

   return ( $res );
}
# =============================================================================

=item dbug_isnt ( $got, $expected. $test_name )

Writes the message to B<fish> and then calls Test::More::isnt().

=cut

sub dbug_isnt
{
   my $got       = shift;
   my $expected  = shift;
   my $test_name = shift;

   # my $res = isnt ( $got, $expected, $test_name );
   my $res = Test::Builder->new()->isnt_eq ( $got, $expected, $test_name );

   _write_to_fish ($res, $got, undef, $expected, $test_name, 0);

   return ( $res );
}

# =============================================================================

=item dbug_like ( $got, $regexpr. $test_name )

Writes the message to B<fish> and then calls Test::More::like().

=cut

sub dbug_like
{
   my $got       = shift;
   my $regexpr   = shift;
   my $test_name = shift;

   # my $res = like ( $got, $regexpr, $test_name );
   my $res = Test::Builder->new()->like ( $got, $regexpr, $test_name );

   _write_to_fish ($res, $got, $regexpr, undef, $test_name, 0);

   return ( $res );
}

# =============================================================================

=item dbug_unlike ( $got, $regexpr. $test_name )

Writes the message to B<fish> and then calls Test::More::unlike().

=cut

sub dbug_unlike
{
   my $got       = shift;
   my $regexpr   = shift;
   my $test_name = shift;

   # my $res = unlike ( $got, $regexpr, $test_name );
   my $res = Test::Builder->new()->unlike ( $got, $regexpr, $test_name );

   _write_to_fish ($res, $got, $regexpr, undef, $test_name, 0);

   return ( $res );
}

# =============================================================================

=item dbug_cmp_ok ( $got, $op, $expected. $test_name )

Writes the message to B<fish> and then calls Test::More::cmp_ok().

=cut

sub dbug_cmp_ok
{
   my $got       = shift;
   my $op        = shift;
   my $expected  = shift;
   my $test_name = shift;

   # my $res = cmp_ok ( $got, $op, $expected, $test_name );
   my $res = Test::Builder->new()->cmp_ok ( $got, $op, $expected, $test_name );

   _write_to_fish ($res, $got, $op, $expected, $test_name, 0);

   return ( $res );
}

# =============================================================================

=item dbug_can_ok ( $module_or_object, @methods )

Writes the message to B<fish> and then calls Test::More::can_ok().

=cut

sub dbug_can_ok
{
   my $module  = shift;
   my @methods = @_;

   my $cnt = @methods;
   my $test_name = "Testing existance of $cnt method(s).";

   # To complex to write my own version, so have to write additional "at" diag.
   my $res = can_ok ( $module, @methods );

   _write_to_fish ($res, undef, undef, undef, $test_name, 1);

   return ( $res );
}

# =============================================================================

=item dbug_isa_ok ( $object, $class, $object_name )

Writes the message to B<fish> and then calls Test::More::isa_ok().

=cut

sub dbug_isa_ok
{
   my @opts = @_;

   my $test_name = join (", ", @opts);

   # To complex to write my own version, so have to write additional "at" diag.
   my $res = isa_ok ( $opts[0], $opts[1], $opts[2] );

   _write_to_fish ($res, undef, undef, undef, $test_name, 1);

   return ( $res );
}

# =============================================================================

=item my $obj = dbug_new_ok ( $class, ... )

Writes the message to B<fish> and then calls Test::More::new_ok().

=cut

sub dbug_new_ok
{
   my @opts = @_;

   my $test_name = join (", ", @opts);

   my $obj = new_ok ( @opts );

   # To complex to write my own version, so have to write additional "at" diag.
   _write_to_fish (defined $obj, undef, undef, undef, $test_name, 1);

   return ( $obj );
}

# =============================================================================

=item dbug_BAIL_OUT ( $message )

Writes the message to B<fish> and then calls Test::More::done_testing() if
needed and then Test::More::BAIL_OUT($message) before terminating your test
script.

=cut

sub dbug_BAIL_OUT
{
   my $msg = shift || "Unknown reason for bailing.";

   my $tb = Test::Builder->new ();
   my $test = $tb->current_test ();
   my $plan = $tb->expected_tests ();
   # diag ( DBUG_PRINT ("test", "Current: %d,  Planed: %s", $test, $plan) );

   DBUG_PRINT ("BAIL_OUT", "%s", $msg);
   done_testing ()  if ($plan == 0);
   # BAIL_OUT ( $msg );
   Test::Builder->new()->BAIL_OUT ( $msg );
   exit (255);           # Should never get here.
}

# =============================================================================

# ---------------------------------------------------------------------------
# End of Fred::Fish::DBUG::Test ...
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

L<Fred::Fish::DBUG::TIE> - Allows you to trap and log STDOUT/STDERR to B<fish>.

L<Fred::Fish::DBUG::Signal> - Allows you to trap and log signals to B<fish>.

L<Fred::Fish::DBUG::SignalKiller> - Allows you to implement action
DBUG_SIG_ACTION_LOG for B<die>.  Really dangerous to use.  Will break most
code bases.

L<Fred::Fish::DBUG::Tutorial> - Sample code demonstrating using DBUG module.

=head1 COPYRIGHT

Copyright (c) 2024 - 2025 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ============================================================
#required if module is included w/ require command;
1;
 
