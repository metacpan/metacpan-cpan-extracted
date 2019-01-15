#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Callstack;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.41';

use constant CMD => "callstack";
use constant CMD_DESC => "Display the call stack";

=head1 NAME

C<Devel::MAT::Tool::Callstack> - display the call stack

=head1 DESCRIPTION

This C<Devel::MAT> tool displays the captured state of the call stack, showing
which functions have been called, and what their arguments were.

=cut

=head1 COMMANDS

=head2 callstack

   pmat> callstack
   caller(0): &main::func => void
     at program.pl line 4
     $_[0]: SCALAR(PV) at 0x55c2bdce2778 = "arguments"
     $_[1]: SCALAR(PV) at 0x55c2bdce2868 = "go"
     $_[2]: SCALAR(PV) at 0x55c2bdce26e8 = "here"

Prints details of the call stack, including arguments to functions.

=cut

sub run
{
   my $self = shift;

   my @contexts = $self->df->contexts;
   foreach my $idx ( 0 .. $#contexts ) {
      my $ctx = $contexts[$idx];
      my $what;

      for( $ctx->type ) {
         if( $_ eq "SUB" ) {
            $what = $ctx->cv->symname;
         }
         elsif( $_ eq "TRY" ) {
            $what = "eval {...}";
         }
         elsif( $_ eq "EVAL" ) {
            my $code = substr $ctx->code->pv, 0, 32;
            $code =~ s/\n.*//;
            $what = 'eval ("' . $code . '"...)';
         }
      }

      Devel::MAT::Cmd->printf( "%s: %s => %s\n",
         Devel::MAT::Cmd->format_note( sprintf "caller(%d)", $idx ),
         $what,
         Devel::MAT::Cmd->format_note( $ctx->gimme ),
      );

      Devel::MAT::Cmd->printf( "  at %s\n",
         $ctx->location,
      );

      next unless $ctx->type eq "SUB";

      my $args = $ctx->args or next;
      my @args = $args->elems;

      my $doneargs;

      $doneargs++, Devel::MAT::Cmd->printf( "  %s: %s\n",
         Devel::MAT::Cmd->format_note( "\$_[$_]", 1 ),
         Devel::MAT::Cmd->format_sv_with_value( $args[$_] )
      ) for 0 .. $#args;

      my $cv = $ctx->cv;

      ( my $depth = $ctx->depth ) > -1 or next;
      my $pad = $cv->pad( $depth );

      foreach my $name ( '$self' ) {
         my $self_padix = $cv->padix_from_padname( $name )
            or next;

         if( my $sv = $pad->elem( $self_padix ) ) {
            $doneargs++;
            Devel::MAT::Cmd->printf( "  %s: %s\n",
               Devel::MAT::Cmd->format_note( $name, 1 ),
               Devel::MAT::Cmd->format_sv_with_value( $sv ),
            );
         }
         else {
            $doneargs++;
            Devel::MAT::Cmd->printf( "  no %s\n",
               Devel::MAT::Cmd->format_note( $name, 1 ),
            );
         }
      }

      $doneargs or
         Devel::MAT::Cmd->printf( "  %s\n",
            Devel::MAT::Cmd->format_note( "(no args)", 1 ),
         );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
