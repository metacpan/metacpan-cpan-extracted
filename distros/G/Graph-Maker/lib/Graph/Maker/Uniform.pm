package Graph::Maker::Uniform;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Math::Random qw/random_uniform/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $rad = delete($params{radius}) || 0;
	my $dim = delete($params{dims}) || 2;
	my $repel = delete($params{repel}) || 0;
	my $rand = delete($params{random}) || sub { random_uniform($_[0], 0, 1) };
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	croak "rand must be a code reference\n" unless ref($rand) eq 'CODE';

	$rad **= 2;
	$repel **= 2;

	#print "\t$rad\t$repel\n";

	my @dims;
	push(@dims, 2) for (1..$n);

	my $g = $gm->(%params);

	my %pos;
	for (1..$n)
	{
		my @np = $rand->($dim);
		if($repel > 0)
		{
			redo if grep {dist2(\@np, $_) > $repel} values %pos;
		}
		$pos{$_} = [@np];
	}
	for my $v(1..$n)
	{
		$g->set_vertex_attribute($v, 'pos', $pos{$v});
		$g->add_edges($v, $_, ($g->is_directed() ? ($_, $v) : ()))
			foreach (grep {$_ != $v && dist2($pos{$v}, $pos{$_}) < $rad} keys %pos);
	}

	return $g;
}

sub dist2
{
	my ($a, $b) = @_;
	my $r = 0;
	foreach my $i(0..@$a-1)
	{
		$r += ($a->[$i] - $b->[$i]) ** 2;
	}
	#print "\t@$a <=> @$b = $r\n";
	return $r;
}

Graph::Maker->add_factory_type( 'uniform' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Uniform - Creates a graph distributed randomly over the d-dimensional grid.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a uniform graph with nodes distributed randomly over dims-dimensional unit cube.
A uniform graph distributes nodes randomly (generally uniformally) over a unit cube in some
number of dimensions, where nodes are connected iff they are with rad units of distnace of eachother and no nodes
are within repel distance of eachother.
If the graph is directed then edges are added in both directions to create an undirected graph.


	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Uniform;
	use Math::Random qw/random_normal/;

	my (@a, @b);
	@a = (2); @b = (1,1);
	$g = new Graph::Maker('uniform', N => 100, radius => 0.1, undirected => 1);
	@a = (2,3,1,2,1); @b = (2,2,1,3,1);
	$g2 = new Graph::Maker('uniform',
		N => 100,
		rad => 0.15,
		dims => 3,
		repel => 0.01,
		random => sub { random_normal($_[0], 0, 0.5) }
	); # make the nodes distributed over the cube with a gaussian (normal) distribution
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a uniform graph with N nodes randomly distributed over a dims-dimensional unit cube, where nodes are connected if
they are within rad euclidian (L2) units of distance, and no nodes are within repel distance of eachother according
to the random distribution.
The recognized parameters are N, rad, dims, repel, graph_maker, and random.
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
if rad is not given it defaults to 0.
If dims is not given it defaults to 2.
If repel is not given it defaults to 0.
if random is not given it defaults to uniform (Math::Random::random_uniform(dims, 0, 1)),
if random is given it is passed the number of random numbers that should be returned.
The vertex attribute pos will be set to an array reference of the nodes d-dimensional position.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

random

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-uniform at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
