package Graph::MoreUtils::SSSR;

# ABSTRACT: Find the Smallest Set of Smallest Rings in graph
our $VERSION = '0.3.0'; # VERSION

use strict;
use warnings;

sub SSSR
{
    my( $graph, $max_depth ) = @_;

    return
        map { detect_rings( $graph, $_, undef, undef, $max_depth ) }
            $graph->vertices;
}

# This subroutine will return cycle base not containing 1-vertex-connected graphs.
# TODO: Finish
sub get_cycle_base
{
    my( $graph, $max_depth ) = @_;

    my @SSSR = SSSR( $graph, $max_depth );
    my %edge_participation;
    for my $cycle (@SSSR) {
        for my $i (0..$#$cycle) {
            my $edge = join '', $cycle->[$i     % @$cycle],
                                $cycle->[($i+1) % @$cycle];
            $edge_participation{$edge} = [] unless $edge_participation{$edge};
            push @{$edge_participation{$edge}}, $cycle;
        }
    }

    # TODO: Cycle through all mutual edges and perform cycle addition
}

sub detect_rings
{
    my ( $graph, $atom, $original_atom, $previous_atom,
         $level, $seen_atoms ) = @_;

    return () if defined $level && !$level;

    $seen_atoms = {} unless defined $seen_atoms;
    $original_atom = $atom unless defined $original_atom;

    my %seen_atoms = ( %$seen_atoms,
                       $atom => { atom     => $atom,
                                  position => scalar keys %$seen_atoms } );

    my @rings;

    # First, look if we have Nachbarpunkte of the current path
    # _different_ from the original atom. If yes, we will discard this
    # cycle since it could be closed in a shorter way:

    for my $neighbour_atom ( $graph->neighbours( $atom ) ) {
        next if $neighbour_atom eq $original_atom;
        next if defined $previous_atom && $previous_atom eq $neighbour_atom;
        next if !exists $seen_atoms->{$neighbour_atom};

        return @rings;
    }

    # If no Nachbarpunkte are found in the previous search, let's look
    # if we can close the ring. If we do so, we set the
    # $Nachbarpunkte_detected flag, so that the search for rings does
    # not go on (the current atom and the original atom would be
    # Nachbarpunkte in any larger cycle containing the current path:

    if( scalar keys %seen_atoms > 2 ) {
        for my $neighbour_atom ( $graph->neighbours( $atom ) ) {
            next if $neighbour_atom ne $original_atom;

            # Detect a ring:

            my @sorted_ring =
                sort_ring_elements( map  { $seen_atoms{$_}->{atom} }
                                    sort { $seen_atoms{$a}->{position} <=>
                                           $seen_atoms{$b}->{position} }
                                         keys %seen_atoms );
            return @rings, \@sorted_ring;
        }
    }

    # Descend the new path in the neighbourhood graph:
    for my $neighbour_atom ( $graph->neighbours( $atom ) ) {
        next if exists $seen_atoms->{$neighbour_atom};
            
        push @rings,
             detect_rings( $graph,
                           $neighbour_atom,
                           $original_atom,
                           $atom,
                           defined $level ? $level - 1 : undef,
                           \%seen_atoms );
    }

    return @rings;
}

sub sort_ring_elements
{
    my( @elements ) = @_;

    return @elements if scalar @elements <= 1;

    my $min_index;
    my $reverse;
    for my $i (0..$#elements) {
        next if defined $min_index && $elements[$i] ge
                                      $elements[$min_index];
        $min_index = $i;
        $reverse = $elements[($i-1) % scalar @elements] lt
                   $elements[($i+1) % scalar @elements];
    }

    if( $reverse ) {
        @elements = reverse @elements;
        $min_index = $#elements - $min_index;
    }

    return @elements[$min_index..$#elements],
           @elements[0..$min_index-1];
}

1;
