package Graph::MoreUtils::Smooth;

# ABSTRACT: Generate smoothed graphs
our $VERSION = '0.3.0'; # VERSION

use strict;
use warnings;

use Graph::MoreUtils::Smooth::Intermediate;
use Graph::Undirected;
use Scalar::Util qw( blessed );

sub smooth
{
    my( $graph ) = @_;

    if( !blessed $graph || !$graph->isa( Graph::Undirected:: ) ) {
        die 'only Graph::Undirected and its derivatives are accepted' . "\n";
    }

    for ($graph->vertices) {
        next unless $graph->degree( $_ ) == 2;
        my( $a, $b ) = sort $graph->neighbours( $_ );

        # do not reduce cycles of three vertices:
        next if $graph->has_edge( $a, $b );

        my $intermediate;
        if( $graph->has_edge_attribute( $a, $_, 'intermediate' ) &&
            $graph->has_edge_attribute( $b, $_, 'intermediate' ) ) {
            $intermediate = Graph::MoreUtils::Smooth::Intermediate->new(
                $_ lt $a
                    ? $graph->get_edge_attribute( $a, $_, 'intermediate' )->reverse
                    : $graph->get_edge_attribute( $a, $_, 'intermediate' ),
                $_,
                $_ gt $b
                    ? $graph->get_edge_attribute( $b, $_, 'intermediate' )->reverse
                    : $graph->get_edge_attribute( $b, $_, 'intermediate' ) );
        } elsif( $graph->has_edge_attribute( $a, $_, 'intermediate' ) ) {
            $intermediate = $graph->get_edge_attribute( $a, $_, 'intermediate' );
            $intermediate->reverse if $a gt $_; # getting natural order
            push @$intermediate, $_;
        } elsif( $graph->has_edge_attribute( $b, $_, 'intermediate' ) ) {
            $intermediate = $graph->get_edge_attribute( $b, $_, 'intermediate' );
            $intermediate->reverse if $_ gt $b; # getting natural order
            unshift @$intermediate, $_;
        } else {
            $intermediate = Graph::MoreUtils::Smooth::Intermediate->new( $_ );
        }

        $graph->delete_vertex( $_ );
        $graph->set_edge_attribute( $a, $b, 'intermediate', $intermediate );
    }

    return $graph;
}

1;
