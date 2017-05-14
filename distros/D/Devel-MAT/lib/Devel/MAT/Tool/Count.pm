#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Count;

use strict;
use warnings;

our $VERSION = '0.26';

use constant CMD => "count";

=head1 NAME

C<Devel::MAT::Tool::Count> - count the various kinds of SV

=head1 DESCRIPTION

This C<Devel::MAT> tool counts the different kinds of SV in the heap.

=cut

sub new
{
   my $class = shift;
   return bless { df => shift->dumpfile }, $class;
}

=head1 METHODS

=cut

=head2 count_svs

   ( $kinds, $blessed ) = $count->count_svs( $df )

Counts the different kinds of SV in the heap of the given
L<Devel::MAT::Dumpfile> and returns two HASH references containing totals. The
first counts every SV, split by type. The second counts those SVs that are
blessed into some package; that is, SVs that are objects.

=cut

sub count_svs
{
   shift;
   my ( $df ) = @_;

   my %kinds;
   my %blessed_kinds;

   foreach my $sv ( $df->heap ) {
      $kinds{ref $sv}++;
      $blessed_kinds{ref $sv}++ if $sv->blessed;
   }

   # Strip Devel::MAT::SV:: prefix from keys
   foreach my $k ( keys %kinds ) {
      ( my $new_k = $k ) =~ s/^Devel::MAT::SV:://;
      $kinds        {$new_k} = delete $kinds        {$k};
      $blessed_kinds{$new_k} = delete $blessed_kinds{$k};
   }

   return \%kinds, \%blessed_kinds;
}

=head1 COMMANDS

=head2 count

   pmat> count
     Kind                 Count      (blessed) 
     ARRAY                134                  
     CODE                 133                  

Prints a summary of the count of each type of object.

=cut

sub run_cmd
{
   my $self = shift;

   Devel::MAT::Cmd->printf( "  %-20s %-10s %-10s\n", "Kind", "Count", "(blessed)" );

   my ( $kinds, $blessed ) = $self->count_svs( $self->{df} );

   foreach my $kind ( sort keys %$kinds ) {
      Devel::MAT::Cmd->printf( "  %-20s %-10s %-10s\n", $kind, $kinds->{$kind}, $blessed->{$kind} // "" );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
