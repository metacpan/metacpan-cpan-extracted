package Graph::Maker::SmallWorldWS;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Math::Random qw/random_uniform random_uniform_integer/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $k = delete($params{K}) || 0;
	my $p = delete($params{PR}) || 0;
	my $a = delete($params{keep_edges});
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	$k = $n if $k > $n;

	my $g = $gm->(%params);
	my @v = (1..$n);

	# Connect initial ring
	foreach my $v(@v)
	{
		for my $w(1..int($k/2 + .5))
		{
			my $j = $v + $w;
			$j = ($j % $n) if $j > $n;
			$g->add_edge($v, $j);
			$g->add_edge($j, $v) unless $g->is_undirected();
		}
	}

	# Rewire
	foreach my $e($g->edges())
	{
		if(random_uniform() < $p)
		{
			my $w = random_uniform_integer(1, 1, $n);
			$w = random_uniform_integer(1, 1, $n) until $w != $e->[0] && !$g->has_edge($e->[0], $w);

			$g->delete_edge(@$e) unless $a;
			$g->delete_edge(reverse @$e) unless $a;
			$g->add_edge($e->[0], $w);
			$g->add_edge($w, $e->[0]) unless $g->is_undirected();
		}
	}

	return $g;
}

Graph::Maker->add_factory_type( 'small_world_ws' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::SmallWorldWS - Creates a small-world graph according to (Newman) Watt and Strogatz

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a small world graph according to (Newman and) Watt and Strogatz's model.
A small world graph has an approximate power law degree distribution and a high clustering coefficient.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::SmallWorldWS;

	my $g = new Graph::Maker('small_world_ws', N => 10, K => 2, PR => .1, undirected => 1);
	my $g2 = new Graph::Maker('small_world_ws', N => 10, K => 2, PR => .1, keep_edges => 1, undirected => 1);
	# work with the graph


=head1 FUNCTIONS

=head2 new %params

Creates a small world graph with N nodes, K initial connections, and a probability of rewiring of PR
according to Watts and Strogats.
The recognized parameters are N, K, PR, graph_maker, and keep_edges
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
If K is not given it defaults to 0.
If PR is not given it defaults to 0.
keep_edges uses the Newman, Watts and Strogatz model where "rewiring" adds an edge
between two random nodes, instead of removing and then adding.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut


=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-smallworldws at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
