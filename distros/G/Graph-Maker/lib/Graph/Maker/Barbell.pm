package Graph::Maker::Barbell;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;

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
	$g->add_path($n1..$n1+$n2+1);
	$g->add_path(reverse $n1..$n1+$n2+1) if $g->is_directed();
	# Right
	for my $u(1..$n1)
	{
		my $min = $g->is_directed() ? 1 : $u+1;
		for my $v($min..$n1)
		{
			next if $u == $v;
			$g->add_edge($n1+$n2+$u, $n1+$n2+$v);
		}
	}

	return $g;
}

Graph::Maker->add_factory_type( 'barbell' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Barbell - Create barbell graphs

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates the barbell graph with N1 nodes on the left, N1 nodes on the right
and N2 nodes in the center bar. A barbell graph is one in which there
are two fully-connected components of size N1 connected by a single bridge
of N2 nodes. If the graph is directed, then edges are added in both directions
to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Barbell;

	my $g = new Graph::Maker('barbell', N1 => 4, N2 => 2);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates the barbell graph with N1 nodes on the left and right and N2 nodes in the center bar,
The recognized parameters are graph_maker, N1 and N2
any others are passed onto L<Graph>'s constructor.
If N1 is not given it defaults to 0.
If N2 is not given it defaults to 0.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker-barbell at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
