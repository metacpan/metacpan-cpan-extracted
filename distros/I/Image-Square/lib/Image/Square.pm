package Image::Square;

use strict;
use warnings;
use Carp ('croak');
use GD;

our $VERSION = '1.0';
$VERSION = eval $VERSION;

GD::Image->trueColor(1);

sub new {
    my ($class, $image) = @_;
    
    unless ( $class and defined $image) {
        croak 'Image::Square->new(): image required';
    }
    
    my $gd;
    
    if (ref $image eq 'GD::Image') {
        $gd = $image;
    } else {
        unless ( -e $image ) {
            croak "Image::Square->new(): file '$image' not found";
        }
        $gd = GD::Image->new($image) or die $@;
    }
    
    return bless {
        'gd'    => $gd,
    }, $class;
}

sub square {
    my $self = shift;
    my ($size, $pos) = @_;
    
    $pos = 0.5 unless defined $pos;
    
    if ($pos < 0 or $pos > 1) {
        croak "Image::Square->square(): pos out of range!  0-1 allowed";
    }
    
    my $width = $self->{'gd'}->width;
    $width = $self->{'gd'}->height if $self->{'gd'}->height < $width;
    my $source = $width;
    $width = $size if $size and $size > 0;
 
    my $square = GD::Image->new($width, $width);
    if ($self->{'gd'}->width > $self->{'gd'}->height) {
        $square->copyResampled($self->{'gd'}, 0, 0, ($self->{'gd'}->width - $source) * $pos, 0, $width, $width, $source, $source);
    } else {
        $square->copyResampled($self->{'gd'}, 0, 0, 0, ($self->{'gd'}->height - $source) * $pos, $width, $width, $source, $source);
    }
    
    return $square;
}

=head1 NAME

Image::Square - Crop and resize an image to create a square image

=head1 SYNOPSIS

  use Image::Square;

  # Create a new Image::Square object from an image file
  my $img = Image::Square->new('example.jpg');

  # Create a square image from the source image with default settings
  my $square_img = $img->square();

  # Create a square image of a specific size (e.g., 200x200 pixels)
  my $custom_size_square = $img->square(200);

  # Create a square image from a specific position (e.g., center)
  my $center_square = $img->square(0, 0.5);

=head1 DESCRIPTION

The C<Image::Square> module provides a simple way to crop and resize an image to create a square image. This can be useful when you need to prepare images for applications that require square thumbnails or avatars.

=head1 ERROR HANDLING

C<Image::Square> will C<croak> if it detects a problem.

=head1 METHODS

=head2 new

  my $img = Image::Square->new('example.jpg');

Creates a new C<Image::Square> object from an image file specified by the file path. The image file should be in a format supported by the L<GD> module.  Alternatively, a L<GD::Image> object is accepted.

=head2 square

  my $square_img = $img->square($size, $pos);

Creates a square image from the source image. The method takes two optional parameters:

=over 4

=item *

C<$size> - The size of the output square image in pixels. If not provided or set to 0, the size will be determined based on the smaller dimension of the source image. (default: 0)

=item *

C<$pos> - The position in the source image to create the square image from. This parameter accepts values between 0 and 1, where 0 represents the left or top edge, 0.5 represents the middle, and 1 represents the right or bottom edge. (default: 0.5)

=back

The method returns a new L<GD::Image> object that represents the square image.

=head1 AUTHOR

Ian Boddison <ian at boddison.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-square at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=image-square>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::Square

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-Square>

=item * Search CPAN

L<https://metacpan.org/release/Image::Square>

=item * GitHub

L<https://github.com/IanBod/Image-Square>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ian Boddison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;


    
