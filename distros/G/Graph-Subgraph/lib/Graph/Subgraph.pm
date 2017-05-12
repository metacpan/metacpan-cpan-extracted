use warnings;
use strict;

package Graph::Subgraph;

=head1 NAME

Graph::Subgraph - A subgraph() method for Graph module.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.0204';

=head1 SYNOPSIS

    use Graph;
    use Graph::Subgraph;

    my $foo = Graph->new();
    $foo->add_edges(qw(x y y z));
    my $bar = $foo->subgraph(['x', 'y']);
    # $bar is now 'x-y'

=head1 METHODS

The only method resides in the Graph package (not Graph::Subgraph)
so that any descendant of Graph can call it.

=head2 subgraph( \@src, [ \@dst ] );

=head2 subgraph( @src );

Returns a subgraph of the original graph induced by two sets of vertices.

A vertex is copied if and only if it belongs to one of the sets. An edge is
copied if and only if it starts in the first set and ends in the second set.

If only one set is given, it is used as both. (So that is "subgraph induced
by a set of vertices").

The sets may be given as one or two array references, or list.

The properties of the original graph (directedness etc.) are preserved,
however the properties of vertices and edges are not.

B<Complexity:> This method has a computational complexity of O(N(src)*N(dst)).

In theory, O(N(egdes_in_initial_graph)) is also possible, and the algorithm
should choose whichever is better. This is not done yet.

Feel free to file a bug report if there's anything faster.

=cut

use Carp;
use Graph;

sub subgraph {
	my $self = shift;
	my ($src, $dst);
	if (!ref $_[0]) {
		$src = $dst = [ @_ ];
		# no check here
	} else {
		$src = shift;
		$dst = shift || $src;
		croak "Extra arguments in subgraph"
			if @_;
		croak "Arguments of subgraph must be array references"
			unless ref $src eq 'ARRAY' and ref $dst eq 'ARRAY';
	};

	# Now we'll use undocumented feature of Graph.
	# As the source tells, new() will copy properties but not vertices/edges
	# if called this way
	my $subg = $self->new;

	# iterate over $src and $dst sets, copying edges when needed
	foreach my $s (@$src) {
		$self->has_vertex($s) or next;
		$subg->add_vertex($s);
		my @edges;
		foreach my $d (@$dst) {
			$self->has_edge($s, $d) and push @edges, $s, $d;
		};
		$subg->add_edges(@edges); # don't call too often, keep memory usage linear
	};

	# now add orphaned vertices from the dst set
	foreach my $d (@$dst) {
		$self->has_vertex($d) and $subg->add_vertex($d);
	};

	return $subg;
}

# FIXME UGLY HACK
# Now plant the subgraph method into Graph.
# Warn if method is present in Graph, but still override it
carp "Found subgraph method in Graph, Graph::Subgraph is now deprecated"
	if Graph->can('subgraph');

{
	no warnings 'redefine', 'once'; ## no critic
	*Graph::subgraph = \&subgraph;
};
=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

This module should be merged into Graph.

Please report any bugs or feature requests to C<bug-graph-subgraph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Subgraph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Subgraph


You can also look for information at:

=over 4

=item * github

L<https://github.com/dallaylaen/perl-Graph-Subgraph>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Subgraph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-Subgraph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-Subgraph>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-Subgraph/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Graph::Subgraph
