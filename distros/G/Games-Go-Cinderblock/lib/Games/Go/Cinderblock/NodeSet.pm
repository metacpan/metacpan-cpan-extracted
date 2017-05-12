package Games::Go::Cinderblock::NodeSet;
use Moose;

use overload
   '==' => \&test_equality,
   '!=' => \&test_inequality,
   '""' => \&stringify;

has _nodes => (
   isa => 'HashRef',
   is => 'ro',
   default => sub{{}},
);
has rulemap => (
   isa => 'Games::Go::Cinderblock::Rulemap',
   is => 'ro', #shouldn't change.
   required => 1,
);

sub copy{
   my $self = shift;
   my %set = %{$self->_nodes};
   return Games::Go::Cinderblock::NodeSet->new(
      _nodes => \%set,
      rulemap => $self->rulemap,
   );
}

sub nodes{
   my $self = shift;
   return values %{$self->_nodes};
}
sub remove{
   my $self = shift;
   return unless $_[0];
   if(ref($_[0]) eq 'Games::Go::Cinderblock::NodeSet'){
      my $ns = shift;
      for my $nid (keys %{$ns->_nodes}){
         delete $self->_nodes->{$nid}
      }
   }
   else{
      for my $node (@_){
         my $node_id = $self->rulemap->node_to_id($node);
         delete $self->_nodes->{$node_id};
      }
   }
}
sub add { #stones or a nodeset.
   my $self = shift;
   return unless $_[0];
   if(ref($_[0]) eq 'Games::Go::Cinderblock::NodeSet'){
      my $ns = shift;
      for my $nid (keys %{$ns->_nodes}){
         $self->_nodes->{$nid} = $ns->_nodes->{$nid};
      }
   }
   else{
      for my $node (@_){
         my $node_id = $self->rulemap->node_to_id($node);
         $self->_nodes->{$node_id} = $node;
      }
   }
}
sub has_node{
   my ($self,$node) = @_;
   my $node_id = $self->rulemap->node_to_id($node);
   return 1 if defined $self->_nodes->{$node_id};
   return 0;
}

sub test_equality{
   my $self = shift;
   my $other = shift;
   Carp::confess unless ref($other) eq 'Games::Go::Cinderblock::NodeSet';
   return 0 if scalar(keys %{$self->_nodes}) != scalar(keys %{$other->_nodes});
   for my $key (keys %{$self->_nodes}){
      return 0 unless defined $other->_nodes->{$key};
   }
   return 1;
}
sub test_inequality{
   my $self = shift;
   my $other = shift;
   return 0 if $self == $other;
   return 1;
}

sub stringify{
   my $self = shift;
   return '<' . join( ',', keys %{$self->_nodes}) . '>';
}

sub count{
   my $self = shift;
   return scalar keys %{$self->_nodes};
}

# return an arbitrary element. not random.
sub choose{
   my $self = shift;
   my ($key,$val) = each %{$self->_nodes};
   return $val;
}

sub adjacent{
   my $self = shift;
   my $res = $self->rulemap->nodeset;
   for my $n ($self->nodes){
      my @adj = $self->rulemap->adjacent_nodes($n);
      $res->add(@adj);
   }
   $res->remove($self);
   return $res;
}
sub union{
   my ($self,$other) = @_;
   my $result = $self->rulemap->nodeset;
   for my $n ($self->nodes){
      $result->add($n);
   }
   for my $n ($other->nodes){
      $result->add($n);
   }
   $result
}
sub intersect{
   my ($self,$other) = @_;
   my $result = $self->rulemap->nodeset;
   for my $n ($self->nodes){
      next unless $other->has_node($n);
      $result->add($n);
   }
   $result
}

sub disjoint_split{
   my $self = shift;
   my @disjoints;
   my $remaining = $self->copy;
   while($remaining->count){
      my $choice_node = $remaining->choose;
      my $subset = $self->rulemap->nodeset;#($choice_node);
      my $flood_iter = $self->rulemap->nodeset ($choice_node);
      while($flood_iter->count){
         $subset->add($flood_iter);
         $remaining->remove($flood_iter);
         $flood_iter = $flood_iter->adjacent->intersect($remaining);
      }
      push @disjoints, $subset;
   }
   return @disjoints;
}
1;

__END__

=head1 NAME

Games::Go::Cinderblock::NodeSet

=head1 SYNOPSIS

 my $rulemap = Games::Go::Cinderblock::Rulemap::Rect->new
   ( h => 19, w => 19 );
 #initialize two empty nodesets
 my $ns1 = $rulemap->nodeset;
 my $ns2 = $ns1->copy;
 #add two opposite corners.
 $ns1->add([0,0], [18,18]);
 # add 4 nodes to $ns2, each adjacent to the 2 nodes in $ns1
 $ns2->add($ns1->adjacent);
 # let ns2 have the original 2 corners.
 $ns2->add($ns1);
 # split ns2 into its 2 connected subsets 
 my @foo = $ns2->disjoint_split;
 # compare equality
 my $false = $ns1 == $ns2;

=head1 DESCRIPTION

A set of nodes :|

NodeSets are typically initiated with C<< $rulemap->nodeset(@nodes) >>. 
NodeSets may be empty. Nodesets are independant of 
L<State|Games::Go::Cinderblock::State>, but 
heavily dependant on L<Rulemap|Games::Go::Cinderblock::RuleMap>.

insertion, lookup, removal of a single node is O(1). Nodesets are mutable,
but union & intersect do not affect the invocant.
Nodes are topology-implementation-dependent. In
L<::Rect|Games::Go::Cinderblock::Rulemap::Rect> instances, nodes are defined as a C<[$row,$col]>
array ref. In future instances, a node may be defined as
a number, with an entry in an adjacency matrix.

Set operations unclude union, intersect, C<==>, 
count, add, remove, copy, has_node, disjoint_split

=head1 METHODS

=head2 count

Returns the number of nodes in the nodeset.

=head2 add

C<add> & C<remove> each may take either a nodeset or a list of nodes

=head2 remove

=head2 has_node

 $set->add([3,3])
 my $true = $set->has_node([3,3])
 $set->remove([3,3])
 my $false = $set->has_node([3,3])

=head2 copy

=head2 union

 my $result = $set1->union($set2)

Return the set of nodes in either the invocant or operand.

=head2 intersect

 my $result = $set1->intersect($set2)

Return the set of nodes in both invocant and operand.

=head2 ==, !=

Compare two sets. Returns true or false.

=head2 adjacent

Returns a nodeset of nodes adjacent to the nodes of the invocant.
The result excludes any nodes of the invocant.

=head2 disjoint_split

Return an arrayref of disconnected regions. Use this with 
L<Games::Go::Cinderblock::State>'s grep functionality to
uncover distinct, disconnected regions of a particular attribute
(color, etc.)

=cut

