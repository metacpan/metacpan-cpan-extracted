#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Roots;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

use List::Util qw( max );

our $VERSION = '0.27';

use constant CMD => "roots";

=head1 NAME

C<Devel::MAT::Tool::Roots> - display a list of the root SVs

=head1 DESCRIPTION

This C<Devel::MAT> tool displays a list of all the root SVs.

=cut

=head1 COMMANDS

=head2 roots

   pmat> roots
   the *@ GV                           : GLOB($*) at 0x1381ed0
   the ARGV GV                         : GLOB(@*I) at 0x139f618
   ...

Prints a list of every root SV in the heap.

=cut

sub run_cmd
{
   my $self = shift;
   my $df = $self->df;

   my %roots = $df->roots;
   my $namelen = max map { length } keys %roots;

   foreach my $name ( sort keys %roots ) {
      my $sv = $roots{$name} or next;  # Not all root SVs are defined

      Devel::MAT::Cmd->printf( "%-*s: ", $namelen, $name );
      Devel::MAT::Cmd->print_sv( $sv );
      Devel::MAT::Cmd->printf( "\n" );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
