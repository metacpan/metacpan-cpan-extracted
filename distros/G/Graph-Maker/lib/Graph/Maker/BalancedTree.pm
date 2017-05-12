package Graph::Maker::BalancedTree;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $b = delete($params{fan_out});
	my $h = delete($params{height});
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	croak "fan_out must be defined and at least 2\n" unless defined $b && $b >= 2;
	croak "h must be defined and positive\n" unless defined $h && $h >= 1;

	my $g = $gm->(%params);

	# First handle the root
	my $v = 2; # the vertex number
	my @newLeaves; # the set of new leaves
	for (1..$b)
	{
		push(@newLeaves, $v);
		$g->add_edge(1, $v);
		$g->add_edge($v, 1) unless $g->is_undirected();
		$v++;
	}

	# Now the rest
	for (2..$h-1)
	{
		my @leaves = @newLeaves;
		@newLeaves = ();
		foreach my $l(@leaves)
		{
			for (1..$b)
			{
				push(@newLeaves, $v);
				$g->add_edge($l, $v);
				$g->add_edge($v, $l) unless $g->is_undirected();
				$v++;
			}
		}
	}

	return $g;
}

Graph::Maker->add_factory_type( 'balanced_tree' => __PACKAGE__ );

1;


__DATA__

=head1 NAME

Graph::Maker::BalancedTree - Creates a balanced tree with specified fan out and height

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a tree of the given height and a fan out of fan_out. If the graph is
directed, then edges are added in both directions to create an undirected graph.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::BalancedTree;

	my $g = new Graph::Maker('balanced_tree', fan_out => 3, height => 3);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a tree of the given height and fan out. The parameters are graph_maker,
fan_out (fan_out >= 2) and height (height >= 1), and any others are
passed onto Graph's constructor. If graph_maker is specified, it will be
called to create the Graph class (for example if you have a subclass of Graph);
otherwise, this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker-balancedtree at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
