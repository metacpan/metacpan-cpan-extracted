#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Inrefs 0.52;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use List::Util qw( any pairs );

my %STRENGTH_TO_IDX = (
   strong   => 0,
   weak     => 1,
   indirect => 2,
   inferred => 3,
);
use constant {
   IDX_ROOTS_STRONG => 4,
   IDX_ROOTS_WEAK   => 5,
   IDX_STACK        => 6,
};

=head1 NAME

C<Devel::MAT::Tool::Inrefs> - annotate which SVs are referred to by others

=head1 DESCRIPTION

This C<Devel::MAT> tool annotates each SV with back-references from other SVs
that refer to it. It follows the C<outrefs> method of every heap SV and
annotates the referred SVs with back-references pointing back to the SVs that
refer to them.

=cut

sub init_tool
{
   my $self = shift;

   my $df = $self->df;

   my $heap_total = scalar $df->heap;
   my $count = 0;
   foreach my $sv ( $df->heap ) {
      foreach ( pairs $sv->outrefs( "NO_DESC" ) ) {
         my ( $strength, $refsv ) = @$_;

         push @{ $refsv->{tool_inrefs}[ $STRENGTH_TO_IDX{ $strength } ] }, $sv->addr if !$refsv->immortal;
      }

      $count++;
      $self->report_progress( sprintf "Patching refs in %d of %d (%.2f%%)",
         $count, $heap_total, 100*$count / $heap_total ) if ($count % 10000) == 0
   }

   # Most SVs are not roots or on the stack. To save time later on we'll make
   #   a note of those rare ones that are

   foreach ( pairs $df->roots_strong ) {
      my ( undef, $sv ) = @$_;
      next unless $sv;
      $sv->{tool_inrefs}[IDX_ROOTS_STRONG]++;
   }

   foreach ( pairs $df->roots_weak ) {
      my ( undef, $sv ) = @$_;
      next unless $sv;
      $sv->{tool_inrefs}[IDX_ROOTS_WEAK]++;
   }

   foreach my $sv ( $df->stack ) {
      $sv->{tool_inrefs}[IDX_STACK]++;
   }

   $self->report_progress();
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
   my ( @strengths ) = @_;

   # In scalar context we don't need to return SVs or Reference instances,
   #   just count them. This allows a lot of optimisations.
   my $just_count = !wantarray;

   $self->{tool_inrefs} ||= [];

   my $df = $self->df;
   my @inrefs;
   foreach my $strength ( @strengths ) {
      my %seen;
      foreach my $addr ( @{ $self->{tool_inrefs}[ $STRENGTH_TO_IDX{$strength} ] // [] } ) {
         if( $just_count ) {
            push @inrefs, 1;
         }
         else {
            $seen{$addr}++ and next;

            my $sv = $df->sv_at( $addr );

            push @inrefs, Devel::MAT::SV::Reference( $_->name, $_->strength, $sv )
               for grep { $_->strength eq $strength and $_->sv == $self } $sv->outrefs;
         }
      }
   }

   if( $self->{tool_inrefs}[IDX_ROOTS_STRONG] and $strengths[0] eq "strong" ) {
      if( $just_count ) {
         push @inrefs, ( 1 ) x $self->{tool_inrefs}[IDX_ROOTS_STRONG];
      }
      else {
         foreach ( pairs $df->roots_strong ) {
            my ( $name, $sv ) = @$_;
            push @inrefs, Devel::MAT::SV::Reference( $name, strong => undef )
               if defined $sv and $sv == $self;
         }
      }
   }

   if( $self->{tool_inrefs}[IDX_ROOTS_WEAK] and any { $_ eq "weak" } @strengths ) {
      if( $just_count ) {
         push @inrefs, ( 1 ) x $self->{tool_inrefs}[IDX_ROOTS_WEAK];
      }
      else {
         foreach ( pairs $df->roots_weak ) {
            my ( $name, $sv ) = @$_;
            push @inrefs, Devel::MAT::SV::Reference( $name, weak => undef )
               if defined $sv and $sv == $self;
         }
      }
   }

   if( $self->{tool_inrefs}[IDX_STACK] and any { $_ eq "weak" } @strengths ) {
      if( $just_count ) {
         push @inrefs, ( 1 ) x $self->{tool_inrefs}[IDX_STACK];
      }
      else {
         foreach my $stacksv ( $df->stack ) {
            next unless $stacksv->addr == $self->addr;

            push @inrefs, Devel::MAT::SV::Reference( "a value on the stack", strong => undef );
         }
      }
   }

   return @inrefs;
}

# If 'strong' is included in these lists it must be first
sub Devel::MAT::SV::inrefs          { shift->_inrefs( qw( strong weak indirect inferred )) }
sub Devel::MAT::SV::inrefs_strong   { shift->_inrefs( qw( strong      )) }
sub Devel::MAT::SV::inrefs_weak     { shift->_inrefs( qw( weak        )) }
sub Devel::MAT::SV::inrefs_direct   { shift->_inrefs( qw( strong weak )) }
sub Devel::MAT::SV::inrefs_indirect { shift->_inrefs( qw( indirect    )) }
sub Devel::MAT::SV::inrefs_inferred { shift->_inrefs( qw( inferred    )) }

=head1 COMANDS

=cut

=head2 inrefs

   pmat> inrefs defstash
   s  the hash  GLOB(%*) at 0x556e47243e40

Shows the incoming references that refer to a given SV.

Takes the following named options:

=over 4

=item --weak

Include weak direct references in the output (by default only strong direct
ones will be included).

=item --all

Include both weak and indirect references in the output.

=back

=cut

use constant CMD => "inrefs";
use constant CMD_DESC => "Show incoming references to a given SV";

use constant CMD_OPTS => (
   weak     => { help => "include weak references" },
   all      => { help => "include weak and indirect references",
                 alias => "a" },
);

use constant CMD_ARGS_SV => 1;

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $sv ) = @_;

   my $method = $opts{all}  ? "inrefs" :
                $opts{weak} ? "inrefs_direct" :
                              "inrefs_strong";

   require Devel::MAT::Tool::Outrefs;
   Devel::MAT::Tool::Outrefs->show_refs_by_method( $method, $sv );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
