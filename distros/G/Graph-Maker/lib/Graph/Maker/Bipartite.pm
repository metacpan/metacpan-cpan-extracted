package Graph::Maker::Bipartite;

use strict;
use warnings;
use Carp qw/croak/;
use base qw/Graph::Maker/;
use Graph;
use Graph::Maker;
use Math::Random qw/random_permuted_index random_permutation/;

our $VERSION = '0.01';

sub init
{
	my ($self, %params) = @_;

	my $n1 = delete($params{N1});
	my $n2 = delete($params{N2});
	#my $deg = delete($params{K});
	my $degSeqA = delete($params{seq1});
	my $degSeqB = delete($params{seq2});
	my $strict = delete($params{strict});
	my $gm = delete($params{graph_maker});
	croak "graph_maker must be a reference to a function that creates a Graph.\n" if $gm && ref($gm) ne 'CODE';
	$gm ||= sub { new Graph(@_); };

	my $g = $gm->(%params);

	#return random_deg($g, $n1, $n2, $deg) if $deg;
	return random_seq($g, $n1, $n2, $degSeqA, $degSeqB, $strict);
}

#sub random_deg
#{
#        my ($g, $n1, $n2, $deg) = @_;
#
#        croak "N1 must be defined and greater than 0\n" unless defined $n1 && $n1 > 0;
#        croak "N2 must be defined and greater than 0\n" unless defined $n2 && $n2 > 0;
#}

sub random_seq
{
	my ($g, $n1, $n2, $a1, $a2, $strict) = @_;

	$n1 ||= @$a1;
	$n2 ||= @$a2;

	$g->add_vertices(1..$n1+$n2);

	croak "The maximum degree in [@$a] must be $n2\n" if grep {$_ > $n2} @$a;
	croak "The maximum degree in [@$a] must be $n1\n" if grep {$_ > $n1} @$b;
	my ($sa, $sb) = (0, 0);
	$sa += $_ foreach (@$a1);
	$sb += $_ foreach (@$a2);
	croak "sum([@$a1]) must equal sum([@$b])\n" unless $sa == $sb;

	my @a = grep {($a1->[$_-1]||0) > 0} (1..$n1);
	my @b = grep {($a2->[$_-$n1-1]||0) > 0} ($n1+1..$n1+$n2);

	my %c;
	# if strict use fill the largest degree nodes first
	my $sort = $strict ?
			sub { reverse sort {$a2->[$b-$n1-1]-($c{$a}||0) <=> $a2->[$b-$n1-1]-($c{$b}||0)} @_ } :
			sub { random_permutation(@_) };

	foreach my $v(@a)
	{
		@b = $sort->(@b);
		my $s = 0;
		next unless ($a1->[$v-1]||0) > 0;
		for my $i(0..$a1->[$v-1]-1)
		{
			last unless $i-$s < @b;
			#print "\t$v -> $b[$i-$s] |@b| $i $s\n";
			$g->add_edge($v, $b[$i-$s]);
			$g->add_edge($b[$i-$s], $v) unless $g->is_undirected();
			$c{$b[$i-$s]}++;
			$c{$v}++;
			if($c{$b[$i-$s]} >= $a2->[$b[$i-$s]-$n1-1])
			{
				splice(@b, $i-$s, 1);
				$s++;
				#print "\tS |@b| $i $s\n";
			}
		}
	}

#       print "\t$_: " . ($a1->[$_-1]||0) . " " . ($c{$_}||0) . "\n" foreach (sort {$a<=>$b} (1..$n1));
#       print "\t$_: " . ($a2->[$_-$n2-1]||0) . " " . ($c{$_}||0) . "\n" foreach (sort {$a<=>$b} ($n1+1..$n1+$n2));
#       print "\n";
#
#       print "\t\t" . join(', ', grep {($a1->[$_-1]||0) == ($c{$_}||0)} (1..$n1)) . "\n";
#       print "\t\t" . join(', ', grep {($a2->[$_-$n1-1]||0) != ($c{$_}||0)} ($n1+1..$n1+$n2)) . "\n";

	croak "Could not build a graph with the requested sequences (@$a1), (@$a2)\n" if $strict &&
		(scalar(grep {($a1->[$_-1]||0) != ($c{$_}||0)} (1..$n1)) ||
		scalar(grep {($a2->[$_-$n1-1]||0) != ($c{$_}||0)} ($n1+1..$n1+$n2)));

	return $g;

}

Graph::Maker->add_factory_type( 'bipartite' => __PACKAGE__ );

1;

__DATA__

=head1 NAME

Graph::Maker::Bipartite - Creates a bipartite graph with a given distribution.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Creates a bipartite graph with the given distributions.
A bipartite graph is one in which it can be decomposed into two unique sets with edges only between these sets.
If the graph is directed then edges are added in both directions to create an undirected graph.

	use strict;
	use warnings;
        use Graph;
	use Graph::Maker;
	use Graph::Maker::Bipartite;

	my (@a, @b);
	@a = (2); @b = (1,1);
	$g = new Graph::Maker('bipartite', N1 => 5, N2 => 4, seq1 => [@a], seq2 => [@b], undirected => 1);
	@a = (2,3,1,2,1); @b = (2,2,1,3,1);
	$g2 = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b]);
	@a = (2,3,1,2,1); @b = (2,2,1,3,1);
	$g3 = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b], strict => 1, undirected => 1);
	# This distribution cannot be satisfied and the resulting graph will be incorrect
	@a = (2); @b = (2);
	eval {
		$g = new Graph::Maker('bipartite', N1 => 5, N2 => 4, seq1 => [@a], seq2 => [@b], undirected => 1);
	};
	# $@ has a message informing the graph could not be constructed
	# work with the graph

=head1 FUNCTIONS

=head2 new %params

Creates a bipartite graph with the given distributions (seq1 and seq2 respectively) with sets of size N1 and N2 respectfully.
The recognized parameters are graph_maker, N1, N2, seq1, and seq2.
any others are passed onto L<Graph>'s constructor.
If N1 is not given it is assumed to be the length of seq1, same for N2.
If N1 (N2) is greater than seq1 (seq2) then the remaining values are assumed to be zero.
If strict is set then uses a deterministic algorithm to ensure (if possible) the correct
degree distribution, otherwise it is not guarenteed that it will have the exact distribution
specified.
If graph_maker is specified it will be called to create the Graph class as desired (for example if you have a
subclass of Graph), this defaults to create a Graph with the parameters specified.
Will croak if strict is turned on and it is unable to create a graph with the given degree sequences with the message
"Could not build a graph with the requested sequences (seq1), (seq2)".

=cut

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Quite possibly, but hopefully not.

Please report any bugs or feature requests to
C<bug-graph-maker-randombipartite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

