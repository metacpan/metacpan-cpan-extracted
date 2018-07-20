#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Outrefs;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.36';

use List::UtilsBy qw( sort_by );

=head1 NAME

C<Devel::MAT::Tool::Outrefs> - show SVs referred to by a given SV

=head1 COMANDS

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

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $sv ) = @_;

   my $method = $opts{all}  ? "outrefs" :
                $opts{weak} ? "outrefs_direct" :
                              "outrefs_strong";

   $self->show_refs_by_method( $method, $sv );
}

sub show_refs_by_method
{
   my $self = shift;
   my ( $method, $sv ) = @_;

   my @table;

   foreach my $ref ( sort_by { $_->name } $sv->$method ) {
      my $refsv = $ref->sv or next;

      push @table, [
         $NOTES_BY_STRENGTH{ $ref->strength },
         $ref->name,
         Devel::MAT::Cmd->format_sv( $refsv ),
      ];
   }

   Devel::MAT::Cmd->print_table( \@table, sep => "  " );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

