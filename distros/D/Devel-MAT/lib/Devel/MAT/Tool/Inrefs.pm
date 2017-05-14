#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Inrefs;

use strict;
use warnings;

our $VERSION = '0.26';

use List::Util qw( pairmap pairs );

=head1 NAME

C<Devel::MAT::Tool::Inrefs> - annotate which SVs are referred to by others

=head1 DESCRIPTION

This C<Devel::MAT> tool annotates each SV with back-references from other SVs
that refer to it. It follows the C<outrefs> method of every heap SV and
annotates the referred SVs with back-references pointing back to the SVs that
refer to them.

=cut

sub new
{
   my $class = shift;
   my ( $pmat, %args ) = @_;

   $class->patch_inrefs( $pmat->dumpfile, progress => $args{progress} );

   return $class;
}

my %PREFIX_FROM_STRENGTH = (
   strong   => "+",
   weak     => "-",
   indirect => ";",
   inferred => ".",
);
my %STRENGTH_FROM_PREFIX = reverse %PREFIX_FROM_STRENGTH;

sub patch_inrefs
{
   my $self = shift;
   my ( $df, %args ) = @_;

   my $progress = $args{progress};

   my $heap_total = scalar $df->heap;
   my $count = 0;
   foreach my $sv ( $df->heap ) {
      foreach my $ref ( $sv->_outrefs_matching ) {
         my $refsv = $ref->sv;
         my $prefixname = $PREFIX_FROM_STRENGTH{$ref->strength} . $ref->name;
         push @{ $refsv->{tool_inrefs} }, $prefixname, $sv->addr if !$refsv->immortal;
      }

      $count++;
      $progress->( sprintf "Patching refs in %d of %d (%.2f%%)",
         $count, $heap_total, 100*$count / $heap_total ) if $progress and ($count % 2000) == 0
   }

   foreach ( pairs $df->_roots ) {
      my ( $name, $sv ) = @$_;
      push @{ $sv->{tool_inrefs} }, $name, undef if defined $sv;
   }

   foreach my $addr ( @{ $df->{stack_at} } ) { # TODO
      my $sv = $df->sv_at( $addr ) or next;
      push @{ $sv->{tool_inrefs} }, "a value on the stack", undef;
   }
}

=head1 SV METHODS

This tool adds the following SV methods.

=head2 inrefs

   @refs = $sv->inrefs

Returns a list of Reference objects for each of the SVs that refer to this
one. This is formed by the inverse mapping along the SV graph from C<outrefs>.

=head2 inrefs_strong

=head2 inrefs_weak

=head2 inrefs_direct

=head2 inrefs_indirect

=head2 inrefs_inferred

   @refs = $sv->inrefs_strong

   @refs = $sv->inrefs_weak

   @refs = $sv->inrefs_direct

   @refs = $sv->inrefs_indirect

   @refs = $sv->inrefs_inferred

Returns lists of Reference objects filtered by type, analogous to the various
C<outrefs_*> methods.

=cut

sub Devel::MAT::SV::_inrefs
{
   my $self = shift;
   my ( $match ) = @_;

   $self->{tool_inrefs} ||= [];

   my $df = $self->df;
   my @inrefs;
   foreach ( pairs @{ $self->{tool_inrefs} } ) {
      my ( $name, $addr ) = @$_;

      if( wantarray and $addr and $addr =~ m/^\d+$/ ) {
         my $sv = $df->sv_at( $addr );
         if( $sv ) {
            push @inrefs, $name, $sv if $name =~ $match;
         }
         else {
            warn "Unable to find SV at $_ for $sv inref\n";
         }
      }
      else {
         push @inrefs, $name => undef if $name =~ $match;
      }
   }

   return @inrefs / 2 if !wantarray;

   return pairmap {
      my $prefix = substr( $a, 0, 1, "" );
      Devel::MAT::SV::Reference( $a, $STRENGTH_FROM_PREFIX{$prefix}, $b );
   } @inrefs;
}

sub Devel::MAT::SV::inrefs          { shift->_inrefs( qr/^./    ) }
sub Devel::MAT::SV::inrefs_strong   { shift->_inrefs( qr/^\+/   ) }
sub Devel::MAT::SV::inrefs_weak     { shift->_inrefs( qr/^-/    ) }
sub Devel::MAT::SV::inrefs_direct   { shift->_inrefs( qr/^[+-]/ ) }
sub Devel::MAT::SV::inrefs_indirect { shift->_inrefs( qr/^;/    ) }
sub Devel::MAT::SV::inrefs_inferred { shift->_inrefs( qr/^\./   ) }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
