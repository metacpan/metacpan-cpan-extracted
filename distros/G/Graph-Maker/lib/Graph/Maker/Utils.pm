package Graph::Maker::Utils;

use warnings;
use strict;
use Graph;
use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT_OK = qw(cartesian_product is_valid_degree_seq);  # symbols to export on request
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $VERSION = '0.02';

sub cartesian_product
{
	my ($g, $h) = @_;

	my $p = $g->copy();
	$p->delete_vertices($g->vertices());

	my $G = $g->vertices();

	foreach my $e($h->edges())
	{
		foreach my $v($g->vertices())
		{
			$p->add_edge($v + $G*($e->[0]-1), $v + $G*($e->[1]-1));
		}
	}

	foreach my $e($g->edges())
	{
		foreach my $v($h->vertices())
		{
			$p->add_edge($e->[0] + $G*($v-1), $e->[1] + $G*($v-1));
		}
	}
	return $p;
}

# BIG BIG copy from NetworkX, only rewrote...
sub is_valid_degree_seq
{
	my (@seq) = @_;

        return 1 if @seq == 0; # good if empty
	my $s = 0;
	$s += $_ foreach (@seq);
	return 0 if $s & 1; # must be even

	while(@seq)
	{
		@seq = reverse sort {$a<=>$b} @seq;

		return 0 if $seq[0] < 0;

		my $d = pop(@seq);
		return 1 if $d == 0;

		return 0 if $d > @seq;

		$seq[@seq-$_]-- for (1..$d);
	}

	return 0;
}

__DATA__

=head1 NAME

Graph::Maker::Utils - Small routines that Graph::Maker::* uses.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Some utility functions for L<Graph>s.

	use strict;
	use warnings;
	use Graph::Maker;
	use Graph::Maker::Linear;
	use Graph::Maker::Utils qw/is_valid_degree_seq cartesian_product/;

	my @seq = (2, 1, 1);
	my $bool = is_valid_degree_seq(@seq); # returns true
	my @se2 = (2, 1, 1, 1)
	my $boo2 = is_valid_degree_seq(@se2); # returns false

	my $g1 = new Graph::Maker('linear', N => 10);
	my $g2 = new Graph::Maker('linear', N => 10);
	my $g = cartesian_product($g1, $g2); # returns the 2-dimensional plane


=head1 EXPORT

Nothing by default, specify any set of functions, or :all to import everything.

=head1 FUNCTIONS

=head2 cartesian_product $g, $h

Creates a new graph that is the cartesian product of $g and $h.  For example, the cartesian product of two linear
graphs is a grid graph.

=head2 is_valid_degree_seq @seq

Tests if @seq is a valid degree sequence, that is if it can be used to generate a graph.  This is mainly used in other
Graph::Maker packages.

=head1 AUTHOR

Matt Spear, C<< <batman900+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-maker-smallworldws at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

This package owes a lot to L<NetworkX|"http://networkx.lanl.gov/>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Matt Spear, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
