package BoostGraphWrapper;

use strict;
use warnings;
use Boost::Graph;

sub new {
	my $g = new Boost::Graph(directed => 1);
	return bless [$g], $_[0];
}

sub add_vertex {
	# my ($self, $name) = @_;
	$_[0]->[0]->add_node($_[1]);
}

sub add_weighted_edge {
	# my ($self, $from, $to, $weight) = @_;
	$_[0]->[0]->add_edge(node1 => $_[1], node2 => $_[2], weight => $_[3]);
}

sub add_edge {
	# my ($self, $from, $to) = @_;
	$_[0]->[0]->add_edge(node1 => $_[1], node2 => $_[2], weight => 1);
}

sub vertices {
	return $_[0]->[0]->nodecount();
}

sub edges {
	return $_[0]->[0]->edgecount();
}

sub SP_Dijkstra {
	# my ($self, $from, $to) = @_;
	return @{$_[0]->[0]->dijkstra_shortest_path($_[1], $_[2])->{path}};
}

1;
