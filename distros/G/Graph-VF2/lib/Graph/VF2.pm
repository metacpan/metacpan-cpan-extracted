package Graph::VF2;

# ABSTRACT: VF2 subgraph isomorphism detection method for Perl Graph
our $VERSION = '0.1.0'; # VERSION

=head1 NAME

Graph::MoreUtils - VF2 subgraph isomorphism detection method for Perl Graph

=head1 SYNOPSIS

    use Graph::Undirected;
    use Graph::VF2 qw( matches );

    my $small = Graph::Undirected->new;
    my $large = Graph::Undirected->new;

    # Create graphs here

    # Find all subgraphs of $small in $large:
    my @matches = matches( $small, $large );

=cut

use strict;
use warnings;

use Graph::Undirected;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    matches
);

require XSLoader;
XSLoader::load('Graph::VF2', $VERSION);

=head1 METHODS

=head2 C<matches( $g1, $g2, $options )>

Takes two L<Graph::Undirected> objects, C<$g1> and C<$g2> and returns an array of occurrences of C<$g1> in C<$g2>.
Returned array consists of array references, each array reference describing one occurrence.
In it, encoded as array references, is the list of pairwise vertex correspondences.
First item in a pair is a vertex from C<$g1>, and second item being a vertex in C<$g2>.
No attempt is made to collate isomorphic matches.
Thus a search of N-element cycle graph in itself will produce 2 * N matches due to graph's symmetry.

C<$options> is a hash reference of options with the following keys:

=over

=item C<vertex_correspondence_sub>

A subroutine reference used to evaluate the equality of vertices, called with C<$v1> and C<$v2> from C<$g1> and C<$g2>, accordingly.
Should return Perl true and false equivalents to signify match and non-match, accordingly.
Unless provided, all vertices are treated as equal.

=back

=cut

sub matches
{
    my( $g1, $g2, $options ) = @_;

    die 'input graphs must be undirected'
        unless $g1->isa( Graph::Undirected:: ) && $g2->isa( Graph::Undirected:: );

    $options = {} unless $options;
    my $vertex_correspondence_sub = exists $options->{vertex_correspondence_sub}
                                         ? $options->{vertex_correspondence_sub}
                                         : sub { 1 };

    my @vertices1 = $g1->vertices;
    my %vertices1 = map { $vertices1[$_] => $_ } 0..$#vertices1;
    my @edges1    = map { [ $vertices1{$_->[0]}, $vertices1{$_->[1]} ] } $g1->edges;
    my @vertices2 = $g2->vertices;
    my %vertices2 = map { $vertices2[$_] => $_ } 0..$#vertices2;
    my @edges2    = map { [ $vertices2{$_->[0]}, $vertices2{$_->[1]} ] } $g2->edges;

    my $map = [];
    for my $vertex (@vertices1) {
        push @$map, [ map { int $vertex_correspondence_sub->($vertex, $_) } @vertices2 ];
    }

    my $correspondence = _vf2( \@vertices1, \@edges1, \@vertices2, \@edges2, $map );

    my @matches;
    while (my @match = splice @$correspondence, 0, 2 * @vertices1) {
        push @matches, [ map { [ $vertices1[$match[2 * $_]],
                                 $vertices2[$match[2 * $_ + 1]] ] }
                             0..$#vertices1 ];
    }

    return @matches;
}

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
