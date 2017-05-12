package Graph::Maker::Cycle;

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

	$g->add_cycle(1..$n);
	$g->add_cycle(reverse 1..$n) unless $g->is_undirected();

	return $g;
}

Graph::Maker->add_factory_type( 'cycle' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Cycle - Create a graph consisting of a cycle.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a cyclic graph with the number of nodes. A cyclic graph is a linear graph
with the last node connected to the first. If the graph is directed, then
edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Cycle;

	my $g = new Graph::Maker('cycle', N => 4, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a cyclic graph with N nodes. The recognized parameters are N, graph_maker,
and any others will be passed onto Graph's constructor. If N is not given, it
defaults to 0. If graph_maker is specified, it will be called to create the Graph
class as desired (for example if you have a subclass of Graph); otherwise, this
defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker-cycle at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
