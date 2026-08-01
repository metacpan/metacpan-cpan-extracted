#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2026 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Roots 0.56;

use v5.20;
use warnings;
use base qw( Devel::MAT::Tool );

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use List::Util qw( pairs );

use constant CMD => "roots";
use constant CMD_DESC => "Display a list of the root SVs";

=head1 NAME

C<Devel::MAT::Tool::Roots> - display a list of the root SVs

=head1 DESCRIPTION

This C<Devel::MAT> tool displays a list of all the root SVs.

=cut

=head1 COMMANDS

=for highlighter

=head2 roots

   pmat> roots
   the *@ GV                           : GLOB($*) at 0x1381ed0/errgv
   the ARGV GV                         : GLOB(@*I) at 0x139f618/argvgv
   ...

Prints a list of every root SV in the heap.

=cut

sub run ( $self )
{
   my $df = $self->df;

   Devel::MAT::Cmd->print_table(
      [ map {
         my ( $name, $description ) = @$_;
         my $addr = $df->root_at( $name );
         my $sv = $df->sv_at( $addr );

         $sv   ? [ "$description", Devel::MAT::Cmd->format_sv( $sv ) ] :
         $addr ? [ "$description", Devel::MAT::Cmd->format_value( $addr, addr => 1 ) ] :
                 ()
      } pairs $df->root_descriptions ],
      sep => ": ",
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
