#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Summary;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.43';

use constant CMD => "summary";
use constant CMD_DESC => "Print basic information about the loaded dumpfile";

=head1 NAME

C<Devel::MAT::Tool::Summary> - show basic information about the dumpfile

=head1 COMANDS

=cut

=head2 summary

   pmat> summary
   Perl memory dumpfile from perl 5.26.1 threaded
   Heap contains 3315 objects

Prints basic information about the dumpfile - the version of perl that created
it, and the number of SVs it contains.

=cut

sub run
{
   my $self = shift;

   my $df = $self->df;

   Devel::MAT::Cmd->printf( "Perl memory dumpfile from perl %s %s\n",
      $df->perlversion, $df->ithreads ? "threaded" : "non-threaded" );

   Devel::MAT::Cmd->printf( "Heap contains %d objects\n", scalar $df->heap );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
