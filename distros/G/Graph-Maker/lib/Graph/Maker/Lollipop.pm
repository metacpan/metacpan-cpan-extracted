package Graph::Maker::Lollipop;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n1 = delete($params{N1});
	my $n2 = delete($params{N2});
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	croak "n1 must be defined and greater than 1\n" unless defined $n1 && $n1 >= 2;
	croak "n2 must be defined and positive\n" unless defined $n2 && $n2 >= 0;

	my $g = $gm->(%params);

	# Left
	for my $u(1..$n1)
	{
		my $min = $g->is_directed() ? 1 : $u+1;
		for my $v($min..$n1)
		{
			next if $u == $v;
			$g->add_edge($u, $v);
		}
	}
	# Bar
	$g->add_path($n1..$n1+$n2);
	$g->add_path(reverse $n1..$n1+$n2) if $g->is_directed();

	return $g;
}

Graph::Maker->add_factory_type( 'lollipop' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Lollipop - Creates a lollipop graph.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates the lollipop graph with N1 nodes on the left and N2 nodes in a bar.
A lollipop graph is one in which there is one fully-connected components of
size N1 connected to a single path of N2 nodes.  If the graph is directed
then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Lollipop;

	my $g = new Graph::Maker('lollipop', N1 => 4, N2 => 2);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates the lollipop graph with N1 nodes on the left and N2 nodes in
the bar, The recognized parameters are N1 (N1 >= 2), N2 (N2 >=
0), graph_maker, and any others are passed onto Graph's
constructor. If graph_maker is specified, it will be called to create
the Graph class (for example if you have a subclass of
Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-lollipop at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Graph::Maker::Lollipop
