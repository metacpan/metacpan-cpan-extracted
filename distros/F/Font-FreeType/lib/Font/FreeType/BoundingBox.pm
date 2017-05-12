package Font::FreeType::BoundingBox;
use warnings;
use strict;

1;

__END__

=head1 NAME

Font::FreeType::BoundingBox - a structure used to hold an outline's bounding box

=head1 SYNOPSIS

    use Font::FreeType;

    my $freetype = Font::FreeType->new;
    my $face = $freetype->face('Vera.ttf');
    my ($x_min, $y_min, $x_max, $y_max) =
        ($face->x_min, $face->y_min, $face->x_max, $face->y_max);

=head1 DESCRIPTION

A structure used to hold an outline's bounding box, i.e., the coordinates of
its extrema in the horizontal and vertical directions.

The bounding box is specified with the coordinates of the lower left and the
upper right corner. In PostScript, those values are often called (llx,lly)
and (urx,ury), respectively.

If I<y_min> is negative, this value gives the glyph's descender. Otherwise, the
glyph doesn't descend below the baseline. Similarly, if I<y_max> is positive,
this value gives the glyph's ascender.

I<x_min> gives the horizontal distance from the glyph's origin to the left
edge of the glyph's bounding box. If I<x_min> is negative, the glyph extends
to the left of the origin.

=head1 METHODS

=over 4

=item x_min

=item y_min

=item x_max

=item y_max

=back

=cut
