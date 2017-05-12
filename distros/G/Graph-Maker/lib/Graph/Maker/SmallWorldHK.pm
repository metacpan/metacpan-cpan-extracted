package Graph::Maker::SmallWorldHK;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker::Cycle;
use Math::Random qw/random_uniform random_uniform_integer/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $m = delete($params{M}) || 1;
	my $m_0 = delete($params{M_0}) || $m;
	my $p = delete($params{PR}) || 0;
	my $callback = delete($params{callback}) || sub {};
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	$m = $n if $m > $n;

	my $g = $gm->(%params);
	my @v = (1..$n);

	my %deg;
	$deg{$_} = 0 foreach (1..$n);


	# MUST start with the $m_0 nodes connected to guarentee connectivity
	for my $i(1..$m_0)
	{
		my $j = $i == $m_0 ? 1 : $i+1;
		$g->add_edge($i, $j);
		$g->add_edge($j, $i) unless $g->is_undirected();
		$deg{$i}++;
		$deg{$j}++;
	}

	# Preferential Attachment (PA) Growth
	my $num_steps = $n - $m_0;
	foreach my $t(1..$num_steps)
	{
		my $new_node = $m_0 + $t;
		my $sel_node;

		foreach my $j(1..$m)
		{
			# Triad Formation
			if($sel_node && random_uniform() < $p)
			{
				my @succs = grep {$_ != $new_node} $g->successors($sel_node);
				my $tri_node = $succs[random_uniform_integer(1, 0, @succs ? @succs-1 : 0)];
				if($tri_node && !$g->has_edge($new_node, $tri_node))
				{
					$g->add_edge($new_node, $tri_node);
					$g->add_edge($tri_node, $new_node) unless $g->is_undirected();
					$deg{$new_node}++;
					$deg{$tri_node}++;
					next;
				}
			}

			# Preferential Attachment
			do
			{
				my $R = 0;
				$R += $deg{$_} for (1..$t);
				$R *= random_uniform();

				my $i = 1;
				my $cs = 0;
				while($cs < $R)
				{
					$cs += $deg{$i};
					$i++;
				}
				$sel_node = $i > 1 ? $i-1 : random_uniform_integer(1, 1, $m_0);
			} until($new_node != $sel_node);

			unless($g->has_edge($new_node, $sel_node))
			{
				$g->add_edge($new_node, $sel_node);
				$g->add_edge($sel_node, $new_node) unless $g->is_undirected();
				$deg{$new_node}++;
				$deg{$sel_node}++;
			}
		}
		$callback->($g, $new_node);
	}

	return $g;
}

Graph::Maker->add_factory_type( 'small_world_hk' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::SmallWorldHK - Creates a small world graph according to Holmea, Beom & Kim

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a small world graph according to Holmea, Beom & Kim's model.
A small world graph has an approximate power law degree distribution and a high clustering coefficient.
Holmea, Beom & Kim's can be seen as a super-set of th BA model as it also allows a "triangle formation"
phase to increase the clustering coefficient.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::SmallWorldHK;

	my $g = new Graph::Maker('small_world_hk', N => 10, M => 2, M_0 => 1, PR => 0, undirected => 1); # BA's model
	my $g2 = new Graph::Maker('small_world_hk', N => 10, M => 2, M_0 => 1, PR => 0.25, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a small world graph with N nodes, initially starting with M_0 nodes and adding M (the minimum number of edges
per node) on each step probalistically doing a triangle formation with probability PR according to the Holmes, Beom & Kim model.
The recognized parameters are N, M, M_0, PR, graph_maker, and callback
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
If M is not given it defaults to 1.
If M_0 is not given it defaults to M.
If PR is not given it defaults to 0.
callback allows one to simulate the growth of a preferential attachment network, callback will be called each time
a node is added.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-smallworldhk at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
