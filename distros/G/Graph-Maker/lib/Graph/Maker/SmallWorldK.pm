package Graph::Maker::SmallWorldK;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Graph::Maker::Grid;
use Math::Random qw/random_uniform random_uniform_integer/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $p = delete($params{P}) || 1;
	my $q = delete($params{Q}) || 0;
	my $alpha = delete($params{alpha}) || 2;
	my $cyclic = delete($params{cyclic});

	my $g = new Graph::Maker('grid', dims => [$n, $n], cyclic => $cyclic, %params);

	my ($v, $na, $nb);

	for my $i(1..$n)
	{
		for my $j(1..$n)
		{
			$v = ($i-1)*$n+$j;

			# Set the positions
			$g->set_vertex_attribute($v, 'pos', [$i, $j]);

			# Handle the extra local contacts
			if($p > 1)
			{
				for my $A(0..$p)
				{
					for my $B(0..$p)
					{
						next if ($A == 0 && $B == 0) || $A+$B <= 1;

						for my $a($A, -$A)
						{
							for my $b($B, -$B)
							{
								$na = $i + $a;
								$nb = $j + $b;

#                                                               print "\t\t[$i $j] [$a $b] [$na $nb]\n";

								next if ($na > $n || $nb > $n) && !$cyclic;
								$na = ($na % ($n-1))+1 if $na > $n;
								$nb = ($nb % ($n-1))+1 if $nb > $n;

#                                                               print "\t\tNeg?\n";
								next if ($na <= 0 || $nb <= 0) && !$cyclic;
								$na = $n+$na if $na <= 0;
								$nb = $n+$nb if $nb <= 0;
								if(dist($cyclic, $n, $i, $j, $na, $nb) <= $p)
								{
									unless($g->has_edge($v, ($na-1)*$n + $nb))
									{
										$g->add_edge($v, ($na-1)*$n + $nb);
										$g->add_edge(($na-1)*$n + $nb, $v) unless $g->is_undirected();;
									}
								}
#                                                               if($v == 4)
#                                                               {
#                                                                       print "\tPOS: [$i, $j] + [$a, $b] = [" . join(', ', ($na, $nb)) . "] = " . (($na-1)*$n+$nb) . " " . dist($cyclic, $n, $i, $j, $na, $nb, 1) . "\n";
#                                                               }
							}
						}
					}
				}
			}

			# handle the remote connections
			my $Q = 0;
			until($Q >= $q)
			{
				my @a = random_uniform_integer(2, 1, $n);
				$na = ($a[0]-1) * $n + $a[1];

				next if $na == $v || $g->has_edge($v, $na) || random_uniform() > dist($cyclic, $n, $i, $j, $a[0], $a[1])**-$alpha;

				$g->add_edge($v, $na);
				$g->add_edge($na, $v) unless $g->is_undirected();;
				$Q++;
			}
		}
	}

	return $g;
}

sub dist
{
	my ($cyclic, $n, $i, $j, $k, $l, $degb) = @_;

	return abs($i-$k) + abs($j-$l) if !$cyclic;

	#print qq{\t\tmin(abs($i-$k), $n - abs($i-$k)) = } . min(abs($i-$k), $n - abs($i-$k)) if $degb;
	#print qq{ min(abs($j-$k), $n - abs($j-$k)) = } . min(abs($j-$k), $n - abs($j-$k)) . "\n" if $degb;

	return min(abs($i-$k), $n - abs($i-$k)) + min(abs($j-$l), $n - abs($j-$l));
}
sub min { $_[0] < $_[1] ? $_[0] : $_[1]; }

Graph::Maker->add_factory_type( 'small_world_k' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::SmallWorldK - Creates a small world graph using Kleinberg's model in 2-dimensions

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS


Creates a small world graph according to Kleinberg's long-range connection model.
In Kleinberg's model a small world graph is connected to nodes within manhattan (L1) distance P and has Q long range contacts
referred to as K(N, P, Q, alpha) or K*(N, P, Q, alpha) (if it wraps-around).
In addition Kleinberg's model gives all nodes a position so that routing can be done efficiently using a greedy algorithm,
these positions are set in the 'pos' attribute for the vertices.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::SmallWorldK;

	my $g = new Graph::Maker('small_world_k', N => 10, P => 2, undirected => 1);
	my $g2 = new Graph::Maker('small_world_k', N => 10, P => 2, Q => 1, alpha => 2.1, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a small world graph with N^2 nodes in a 2-d grid, with connections to nodes
within P manhattan units of distance, and Q random
long-range connections to nodes determined by d(u, v) ** -alpha (where d is the
manhattan distance) according to
Kleinberg's model (the grid wraps-around if cyclic is specified).
The recognized parameters are N, P, Q, cyclic, graph_maker,  and alpha
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
If P is not given it defaults to 1.
If Q is not given it defaults to 0.
If alpha is not given it defaults to 2 (2 <= alpha <= 3 allows poly-logarithmic routing using a local greedy algorithm).
If cyclic is set then the "edges" of the grid are connected.
The vertex attribute pos will be set to an array reference of the nodes d-dimensional position.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-SmallWorldK at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Graph::Maker::SmallWorldK
