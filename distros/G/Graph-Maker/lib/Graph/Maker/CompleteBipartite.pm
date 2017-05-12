package Graph::Maker::CompleteBipartite;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n1 = delete($params{N1}) || 0;
	my $n2 = delete($params{N2}) || 0;
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	my $g = $gm->(%params);

	for my $u(1..$n1)
	{
		for my $v($n1+1..$n1+$n2)
		{
			$g->add_edge($u, $v);
			$g->add_edge($v, $u) unless $g->is_undirected();
		}
	}

	return $g;
}

Graph::Maker->add_factory_type( 'complete_bipartite' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::CompleteBipartite - Creates a complete bipartite graph.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a complete bipartite graph with N1 nodes in one set and N2 in the other.
A complete bipartite graph is one in which it can be decomposed into two unique sets with edges only between these sets,
and every node in one set is linked to every node in the other set.
If the graph is directed then edges are added in both directions to create an undirected graph.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::CompleteBipartite;

	my (@a, @b);
	$g = new Graph::Maker('complete_bipartite', N1 => 5, N2 => 4, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a complete bipartite graph with N1 (N2) in the first (second) set.
The recognized parameters are N1, N2, graph_maker, and any others will be
passed onto Graph's constructor. If N1 or N2 is not given, they
default to 0. If graph_maker is specified, it will be called to create the
Graph class (for example if you have a subclass of Graph); otherwise, this defaults
to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-completebipartite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Graph::Maker::CompleteBipartite
