package Graph::Maker::Grid;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Graph::Maker::Utils qw/cartesian_product/;
use Graph::Maker::Cycle;
use Graph::Maker::Linear;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $dims = delete($params{dims});
	my $per = delete($params{cyclic}) ? 'cycle' : 'linear';

	croak "dims must be an ARRAYREF specifying the dimension with positive numbers" unless defined($dims)
		&& ref($dims) eq 'ARRAY'
		&& 0 == grep {$_ <= 0} @$dims;

	my $g = new Graph::Maker($per, N => $dims->[0], %params);
	return $g if @$dims == 0;

	my ($gn, $go);

	foreach my $d(@$dims[1..@$dims-1])
	{
		$gn = Graph::Maker->new($per, N => $d, %params);
		$go = $g->copy();
		$g = cartesian_product($gn, $go);
	}

	return $g;
}

Graph::Maker->add_factory_type( 'grid' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Grid - Creates a graph in a d-dimensional grid.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a grid with the specified number of nodes in each dimension.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Grid;

	my $g = new Graph::Maker('grid', dims => [3,4], undirected => 1); # 3 by 4 grid
	my $g2 = new Graph::Maker('grid', dims => [3,4], cyclic => 1, undirected => 1); # 3 by 4 grid with wrap-around
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a grid with the specified number of nodes in each dimension (dims).
The recognized parameters are dims (an array reference where the ith element
gives the number of nodes in that dimension; all elements have to be positive),
graph_maker, cyclic (if true then the grid wraps-around), and
any others are passed onto Graph's constructor. If dims is an empty
array reference, it returns an empty graph. If graph_maker is specified ,
it will be called to create the Graph class as desired (for example if you have
a subclass of Graph).

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-grid at rt.cpan.org>, or through the web interface at
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
