#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Devel::MAT::ToolBase::GraphWalker 0.45;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );
use utf8;

use List::Util qw( any pairs );
use List::UtilsBy qw( nsort_by );

my %STRENGTH_ORDER = (
   strong   => 1,
   weak     => 2,
   indirect => 3,
   inferred => 4,
);

my $next_id;
my %id_for;
my %seen;

sub reset
{
   $next_id = "A";
   undef %id_for;
   undef %seen;
}

sub walk_graph
{
   my $self = shift;
   my ( $node, @args ) = @_;

   my $addr  = $node->addr;
   my @roots = $node->roots;
   my @edges = $node->edges_in;

   if( !@roots and !@edges ) {
      $self->on_walk_nothing( $node, @args );
      return;
   }

   if( @roots == 1 and $roots[0] eq "EDEPTH" ) {
      $self->on_walk_EDEPTH( $node, @args );
      return;
   }

   # Don't bother showing any non-root edges if we have a strong root
   @edges = () if any { $_->strength eq "strong" } @roots;

   if( @edges > 0 and $seen{$addr} ) {
      my $cyclic = $seen{$addr} == 1;
      my $id     = $id_for{$addr};

      $self->on_walk_again( $node, $cyclic, $id, @args );
      return;
   }

   $seen{$addr}++;

   foreach my $idx ( 0 .. $#roots ) {
      my $root    = $roots[$idx];
      my $isfinal = $idx == $#roots && !@edges;

      $self->on_walk_root( $node, $root, $isfinal, @args );
   }

   my @refs = nsort_by { $STRENGTH_ORDER{$_->[0]->strength} } pairs @edges;
   foreach my $idx ( 0 .. $#refs ) {
      my ( $ref, $refnode ) = @{ $refs[$idx] };
      my $is_final = $idx == $#refs;

      my $ref_id;
      if( $refnode->edges_out > 1 and not $refnode->roots and not $id_for{$refnode->addr} ) {
         $ref_id = $id_for{$refnode->addr} = $next_id++;
      }

      my @subargs =
         $self->on_walk_ref( $node, $ref, $refnode->sv, $ref_id, $is_final, @args );

      if( $refnode->addr == $addr ) {
         $self->on_walk_itself( $node, @subargs );
      }
      else {
         $self->walk_graph( $refnode, @subargs );
      }
   }

   $seen{$addr}++;
}

0x55AA;
