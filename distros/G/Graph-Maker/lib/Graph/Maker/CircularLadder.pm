package Graph::Maker::CircularLadder;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Graph::Maker::Ladder;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $r = $params{rungs};

	my $g = new Graph::Maker('ladder', %params);

	return if $r == 0;

	$g->add_edge(1, $r);
	$g->add_edge($r, 1) unless $g->is_undirected();
	$g->add_edge($r+1, 2*$r);
	$g->add_edge(2*$r, $r+1) unless $g->is_undirected();

	return $g;
}

Graph::Maker->add_factory_type( 'circular_ladder' => __PACKAGE__ );

1;

__DATA__


=head1 NAME

Graph::Maker::CircularLadder - Create a circular ladder

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates the circular ladder with the specified number of rungs.
The circular ladder is a L<ladder|Graph::Maker::Ladder> graph in which the first rung and last rung are neighbors.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::CircularLadder;

	my $g = new Graph::Maker('circular_ladder', rungs => 4, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a circular ladder graph with the specified number of rungs. The
recognized parameters are rungs, and graph_maker. Any others are passed
onto Graph's constructor. If rungs is not given, it is assumed to be 0.
If graph_maker is specified it will be called to create the Graph class as
desired (for example if you have a subclass of Graph); otherwise, this defaults
to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker-circularladder at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
