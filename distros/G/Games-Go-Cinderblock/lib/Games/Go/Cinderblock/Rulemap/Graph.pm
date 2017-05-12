package Games::Go::Cinderblock::Rulemap::Graph;
use Moose;
extends 'Games::Go::Cinderblock::Rulemap';

#TODO: perhaps subclasses for polyhedra, streetmaps, lattice, & custom
# nodes are represented as an integer,


sub all_node_coordinates{ #only for graph
   my $self = shift;
   return  $self->{nodes_co};
}
sub node_adjacency_list{ #only for graph
   my $self = shift;
   return  $self->{adjacent};
}


sub all_nodes{
   my $self = shift;
   my $num_nodes = scalar @{$self->{nodes}};
   return (0..$num_nodes-1);
}
sub graph_node_liberties{
   my ($self, $node) = @_;
   return @{ $self->{adjacent_nodes}{$node} };
}
sub graph_stone_at_node{
   my ($self, $board, $node) = @_;
   return $board->[$node]
}

#going by the picture in wikipedia.. lol, not used
#coordinates from 0 to 1
sub build_20_fullerene{
   my @nodes; #really has planar coordinates (x,y)
   my @edges;
   my @ring; #a 5-gon
   for (0..4){
      push @ring, [cos (6.28*$_/5), sin (6.28*$_/5)]
   }
   push @nodes, @ring;
   for my $n (0..4){ #scale & push
      my @node = @{$nodes[$n]};
      $node[0] *= 1.5;
      $node[1] *= 1.5;
      push @nodes, \@node;
      push @edges, [$n,$n+5];
   }
   for my $n (5..9){ #flip, scale & push
      my @node = @{$nodes[$n]};
      $node[0] *= -1.3;
      $node[1] *= -1.3;
      push @nodes, \@node;
      push @edges, [5+($n+2)%5,$n+5];
      push @edges, [5+($n+3)%5,$n+5];
   }
   for my $n (10..14){ #scale & push
      my @node = @{$nodes[$n]};
      $node[0] *= 1.2;
      $node[1] *= 1.2;
      push @nodes, \@node;
      push @edges, [$n,$n+5];
   }
   for my $n (15..19){ #connect last 5gon
      push @edges, [$n,15+($n+1)%5];
   }
   my @adjacent;
   for (@edges){
      push @{$adjacent[$_->[0]]}, $_->[1];
      push @{$adjacent[$_->[1]]}, $_->[0];
   }
   return (\@nodes, \@adjacent)
}
1
