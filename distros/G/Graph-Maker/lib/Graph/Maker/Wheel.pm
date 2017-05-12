package Graph::Maker::Wheel;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Graph::Maker::Star;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = $params{N} || 0;

	my $g = new Graph::Maker('star', %params);

	$g->add_cycle(2..$n);
	$g->add_cycle(reverse 2..$n) unless $g->is_undirected();

	return $g;
}

Graph::Maker->add_factory_type( 'wheel' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Wheel - Creates a wheel graph.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS


Creates a wheel graph with the number of nodes.
A wheel graph is a star graph with the outter nodes connected in a cycle.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Wheel;

	my $g = new Graph::Maker('wheel', N => 10, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a wheel graph with the number of nodes.
The recognized parameters are N, and graph_maker
any others are passed onto L<Graph>'s constructor.
If N is note given it defaults to 0.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-wheel at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
