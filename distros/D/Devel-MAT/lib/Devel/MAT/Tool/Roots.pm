#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Roots;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.39';

use List::Util qw( pairs );

use constant CMD => "roots";
use constant CMD_DESC => "Display a list of the root SVs";

=head1 NAME

C<Devel::MAT::Tool::Roots> - display a list of the root SVs

=head1 DESCRIPTION

This C<Devel::MAT> tool displays a list of all the root SVs.

=cut

=head1 COMMANDS

=head2 roots

   pmat> roots
   the *@ GV                           : GLOB($*) at 0x1381ed0/errgv
   the ARGV GV                         : GLOB(@*I) at 0x139f618/argvgv
   ...

Prints a list of every root SV in the heap.

=cut

sub run
{
   my $self = shift;

   my $df = $self->df;

   Devel::MAT::Cmd->print_table(
      [ map {
         my ( $name, $description ) = @$_;
         my $sv = $df->$name;

         $sv ? [ "$description", Devel::MAT::Cmd->format_sv( $sv ) ]
             : ()
      } pairs $df->root_descriptions ],
      sep => ": ",
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
