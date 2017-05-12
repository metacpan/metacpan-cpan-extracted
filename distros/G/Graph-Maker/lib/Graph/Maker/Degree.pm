package Graph::Maker::Degree;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker::Utils qw/is_valid_degree_seq/;
use Math::Random qw/random_permuted_index random_permutation/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n = delete($params{N}) || 0;
	my $seq = delete($params{seq}) || 0;
	my $strict = delete($params{strict});
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	croak "seq must be an array reference and be a valid degree sequence\n" unless
		defined $seq &&
		ref($seq) eq 'ARRAY'
		&& is_valid_degree_seq(@$seq);

	$n = @$seq if !$n;

	my $g = $gm->(%params);
	$g->add_vertices(1..$n);

	my @a = grep {($seq->[$_-1]||0) > 0} (1..$n); # create a list of available nodes
	# if strict use fill the largest degree nodes first
	my %c;
	my $sort = $strict ?
			sub { reverse sort {$seq->[$a-1]-($c{$a}||0) <=> $seq->[$b-1]-($c{$b}||0)} @_ } :
			sub { random_permutation(@_) };

	foreach my $v(1..$n)
	{
		$c{$v} ||= 0;
		@a = $sort->(@a);
		my $s = 0;
		#print "\t$v: $c{$v} >= $seq->[$v-1]\n";
		next unless ($seq->[$v-1]||0) > 0;
		#print "\tH\n";
		next if $c{$v} >= $seq->[$v-1];
		#print "\tB [@a]\n";
		# Add the edges specified
		for my $i(0..$seq->[$v-1]-1-$c{$v})
		{
			last unless $i-$s < @a;
			$s-- if $a[$i-$s] == $v; # be sure not to connect a node to itself
			#print "\t$v -> $a[$i-$s] |@a| $i $s\n";
			$g->add_edge($v, $a[$i-$s]);
			$g->add_edge($a[$i-$s], $v) unless $g->is_undirected();
			$c{$a[$i-$s]}++;
			$c{$v}++;
			#print "\tINC: $a[$i-$s] -> $c{$a[$i-$s]} >= $seq->[$a[$i-$s]-1] ($a[$i-$s]) (@$seq)\n";
			if($c{$a[$i-$s]} >= $seq->[$a[$i-$s]-1])
			{
				splice(@a, $i-$s, 1);
				$s++;
				#print "\tS |@a| $i $s\n";
			}
		}
		@a = grep {$_ != $v} @a;
	}


	croak "Could not build a graph with the requested sequences (@$seq)\n" if $strict &&
		scalar(grep {($seq->[$_-1]||0) != ($c{$_}||0)} (1..$n));

	return $g;
}

Graph::Maker->add_factory_type( 'degree' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Degree - Creates a graph from a degree distribution.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a graph with the given degree distribution. If the graph is directed,
then edges sare added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Degree;

	my (@a, @b);
	@a = (2,1,1);
	$g = new Graph::Maker('degree', N => 5, seq => [@a], undirected => 1);
	@a = (2,3,1,1,1);
	$g = new Graph::Maker('degree', seq => [@a], strict => 1, undirected => 1);
	ok(&checkgraph());
	# a 3-regular graph
	@a = (3,3,3,3,3,3,3,3,3,3,3,3);
	$g = new Graph::Maker('degree', seq => [@a], strict => 1, undirected => 1);
	# This will croak.
	eval {
	@a = (2,2);
	$g = new Graph::Maker('degree', N => 5, seq => [@a], undirected => 1);
	};
	warn $@;
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a graph with the given degree distribution (seq) with N nodes. The
recognized parameters are graph_maker, N and seq, and any others that are
passed onto Graph's constructor. If N is not given, it is assumed to be the
length of seq. If N is greater than seq, then the remaining values are assumed
to be zero. If strict is set, then uses a deterministic algorithm to ensure
(if possible) the correct degree distribution; otherwise it is not guaranteed that
it will have the exact distribution specified. If graph_maker is specified, it
will be called to create the Graph class (for example if you have a subclass of
Graph). Will croak if strict is turned on and it is unable to create a graph with the
given degree sequences with either the message
I<"Could not build a graph with the requested sequences (seq1), (seq2)"> or
I<"seq must be an array reference and be a valid degree sequence">.

=cut

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-smallworldws at rt.cpan.org>, or through the web interface at
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
