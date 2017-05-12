package Graph::Maker::SmallWorldBA;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Graph::Maker::SmallWorldHK;
use Math::Random qw/random_uniform random_uniform_integer/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	$params{M_0} = $params{M} || 1;
	$params{PR} = 0;

	return new Graph::Maker('small_world_hk', %params);
}

Graph::Maker->add_factory_type( 'small_world_ba' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::SmallWorldBA - Creates a small world graph according to the Barabási-Albert preferential attachment model.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a small world graph according to the Barabási-Albert model.
A small world graph has an approximate power law degree distribution and a high clustering coefficient.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::SmallWorldBA;

	my $g = new Graph::Maker('small_world_ba', N => 10, M => 2, undirected => 1);
	my $g2 = new Graph::Maker('small_world_ba', N => 10, M => 2, callback => sub {print "Node added\n"}, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a small world graph with N nodes added on M edges at each step (the minimum number of edges per node)
according to the Barabási-Albert model.
The recognized parameters are N, M, graph_maker, and callback
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
If M is not given it defaults to 1.
callback allows one to simulate the growth of a preferential attachment network, callback will be called each time
a node is added.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-smallworldba at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Graph::Maker::SmallWorldBA
