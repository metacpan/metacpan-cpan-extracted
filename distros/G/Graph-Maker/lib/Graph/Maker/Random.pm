package Graph::Maker::Random;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker::Complete;
use Graph::Maker::Utils qw/is_valid_degree_seq/;
use Math::Random qw/random_uniform_integer random_uniform/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $m = delete($params{M}) || 0;
	my $p = delete($params{PR})|| 0;
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	if($p == 1 || $m >= $n*($n-1)/2)
	{
		return new Graph::Maker('complete', N => $n, graph_maker => $gm, %params);
	}

	my $g = $gm->(%params);
	$g->add_vertices(1..$n);

	return erdos($g, $n, $p) if $p;
	return random($g, $n, $m);
}

sub erdos
{
	my ($g, $n, $p, $m) = @_;

	for my $u(1..$n)
	{
		for my $v(1..$n)
		{
			next if $u == $v;
			if(random_uniform() < $p)
			{
				$g->add_edge($u, $v);
				$g->add_edge($v, $u) if $g->is_directed();
			}
		}
	}
	return $g;
}

sub random
{
	my ($g, $n, $m) = @_;

	for (1..$m)
	{
		my @e = random_uniform_integer(2, 1, $n);
		redo if $e[0] == $e[1] || $g->has_edge(@e);
		$g->add_edge(@e);
		$g->add_edge(reverse @e) unless $g->is_undirected();
	}
	return $g;
}

Graph::Maker->add_factory_type( 'random' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Random - Creates a random graph (using Erdos Renyi or with a specified number of edges)

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a random graph with N nodes and with exactly M edges or connects random edges with probability
PR.
A random graph has N nodes and M random edges, B<OR> for every pair of nodes adds an edge with probability PR (Erdos-Renyi graph).
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Random;

	my $g = new Graph::Maker('random', N => 10, M => 2, undirected => 1);
	my $g = new Graph::Maker('random', N => 100, PR => .01, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params


Creates a random graph with N nodes either connecting edges with the given probability (PR)
or with the specified number of edges (M);
The recognized parameters are graph_maker, N, M, and PR
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
If PR is not given it defaults to 0.
If PR is 1 or M is bigger than N*(N-2)/2 then returns a L<Complete Graph|Graph::Maker::Complete>.
If M is not given it defaults to 0.
If PR and M are both nonzero ignores M.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-random at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
