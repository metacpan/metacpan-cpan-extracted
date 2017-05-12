package Geo::JSON::Utils;

our $VERSION = '0.007';

use strict;
use warnings;
use Carp;

use base 'Exporter';

our @EXPORT_OK = qw/ compare_positions compute_bbox /;

# TODO improve - need to ensure floating points are the same
sub compare_positions {
    my ( $pos1, $pos2 ) = @_;

    # Assume positions have same number of dimensions
    my $dimensions = defined $pos1->[2] ? 2 : 1;

    foreach my $dim ( 0 .. $dimensions ) {

        # TODO fix stringification problems...?
        return 0
            if ( defined $pos1->[$dim] && !defined $pos2->[$dim] )
            || ( !defined $pos1->[$dim] && defined $pos2->[$dim] )
            || ( $pos1->[$dim] != $pos2->[$dim] );
    }

    return 1;
}

sub compute_bbox {
    my $positions = shift;    # arrayref of positions

    croak "Need an array of at least 2 positions"
        unless ref $positions
        && ref $positions eq 'ARRAY'
        && @{$positions} > 1;

    # Assumes all have same number of dimensions

    my $dimensions = scalar @{ $positions->[0] } - 1;

    my @min = my @max = @{ $positions->[0] };

    foreach my $position ( @{$positions} ) {
        foreach my $d ( 0 .. $dimensions ) {
            $min[$d] = $position->[$d] if $position->[$d] < $min[$d];
            $max[$d] = $position->[$d] if $position->[$d] > $max[$d];
        }
    }

    return [ @min, @max ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::Utils - Util methods for Geo::JSON classes

=head1 SYNOPSIS

    use Geo::JSON::Utils qw/ compare_positions compute_bbox /;

=head1 DESCRIPTION

Util methods for L<Geo::JSON>

=head1 METHODS

=head2 compare_positions

    if (Geo::JSON::Utils::compare_positions( $pt1, $pt2 )) {
        # positions of points are the same
    }

Compare two points. Compares in up to three dimensions. Any further
dimensions are ignored.

=cut


=head2 compute_bbox

    my $bbox = Geo::JSON::Utils::compute_bbox( \@positions );

Computes a bounding box for an arrayref of positions. The bounding box is
a list of all minimum values for all axes followed by all maximum values. The
values are in the order the axis they appear in the position geometry.

Assumes all points will have same number of dimensions as the first.

=cut

=head1 TODO

=over

=item *

Improve comparisons of floating point coordinates, look at stringification
issues, etc.

=back

=cut

