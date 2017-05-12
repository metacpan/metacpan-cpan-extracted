package Graph::Fast;

use strict;
use warnings;
use 5.010;

our $VERSION = "0.02";

use Data::Dumper;
use Storable qw(dclone);
use List::Util qw(min);

use Hash::PriorityQueue;

sub new {
	my ($class, %args) = @_;
	my $queue_maker = exists($args{queue_maker}) ? $args{queue_maker} : sub { Hash::PriorityQueue->new() };
	return bless({
		vertices => {},
		edges => [],
		_queue_maker => $queue_maker,
	}, $class);
}

sub count_edges {
	my ($self) = @_;
	return scalar(@{$self->{edges}});
}

sub count_vertices {
	my ($self) = @_;
	return scalar(keys(%{$self->{vertices}}));
}

sub add_vertex {
	my ($self, $name) = @_;

	if (!exists($self->{vertices}->{$name})) {
		$self->{vertices}->{$name} = { name => $name, edges_in => {}, edges_out => {} };
	}
	return $self->{vertices}->{$name};
}

sub del_vertex {
	my ($self, $name) = @_;

	if (exists($self->{vertices}->{$name})) {
		@{$self->{edges}} = grep { $_->{from} ne $name and $_->{to} ne $name } @{$self->{edges}};
		foreach my $in_edge (keys %{$self->{vertices}->{$name}->{edges_in}}) {
			delete($self->{vertices}->{$in_edge}->{edges_out}->{$name});
		}
		foreach my $out_edge (keys %{$self->{vertices}->{$name}->{edges_out}}) {
			delete($self->{vertices}->{$out_edge}->{edges_in}->{$name});
		}
		delete($self->{vertices}->{$name});
	}
}

sub dijkstra_worker {
	my ($self, $from, $to) = @_;

	my $vert = $self->{vertices};
	my $suboptimal = $self->{_queue_maker}->();
	$suboptimal->insert($_, $self->{d_suboptimal}->{$_}) foreach (keys(%{$self->{d_suboptimal}}));
	$self->{d_dist}->{$_} = -1 foreach (@{$self->{d_unvisited}});
	$self->{d_dist}->{$from} = 0;

	while (1) {
		# find the smallest unvisited node
		my $current = $suboptimal->pop() // last;

		# update all neighbors
		foreach my $edge (values %{$vert->{$current}->{edges_out}}) {
			if (($self->{d_dist}->{$edge->{to}} == -1) ||
			($self->{d_dist}->{$edge->{to}} > ($self->{d_dist}->{$current} + $edge->{weight}) )) {
				$suboptimal->update(
					$edge->{to},
					$self->{d_dist}->{$edge->{to}} = $self->{d_dist}->{$current} + $edge->{weight}
				);
			}
		}
	}

	# trace the path from the destination to the start
	my @path = ();
	my $current = $to;
	NODE: while ($current ne $from) {
		foreach my $edge (values %{$vert->{$current}->{edges_in}}) {
			if ($self->{d_dist}->{$current} == $self->{d_dist}->{$edge->{from}} + $edge->{weight}) {
				$current = $edge->{from};
				unshift(@path, $edge);
				next NODE;
			}
		}
		# getting here means we found no predecessor - there is none.
		# so there's no path.
		return ();
	}

	return @path;
}

sub dijkstra_first {
	my ($self, $from, $to) = @_;
	$self->{d_from} = $from;
	$self->{d_dist} = {};
	$self->{d_unvisited}  = [ grep { $_ ne $from } keys(%{$self->{vertices}}) ];
	$self->{d_suboptimal} = { $from => 0 };

	dijkstra_worker($self, $from, $to);
}

sub dijkstra_continue {
	my ($self, $from, $to, $del_to) = @_;
	# instead of reinitializing, it should invoke the worker after initializing
	# to a state that assumes that an edge to $del_to has just been deleted.
	goto &dijkstra_first;
}

sub dijkstra {
	my ($self, $from, $to, $del_to) = @_;
	if (!defined($self->{d_from}) or $self->{d_from} ne $from) {
		goto &dijkstra_first;
	} else {
		goto &dijkstra_continue;
	}
}

sub recursive_dijkstra {
	my ($self, $from, $to, $level, $del_to) = @_;
	my @d = ([ $self->dijkstra($from, $to, $del_to) ]);

	if (!defined($d[0]->[0])) {
		return ();
	}

	if ($level > 0) {
		foreach (0..(@{$d[0]}-1)) {
			# from copies of the graph, remove one edge from the result path,
			# and continue finding paths on that tree.
			my $ffffuuuu = $self->{_queue_maker};
			$self->{_queue_maker} = "omg";
			my $g2 = dclone($self);
			$g2->{_queue_maker} = $self->{_queue_maker} = $ffffuuuu;

			$g2->del_edge($d[0]->[$_]->{from}, $d[0]->[$_]->{to});
			my @new = $g2->recursive_dijkstra($from, $to, $level - 1, $d[0]->[$_]->{to});

			# add all new paths, unless they are already present in the result set
			foreach my $n (@new) {
				push(@d, $n) unless (grep { $n ~~ $_ } @d);
			}
		}
	}

	@d;
}

sub add_edge {
	my ($self, $from, $to, $weight, $user_data) = @_;
	$self->del_edge($from => $to);

	my $edge = { from => $from, to => $to, weight => $weight, (defined($user_data) ? (user_data => $user_data) : ()) };

	push(@{$self->{edges}}, $edge);
	($self->{vertices}->{$from} // $self->add_vertex($from))->{edges_out}->{$to}   = $edge;
	($self->{vertices}->{$to  } // $self->add_vertex($to  ))->{edges_in }->{$from} = $edge;
}

sub del_edge {
	my ($self, $from, $to) = @_;

	# find the edge. assume it only exists once -> only delete the first.
	# while we're at it, delete the edge from the source vertex...
	my $e = $self->{vertices}->{$from}->{edges_out}->{$to};
	return undef if (!defined($e));
	delete($self->{vertices}->{$from}->{edges_out}->{$to});

	# now search it in the destination vertex' list, delete it there
	# also only delete the first matching one here (though now there
	# shouldn't be any duplicates at all because now we're matching the
	# actual edge, not just its endpoints like above.
	delete($self->{vertices}->{$to}->{edges_in}->{$from});

	# and remove it from the graph's vertex list
	@{$self->{edges}} = grep { $_ != $e } @{$self->{edges}}
}

1;

__END__

=head1 NAME

Graph::Fast - graph data structures and algorithms, just faster.

=head1 SYNOPSIS

 # todo

=head1 DESCRIPTION

Graph::Fast implements a mathematical abstract data structure, called graph,
that models relations between objects with vertices and edges.

=head2 Graph::Fast vs Graph

While L<Graph> is a module with a lot of features, it is not really fast.
Graph::Fast doesn't implement all the features, but it is much faster.
Graph::Fast is for you if you need the most important things done very
fast.

=head1 FUNCTIONS

Available functions are:

=head2 B<new>(I<optional options...>)

Constructs a new Graph::Fast object.

The constructor takes optional parameters as a hash. Currently there are
no options.

=head2 B<count_edges>()

Returns the number of edges in the graph.

=head2 B<count_vertices>()

Returns the number of vertices in the graph.

=head2 B<add_vertex>(I<$name>)

Adds a vertex with the specified name to the graph. Names must be unique.
It is safe to call this with a name that already exists in the graph.

=head2 B<del_vertex>(I<$name>)

Deletes a vertex with the specified name from the graph. All edges that
go from or to the specified edges will be deleted as well. It is safe to
call this with a name that doesn't exist.

=head2 B<add_edge>(I<$from> => I<$to>, I<$weight>, I<$user_data>)

Adds a directed edge to the graph, pointing from vertex named I<$from> to
I<$to>. The edge has a weight of I<$weight>. Application-specific data
can be added to the edge.

=head2 B<del_edge>(I<$from> => I<$to>)

Removes an edge that points from named vertex I<$from> to I<$to> from the
graph.

It is safe to call this for edges that do not exist.

=head2 B<dijkstra>(I<$from> => I<$to>)

Invokes Dijkstra's algorithm on the graph to find the shortest path from
source vertex I<$from> to destination vertex I<$to>.

If a path is found, it is returned as a list of edges. The edges are
hashrefs with I<from>, I<to>, I<weight> and possibly I<user_data> keys.
If no path is found, an empty list is returned.

=head1 LIMITATIONS

Many features are missing. This includes basic features.

Vertices currently cannot be deleted once added to the graph.

It is unclear how to deal with multiedges (two different edges that connect
the same pair of vertices). The behaviour will likely change in the future.
Currently edges can and will exist only once.

=head1 BUGS

Maybe.

=head1 SEE ALSO

L<Graph> - slower, but a lot more features

L<Boost::Graph> - faster, written in C++

=head1 AUTHORS & COPYRIGHTS

Made 2010 by Lars Stoltenow.
This is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
