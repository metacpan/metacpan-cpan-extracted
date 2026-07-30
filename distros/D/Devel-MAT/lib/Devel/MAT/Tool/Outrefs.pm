#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2026 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Outrefs 0.55;

use v5.20;
use warnings;
use base qw( Devel::MAT::Tool );

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use List::UtilsBy qw( sort_by );

=head1 NAME

C<Devel::MAT::Tool::Outrefs> - show SVs referred to by a given SV

=head1 DESCRIPTION

This C<Devel::MAT> tool provides a command to list the other SVs that a given
SV retains a reference to.

=head1 COMANDS

=for highlighter

=cut

=head2 outrefs

   pmat> outrefs defstash
   ...

Shows the outgoing references that refer to other SVs.

Takes the following named options:

=over 4

=item --weak

Include weak direct references in the output (by default only strong direct
ones will be included).

=item --all

Include both weak and indirect references in the output.

=back

=cut

use constant CMD => "outrefs";
use constant CMD_DESC => "Show outgoing references from a given SV";

use constant CMD_OPTS => (
   weak     => { help => "include weak references" },
   all      => { help => "include weak and indirect references",
                 alias => "a" },
);

use constant CMD_ARGS_SV => 1;

my %NOTES_BY_STRENGTH = (
   strong   => Devel::MAT::Cmd->format_note( "s" ),
   weak     => Devel::MAT::Cmd->format_note( "w", 1 ),
   indirect => Devel::MAT::Cmd->format_note( "i", 2 ),
   inferred => Devel::MAT::Cmd->format_note( "~", 2 ),
);

sub run ( $self, $optsref, $sv )
{
   my %opts = $optsref->%*;

   my $method = $opts{all}  ? "outrefs" :
                $opts{weak} ? "outrefs_direct" :
                              "outrefs_strong";

   $self->show_refs_by_method( $method, $sv );
}

sub show_refs_by_method ( $self, $method, $sv )
{
   my @refs = grep { $_->sv } sort_by { $_->name } $sv->$method;

   Devel::MAT::Tool::more->paginate( sub ( $count ) {
      my @table;

      my $ref;
      $ref = shift @refs and
         push @table, [
            $NOTES_BY_STRENGTH{ $ref->strength },
            $ref->name,
            Devel::MAT::Cmd->format_sv( $ref->sv ),
         ] while $count--;

      Devel::MAT::Cmd->print_table( \@table, sep => "  " );
      return scalar @refs;
   } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

