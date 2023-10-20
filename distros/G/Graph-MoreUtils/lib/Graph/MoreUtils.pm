package Graph::MoreUtils;

# ABSTRACT: Utilities for graphs
our $VERSION = '0.1.0'; # VERSION

=head1 NAME

Graph::MoreUtils - utilities for graphs

=head1 SYNOPSIS

    use Graph::MoreUtils qw( SSSR line smooth );
    use Graph::Undirected;

    my $G = Graph::Undirected->new;

    # Greate graph here

    # Get line graph for $G:
    my $L = line( $G );

=cut

use strict;
use warnings;

use parent Exporter::;

use Graph::MoreUtils::Line;
use Graph::MoreUtils::SSSR;
use Graph::MoreUtils::Smooth;

our @EXPORT_OK = qw(
    SSSR
    line
    smooth
);

=head2 C<SSSR( $graph, $max_depth )>

Finds the Smallest Set of Smallest Rings (SSSR) in L<Graph> objects.
Thus it should work with any L<Graph::Undirected> object.
The code is largely taken from the C<cod-tools> package (L<https://wiki.crystallography.net/cod-tools/>).

The algorithm returns a superset of minimum cycle basis of a graph in order to produce deterministic results.
As a result it does not succumb to the counterexample of oxabicyclo[2.2.2]octane (L<https://depth-first.com/articles/2020/08/31/a-smallest-set-of-smallest-rings/>, section "SSSR and Uniqueness").
The algorithm has means to control the maximum size of rings included in the SSSR to reduce its complexity.
The default value of C<undef> stands for no limit.

=cut

sub SSSR { &Graph::MoreUtils::SSSR::SSSR }

=head2 C<line( $graph )>

Generates line graphs for L<Graph::Undirected> objects.
Line graph is constructed nondestructively and returned from the call.
Both simple and multiedged graphs are supported.

Call accepts additional options hash.
Currently only one option is supported, C<loop_end_vertices>, which treats the input graph as having self-loops on pendant vertices, that is, increasing the degrees of vertices having degrees of 1.
Thus they are not "lost" during line graph construction.
In the resulting line graph these self-loops are represented as instances of L<Graph::MoreUtils::Line::SelfLoopVertex>.

=cut

sub line { &Graph::MoreUtils::Line::line }

=head2 C<smooth( $graph )>

Smooths the given graph by collating vertices of degree 2.

=cut

sub smooth { &Graph::MoreUtils::Smooth::smooth }

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
