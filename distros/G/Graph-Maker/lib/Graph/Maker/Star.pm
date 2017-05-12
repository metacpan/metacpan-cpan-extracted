package Graph::Maker::Star;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	my $g = $gm->(%params);

	$g->add_edges(1, $_, ($g->is_directed() ? ($_, 1) : ())) for (2..$n);

	return $g;
}

Graph::Maker->add_factory_type( 'star' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Star - Creates a star graph.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Creates a star graph with the number of nodes.
A star graph has one node which is connected to all nodes, and no other edges.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Star;

	my $g = new Graph::Maker('star', N => 10, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a star graph with N nodes.
The recognized parameters are N, and graph_maker
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-star at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
