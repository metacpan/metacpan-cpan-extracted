#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Stack 0.47;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use constant CMD => "stack";
use constant CMD_DESC => "Display the value stack";

=head1 NAME

C<Devel::MAT::Tool::Stack> - display the value stack

=head1 DESCRIPTION

This C<Devel::MAT> tool displays the captured state of the value stack,
showing the SVs in place there.

=cut

=head1 COMMANDS

=head2 stack

   pmat> stack
   [1]: SCALAR(PV) at 0x55cde0fa0830 = "tiny.pmat"
   [0]: UNDEF at 0x55cde0f71398

Prints SVs on the value stack.

=cut

sub run
{
   my $self = shift;

   my @stacksvs = $self->df->stack;
   foreach my $idx ( reverse 0 .. $#stacksvs ) {
      my $sv = $stacksvs[$idx];

      Devel::MAT::Cmd->printf( "[%d]: %s\n",
         $idx, Devel::MAT::Cmd->format_sv_with_value( $sv )
      );
   }
}

0x55AA;
