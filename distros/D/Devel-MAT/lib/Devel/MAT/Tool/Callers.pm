#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2019 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Callers 0.50;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use constant CMD => "callers";
use constant CMD_DESC => "Display the caller stack";

use constant CMD_OPTS => (
   pad => { help => "show PAD contents",
            alias => "P" },
);

=head1 NAME

C<Devel::MAT::Tool::Callers> - display the caller stack

=head1 DESCRIPTION

This C<Devel::MAT> tool displays the captured state of the caller stack,
showing which functions have been called, and what their arguments were.

=cut

=head1 COMMANDS

=head2 callers

   pmat> callers
   caller(0): &main::func => void
     at program.pl line 4
     $_[0]: SCALAR(PV) at 0x55c2bdce2778 = "arguments"
     $_[1]: SCALAR(PV) at 0x55c2bdce2868 = "go"
     $_[2]: SCALAR(PV) at 0x55c2bdce26e8 = "here"

Prints details of the caller stack, including arguments to functions.

Takes the following named options:

=over 4

=item --pad, -P

Additionally show the contents of the active PAD at this depth.

=back

=cut

sub run
{
   my $self = shift;
   my %opts = %{ +shift };

   my @contexts = $self->df->contexts;
   foreach my $idx ( 0 .. $#contexts ) {
      my $ctx = $contexts[$idx];
      my $what;

      for( $ctx->type ) {
         if( $_ eq "SUB" ) {
            $what = String::Tagged->from_sprintf( "%s=%s",
               Devel::MAT::Cmd->format_sv( $ctx->cv ),
               Devel::MAT::Cmd->format_symbol( $ctx->cv->symname ),
            );
         }
         elsif( $_ eq "TRY" ) {
            $what = "eval {...}";
         }
         elsif( $_ eq "EVAL" ) {
            $what = String::Tagged->from_sprintf( "eval (%s)",
               Devel::MAT::Cmd->format_value( $ctx->code->pv, pv => 1 ),
            );
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

      Devel::MAT::Cmd->printf( "  cv=%s\n",
         Devel::MAT::Cmd->format_sv( $cv ),
      );

      ( my $depth = $ctx->depth ) > -1 or next;
      my $pad = $cv->pad( $depth );

      if( $opts{pad} ) {
         Devel::MAT::Cmd->printf( "  curpad=%s\n",
            Devel::MAT::Cmd->format_sv( $pad )
         );

         require Devel::MAT::Tool::Show;
         Devel::MAT::Tool::Show->show_PAD_contents( $pad );
      }
      else {
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
