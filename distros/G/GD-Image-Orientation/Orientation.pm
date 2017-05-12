package GD::Image::Orientation;

use strict;
use warnings;
use GD;

our $VERSION = '0.05';

sub GD::Image::vertical {
    my $gdo = shift;
    my $ccw = shift || 0;
    my $dosq = shift() ? 0 : 1;
    if(!$gdo->isvertical($dosq)) {
        if($ccw) { return $gdo->copyRotate270 } 
        else { return $gdo->copyRotate90 }
    }
    return $gdo;
}

sub GD::Image::horizontal {
    my $gdo = shift;
    my $ccw = shift || 0;
    my $dosq = shift() ? 0 : 1;
    if(!$gdo->ishorizontal($dosq)) {
        if($ccw) { return $gdo->copyRotate270 } 
        else { return $gdo->copyRotate90 }
    }
    return $gdo;
}

sub GD::Image::isvertical {
    my ($w,$h) = shift->getBounds;
    return 1 if $h >= $w && shift;
    return 1 if $h > $w;
    return 0;
}

sub GD::Image::ishorizontal {
    my ($w,$h) = shift->getBounds;
    return 1 if $w >= $h && shift;
    return 1 if $w > $h;
    return 0;
}

sub GD::Image::issquare {
    my ($w,$h) = shift->getBounds;
    return 1 if $h == $w;
    return 0; 
}

sub GD::Image::orientation {
    my $gdo = shift;
    return 'square' if $gdo->issquare;
    return 'vertical' if $gdo->isvertical;
    return 'horizontal' if $gdo->ishorizontal;
    return undef; # should never get here 
}

1;
__END__

=head1 NAME

GD::Image::Orientation - Perl extension for managing a GD::Image's vertical or horizontal orientation (shapewise)

=head1 SYNOPSIS

    use GD::Image::Orientation;

    for(@images) {
        my $img = GD::Image->new($_) or die $!;
        $dbh->do("INSERT INTO photogallery.metainfo (Id,Orientation,File) VALUES (NULL,$img->isvertical,$dbh->quote($_))") or die $dbh->errstr;
    }

=head1 DESCRIPTION

Adds functionality to GD by adding class methods to determine orientation in boolean terms or in a string.
Also included methods to set an image's orientation;

=head2 isvertical()

    $img->isvertical()

Returns true if an image's height is greater than it's width.
Call it with a true argument:

    $img->isvertical(1)

and it returns true if an image's height is greater than it's width or it is square.

=head2 ishorizontal()

    $img->ishorizontal()

Returns true if an image's width is greater than it's height.
Call it with a true argument:

    $img->ishorizontal(1)
 
and it returns true if an image's width is greater than it's height or it is square.

=head2 issquare()

Returns true if an image's width and height are the same.

=head2 orientation()

Returns a string describing its orientation in English.
It returns 'horizontal', 'vertical', or 'square'

    print 'The image you uploaded is ' . $img->orientation . "<br />\n";

=head2 vertical()

If the image is horizontal it is rotated 90 degrees clockwise to become vertical.
Call it with a true argument and it's rotated 90 degrees counter clockwise to become vertical. 

It returns a new GD::Image object if modified or the original object if its already vertical or square.

    my $vert_img = $img->vertical;  # rotate $img clockwise 90 degrees if its horizontal
    my $vert_img = $img->vertical(1); # rotate $img counter clockwise 90 degrees if its horizontal
    $img = $img->vertical; # rotate $img clockwise 90 degrees if its horizontal, modifying the original object

If the second argument is true it will rotate it even if its sqare:

    my $vert_img = $img->vertical(0,1); # rotate $img clockwise if its horizontal or square
    my $vert_img = $img->vertical(1,1); # rotate $img counter clockwise if its horizontal or square

=head2 horizontal()

If the image is vertical it is rotated 90 degrees clockwise to become horizontal.
Call it with a true argument and it's rotated 90 degrees counter clockwise to become horizontal.

It returns a new GD::Image object if modified or the original object if its already horizontal or square.

    my $hori_img = $img->horizontal;  # rotate $img clockwise 90 degrees if its vertical
    my $hori_img = $img->horizontal(1); # rotate $img counter clockwise 90 degrees if its vertical
    $img = $img->horizontal; # rotate $img clockwise 90 degrees if its vertical, modifying the original object

If the second argument is true it will rotate it even if its square:

    my $vert_img = $img->horizontal(0,1); # rotate $img clockwise if its vertical or square
    my $vert_img = $img->horizontal(1,1); # rotate $img counter clockwise if its vertical or square

=head1 TO DO

I'd like to add functionality to modify the original image object if called in void context:

   $img->vertical;
   $img->horizontal;

=head1 SEE ALSO

    L<GD>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl> 

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
