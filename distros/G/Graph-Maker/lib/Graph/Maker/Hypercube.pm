package Graph::Maker::Hypercube;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Graph::Maker::Grid;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;

	my @dims;
	push(@dims, 2) for (1..$n);

	my $g = new Graph::Maker('grid', dims => \@dims, %params);

	return $g;
}

Graph::Maker->add_factory_type( 'hypercube' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Hypercube - Create the N-dimensional hypercube graph

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates the N-dimensional hypercube graph.
If the graph is directed then edges are added in both directions to create an undirected graph.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Hypercube;

	my $g = new Graph::Maker('hypercube', N => 2, undirected => 1);
	# work with the graph


=head1 FUNCTIONS

=head2 new %params

Creates the N-dimensional hypercube graph.
The recognized parameters are N, and graph_maker
any others are passed onto L<Graph>'s constructor.
If N is note given it defaults to 0.
If graph_maker is specified and is it will be called to create the Graph class as desired (for example if you have a
subclass of Graph).

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-hypercube at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=head1 ACKNOWLEDGEMENTS

This package owes a lot to L<NetworkX|"http://networkx.lanl.gov/>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
