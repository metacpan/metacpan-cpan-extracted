package Graph::Maker::Regular;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Math::Random qw/random_uniform_integer/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $k = delete($params{K}) || 0;
	$k = $n if $k > $n;
	croak "N*K (" . ($n*$k) . ") must be even\n" if ($n*$k) & 1;
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	my $g = $gm->(%params);

	my @a = (1..$n);
	my %c;

	while(@a > 1)
	{
		my @e = random_uniform_integer(2, 0, @a-1);
		if($e[0] != $e[1] && !$g->has_edge(@a[@e]))
		{
			$g->add_edge(@a[@e]);
			$g->add_edge(reverse @a[@e]) unless $g->is_undirected();
			$c{$a[$e[0]]}++;
			$c{$a[$e[1]]}++;
			#print "\tAdded @a[@e]\t[@a]\n";
			if($c{$a[$e[0]]} >= $k)
			{
				#print "\tRemoving $c{$a[$e[0]]} $a[$e[0]]\n";
				splice(@a, $e[0], 1);
				$e[1]-- if $e[1] > $e[0];
			}
			splice(@a, $e[1], 1) if $c{$a[$e[1]]} >= $k;
			#print "\t\t\t[@a]\n";
		}
		else
		{
			#print "\twarnings...$a[$e[0]] $a[$e[1]]\n";
			my $b = 0;
			foreach my $u(@a)
			{
				last if $b;
				foreach my $v(@a)
				{
					do {$b = 1; last} if $u != $v && !$g->has_edge($u, $v);
				}
			}
			next if $b;
			croak "Could not form the requested graph...\n";
		}
	}

	croak "Could not form the requested graph...\n" if @a;

	return $g;
}

Graph::Maker->add_factory_type( 'regular' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Regular - Creates a k-regular graph.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a regular graph with the number of nodes and the specified degree.
A regular graph has every node connected to exactly K other nodes.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Regular;

	my $g = new Graph::Maker('regular', N => 10, K => 2, undirected => 1);
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a k-regular graph with the number of nodes.
The recognized parameters are graph_maker, N, and K
any others are passed onto L<Graph>'s constructor.
If N is not given it defaults to 0.
If K is not given it defaults to 0.
N*K must be even.
If graph_maker is specified and is it will be called to create the Graph class as desired (for example if you have a
subclass of Graph).
Will croak with the message "Could not form the requested graph..." if it is unable to create the requested graph.

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

None at the moment...

Please report any bugs or feature requests to
C<bug-graph-maker-regular at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.

=head1 ACKNOWLEDGEMENTS

This package owes a lot to L<NetworkX|"http://networkx.lanl.gov/>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
