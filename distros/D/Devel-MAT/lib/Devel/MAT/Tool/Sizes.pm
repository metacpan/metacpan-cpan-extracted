#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Sizes;

use strict;
use warnings;

our $VERSION = '0.26';

use constant FOR_UI => 1;

use List::Util qw( sum0 );

=head1 NAME

C<Devel::MAT::Tool::Sizes> - calculate sizes of SV structures

=head1 DESCRIPTION

This C<Devel::MAT> tool calculates the sizes of the structures around SVs.
The individual size of each individual SV is given by the C<size> method,
though in several cases SVs can be considered to be part of larger structures
of a combined aggregate size. This tool calculates those sizes and adds them
to the UI.

The structural size is calculated from the basic size of the SV, added to
which for various types is:

=over 2

=item ARRAY

Arrays add the basic size of every non-mortal element SV.

=item HASH

Hashes add the basic size of every non-mortal value SV.

=item CODE

Codes add the basic size of their padlist and constant value, and all their
padnames, pads, constants and globrefs.

=back

The owned size is calculated by starting at the given SV and accumulating the
set of every strong outref whose refcount is 1. This is the set of all SVs the
original directly owns.

=cut

sub new { shift }

sub init_ui
{
   my $self = shift;
   my ( $ui ) = @_;

   my %size_tooltip = (
      SV        => "Display the size of each SV individually",
      Structure => "Display the size of SVs including its internal structure",
      Owned     => "Display the size of SVs including all owned referrents",
   );

   $ui->provides_radiobutton_set(
      map {
         my $size = $_ eq "SV" ? "size" : "\L${_}_size";

         $ui->register_icon(
            name => "size-$_",
            svg  => "icons/size-$_.svg",
         );

         {
            text    => $_,
            icon    => "size-$_",
            tooltip => $size_tooltip{$_},
            code    => sub {
               $ui->set_svlist_column_values(
                  column => Devel::MAT::UI->COLUMN_SIZE,
                  from   => sub { shift->$size },
               );
            },
         }
      } qw( SV Structure Owned )
   );
}

=head1 SV METHODS

This tool adds the following SV methods.

=head2 structure_set

   @svs = $sv->structure_set

Returns the total set of the SV's structure.

=head2 structure_size

   $size = $sv->structure_size

Returns the size, in bytes, of the structure that the SV contains.

=cut

# Most SVs' structual set is just themself
sub Devel::MAT::SV::structure_set { shift }

# ARRAY structure includes the element SVs
sub Devel::MAT::SV::ARRAY::structure_set
{
   my $av = shift;
   my @svs = ( $av, grep { $_ && !$_->immortal } $av->elems );
   return @svs;
}

# HASH structure includes the value SVs
sub Devel::MAT::SV::HASH::structure_set
{
   my $hv = shift;
   my @svs = ( $hv, grep { $_ && !$_->immortal } $hv->values );
   return @svs;
}

# CODE structure includes PADLIST, PADNAMES, PADs, and all pad name and pad SVs
sub Devel::MAT::SV::CODE::structure_set
{
   my $cv = shift;
   my @svs = ( $cv, grep { $_ && !$_->immortal }
      $cv->padlist, $cv->padnames, $cv->pads,
      $cv->constval, $cv->constants, $cv->globrefs );
   return @svs;
}

sub Devel::MAT::SV::structure_size
{
   return sum0 map { $_->size } shift->structure_set
}

=head2 owned_set

   @svs = $sv->owned_set

Returns the set of every SV owned by the given one.

=head2 owned_size

   $size = $sv->owned_size

Returns the total size, in bytes, of the SVs owned by the given one.

=cut

sub Devel::MAT::SV::owned_set
{
   my @more = ( shift );

   my %seen;
   my @owned;

   while( @more ) {
      my $next = pop @more;
      push @owned, $next;

      $seen{$next->addr}++;
      push @more, grep { !$seen{$_->addr} and
                         !$_->immortal and
                         $_->refcnt == 1 } map { $_->sv } $next->outrefs_strong;
   }
   return @owned;
}

sub Devel::MAT::SV::owned_size
{
   my $sv = shift;
   return $sv->{tool_sizes_owned} //= sum0 map { $_->size } $sv->owned_set;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
