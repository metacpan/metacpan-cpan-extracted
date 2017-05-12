package Graph::Maker::Disk;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use constant TWO_PI => 2*3.1415926535897932384626433832795;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $numDisks = delete($params{disks}) || 0;
	my $numPerDisk = delete($params{init})|| 0;
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	croak "init must be defined and greater than 1 or equal to 0\n" unless defined $numPerDisk && ($numPerDisk >= 2 && $numPerDisk != 0);

	my $g = $gm->(%params);

	$g->set_vertex_attribute(1, 'pos', [0, 0]);
	$g->add_edges(1, $_, ($g->is_directed() ? ($_, 1) : ())) for (2..$numPerDisk+1);

	my $v = 2;
	for my $i(1..$numDisks)
	{
		my $thetaDel = TWO_PI / $numPerDisk;
		my $theta = 0;

		if($numPerDisk > 1)
		{
			$g->add_cycle($v..$v+$numPerDisk-1);
			$g->add_cycle(reverse $v..$v+$numPerDisk-1) unless $g->is_undirected();
		}

		for my $j(0..$numPerDisk-1)
		{
			$g->set_vertex_attribute($v, 'pos', [$i * cos($theta), $i * sin($theta)]);

			if($i < $numDisks)
			{
				$g->add_edges($v, $v+$numPerDisk+$j, $v, $v+$numPerDisk+$j+1);
				$g->add_edges($v+$numPerDisk+$j, $v, $v+$numPerDisk+$j+1, $v) unless $g->is_undirected();
			}

			$v++;
			$theta += $thetaDel;
		}
		$numPerDisk *= 2;
	}

	return $g;
}

Graph::Maker->add_factory_type( 'disk' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Disk - Creates a graph with nodes positioned in concentric connected rings.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a disk graph with init nodes on the first cycle, and disks total cycles.
A disk graph is an extensoin of a wheel (a wheel is a disk with disks=1) wherein
there is a central node, then init node, then 2*init nodes, ... to 2**disks*init nodes
where each node on an inner cycle connects to 2 nodes on the outter cycle.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Disk;

	my $g = new Graph::Maker('disk', disks => 4, init => 3);
	my $arr = $g->get_vertex_attribute(1, 'pos");
	print "@$arr\n"; # prints out 0 0
	# work with the graph

As disk graphs are generally associated with geometry the pos attribute is set for each node
specifying their position (node 1 is at (0,0) and the distance between nodes is 1 unit).

=head1 FUNCTIONS

=head2 new %params

Creates a disk graph with init nodes on the first cycle, and disks total cycles.
the required parameters are graph_maker, disks and init (init >= 2 || init == 0)
any others are passed onto L<Graph>'s constructor.
If disks is not given it defaults to 0.
If init is not given it defaults to 0.
The vertex attribute pos will be set to an array reference of the nodes d-dimensional position.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-disk at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

