#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Callstack;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.31';

use constant CMD => "callstack";
use constant CMD_DESC => "Display the call stack";

=head1 NAME

C<Devel::MAT::Tool::Callstack> - display the call stack

=head1 DESCRIPTION

This C<Devel::MAT> tool displays the captured state of the call stack, showing
which functions have been called, and what their arguments were.

=cut

sub _stringify
{
   my ( $sv ) = @_;

   if( $sv->type eq "SCALAR" ) {
      if( defined $sv->pv ) {
         return Devel::MAT::Cmd->format_value( $sv->pv, pv => 1 );
      }
      elsif( defined( my $num = $sv->nv // $sv->uv ) ) {
         return Devel::MAT::Cmd->format_value( $num, nv => 1 );
      }
      else {
         return Devel::MAT::Cmd->format_value( "undef" );
      }
   }
   elsif( $sv->type eq "REF" ) {
      return "REF => " . _stringify( $sv->rv );
   }
   else {
      return Devel::MAT::Cmd->format_sv( $sv );
   }
}

=head1 COMMANDS

=head2 callstack

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
            $what = $ctx->cv->name;
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
         _stringify( $args[$_] )
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
               _stringify( $sv ),
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
