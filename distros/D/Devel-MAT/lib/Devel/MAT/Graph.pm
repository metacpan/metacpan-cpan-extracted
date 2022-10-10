#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Graph 0.49;

use v5.14;
use warnings;

use Struct::Dumb 0.07 'readonly_struct';

=head1 NAME

C<Devel::MAT::Graph> - a set of references between related SVs

=head1 DESCRIPTION

Instances of this class represent an entire graph of references between
related SVs, as a helper method for return values from various L<Devel::MAT>
methods, which might be used for some sort of screen layout or other analysis
tasks.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $graph = Devel::MAT::Graph->new( $dumpfile )

Constructs a new C<Devel::MAT::Graph> instance backed by the given dumpfile
(which is only actually used to make the C<< $node->sv >> method work).

=cut

sub new
{
   my $class = shift;
   my ( $df ) = @_;

   bless {
      df  => $df,

      edges_from => {},
      edges_to   => {},

      roots_from => {},
   }, $class;
}

=head1 MUTATION METHODS

=cut

=head2 add_sv

   $graph->add_sv( $sv )

Makes the graph aware of the given L<Devel::MAT::SV>. This is not strictly
necessary before calling C<add_ref> or C<add_root>, but ensures that C<has_sv>
will return true immediately after it, and so can be used as a sentinel for
recursion control.

=cut

sub add_sv
{
   my $self = shift;
   my ( $sv ) = @_;

   $self->{edges_from}{$sv->addr} ||= [];

   return $self;
}

=head2 add_ref

   $graph->add_ref( $from_sv, $to_sv, $desc )

Adds an edge to the graph, from and to the given SVs, with the given
description.

=cut

sub add_ref
{
   my $self = shift;
   my ( $from_sv, $to_sv, $desc ) = @_;

   my $from_addr = $from_sv->addr;
   my $to_addr   = $to_sv->addr;

   push @{ $self->{edges_from}{$from_addr} }, [ $to_addr,   $desc ];
   push @{ $self->{edges_to}  {$to_addr}   }, [ $from_addr, $desc ];

   return $self;
}

=head2 add_root

   $graph->add_root( $from_sv, $desc )

Adds a root edge to the graph, at the given SV with the given description.

=cut

sub add_root
{
   my $self = shift;
   my ( $from_sv, $desc ) = @_;

   push @{ $self->{roots_from}{$from_sv->addr} }, $desc;

   return $self;
}

=head1 QUERY METHODS

=cut

=head2 has_sv

   $bool = $graph->has_sv( $sv )

Returns true if the graph has edges or roots for the given SV, or it has at
least been given to C<add_sv>.

=cut

sub has_sv
{
   my $self = shift;
   my ( $sv ) = @_;

   my $addr = $sv->addr;

   return !!( $self->{edges_from}{$addr} ||
              $self->{edges_to}  {$addr} ||
              $self->{roots_from}{$addr} );
}

=head2 get_sv_node

   $node = $graph->get_sv_node( $sv )

Returns a C<Node> object for the given SV.

=cut

sub get_sv_node
{
   my $self = shift;
   my ( $sv ) = @_;

   my $addr = ref $sv ? $sv->addr : $sv;

   return Devel::MAT::Graph::Node->new(
      graph => $self,
      addr  => $addr,
   );
}

=head2 get_root_nodes

   @desc_nodes = $graph->get_root_nodes

Returns an even-sized list of pairs, containing root descriptions and the
nodes having those roots, in no particular order.

=cut

sub get_root_nodes
{
   my $self = shift;
   return map {
      my $node = $self->get_sv_node( $_ );
      map { $_, $node } @{ $self->{roots_from}{$_} }
   } keys %{ $self->{roots_from} };
}

package Devel::MAT::Graph::Node 0.49;

=head1 NODE OBJECTS

The values returned by C<get_sv_node> respond to the following methods:

=cut

sub new { my $class = shift; bless { @_ }, $class }

=head2 graph

   $graph = $node->graph

Returns the containing C<Devel::MAT::Graph> instance.

=head2 addr

   $addr = $node->addr

Returns the address of the SV represented by this node.

=cut

sub graph { $_[0]->{graph} }
sub addr  { $_[0]->{addr}  }

=head2 sv

   $sv = $node->sv

Returns the SV object itself, as taken from the dumpfile instance.

=cut

sub sv { $_[0]->graph->{df}->sv_at( $_[0]->addr ) }

=head2 roots

   @roots = $node->roots

Returns any root descriptions given (by calls to C<< $graph->add_root >> for
the SV at this node.

   $graph->add_root( $sv, $desc );

   ( $desc, ... ) = $graph->get_sv_node( $sv )->roots

=cut

sub roots
{
   my $self = shift;
   return @{ $self->graph->{roots_from}{$self->addr} // [] };
}

=head2 edges_out

   @edges = $node->edges_out

Returns an even-sized list of any edge descriptions and more C<Node> objects
given as references (by calls to C<< $graph->add_ref >>) from the SV at this
node.

   $graph->add_ref( $from_sv, $to_sv, $desc )

   ( $desc, $to_edge, ... ) = $graph->get_sv_node( $from_sv )->edges_out

=head2 edges_out (scalar)

   $n_edges = $node->edges_out

In scalar context, returns the I<number of edges> that exist; i.e. half the
size of the pairlist that would be returned in list context.

=cut

sub edges_out
{
   my $self = shift;

   return unless my $edges = $self->graph->{edges_from}{$self->addr};
   return scalar @$edges unless wantarray;
   return map {
      $_->[1], ( ref $self )->new( graph => $self->graph, addr => $_->[0] )
   } @$edges;
}

=head2 edges_in

   @edges = $node->edges_in

Similar to C<edges_out>, but returns edges in the opposite direction; i.e.
edges of references to this node.

   $graph->add_ref( $from_sv, $to_sv, $desc )

   ( $desc, $from_edge, ... ) = $graph->get_sv_node( $to_sv )->edges_in

=head2 edges_in (scalar)

   $n_edges = $node->edges_out

In scalar context, returns the I<number of edges> that exist; i.e. half the
size of the pairlist that would be returned in list context.

=cut

sub edges_in
{
   my $self = shift;

   return unless my $edges = $self->graph->{edges_to}{$self->addr};
   return scalar @$edges unless wantarray;
   return map {
      $_->[1], ( ref $self )->new( graph => $self->graph, addr => $_->[0] )
   } @$edges;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
