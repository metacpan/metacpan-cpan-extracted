package Image::RGBA;

=head1 NAME

Image::RGBA - Functions for sampling simple RGBA images

=head1 SYNOPSIS

'simple', 'bilinear' and 'bicubic' image sampling.

=head1 DESCRIPTION

Hides some of the ugly stuff involved when sampling individual pixel
values from images.  A good range of quality levels are provided,
currently; simple, linear and spline16.

For an explanation of what is going on, see:

 http://www.fh-furtwangen.de/~dersch/interpolator/interpolator.html

An RGBA image file is very simple, just each channel stored one after
the other with no delimiters for each pixel in turn.  There is no header
data, so you have to know the image dimensions to reconstruct an RGBA
image.

=head1 USAGE

You can start by creating an Image::Magick object:

    my $input = new Image::Magick;
    $input->Read ('input.jpg');

=cut

use strict;
use warnings;

use Image::Magick;

our $VERSION = '0.04';

=pod

Use an Image::Magick object as the basis of an Image::RGBA
object:

    my $rgba = new Image::RGBA (sample => 'linear',
                                 image => $input);

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;

    my $params = {@_};

    my $imagemagick = $params->{image};

    my $self;

    # we can get the width and height from the source image

    $self->{height} = $imagemagick->Get('height');
    $self->{width}  = $imagemagick->Get('width');

    # this is the raw rgba data

    $self->{blob} = _imagetoblob ($imagemagick);

    # a sensible default sampling level

    $self->{sample} = $params->{sample} || 'linear';

    bless $self, $class;

    return $self;
}

=pod

Now you can retrieve a string representing the RGBA pixel values
of any point in the original image:

    $values = $rgba->Pixel (20.2354, 839.6556);

Additionally, you can write RGBA pixel values directly to an image by appending
the values that need to be written:

    $rgba->Pixel (22, 845, $values);

Note that locations for writing need to be integer values.

=cut

sub Pixel
{
    my $self = shift;

    my $m = shift;
    my $n = shift;

    if (scalar @_) 
    {
        my $rgba = shift;

        my $pixel_offset = (int ($m) + ($self->{width} * (int ($n) - $self->{height})));

        $self->_set_offset ($pixel_offset, $rgba);

        return;
    };

    my ($r, $g, $b, $a) = $self->_sample ($m, $n);

    return $self->_pack ($r, $g, $b, $a);
}

=pod

You can access the image as an Image::Magick object at any time using the Image
method:

    $rgba->Image->Write ('filename.jpg');

=cut

sub Image
{
    my $self = shift;

    $self->_blobtoimage;
}

=pod

=head1 OPTIONS

=head2 SAMPLING TYPES

=cut

sub _sample
{
    my $self = shift;

    my $m = shift;
    my $n = shift;

=pod

Note that trying to sample values physically outside of the source image will
return a black/transparent pixel value consisting of null bytes.

=cut

    return (0, 0, 0, 0)
        if ($m < 0 or $m > $self->{width} or $n < 0 or $n > $self->{height});

    my ($r, $g, $b, $a);

    if ($self->{sample} eq 'simple')
        { ($r, $g, $b, $a) = $self->_simple ($m, $n) }

    elsif ($self->{sample} eq 'linear')
        { ($r, $g, $b, $a) = $self->_linear ($m, $n) }

    elsif ($self->{sample} eq 'spline16')
        { ($r, $g, $b, $a) = $self->_spline16 ($m, $n) }

    return ($r, $g, $b, $a);
}

=pod

'simple' sampling is crude non-interpolated pixel sampling, equivalent
to the Image::Magick::Get ("pixel[$x,$y]") method.  Use this when speed
rather than quality is required.

=cut

sub _simple
{
    my $self = shift;

    my $m = shift;
    my $n = shift;

    # find the nearest pixel if it's over the edge of the source image

    $m = 0 if ($m < 0);
    $n = 0 if ($n < 0);
    $m = $self->{width} - 1 if ($m > $self->{width} - 1);
    $n = $self->{height} - 1 if ($n > $self->{height} - 1);

    # get raw rgba value corresponding to $m and $n

    my $pixel_offset = (int ($m) + ($self->{width} * (int ($n) - $self->{height})));

    my $rgba = $self->_get_offset ($pixel_offset);

    $self->_unpack ($rgba);
}

=pod

'linear' sampling is fast general purpose pixel sampling, about 3
times slower than 'simple' sampling'.  Pixel values are interpolated, so
sampling pixel (45.5, 56.6) will get different results to pixel (45,
56).

=cut

sub _linear
{
    my $self = shift;

    my $m = shift;
    my $n = shift;

    my ($r, $g, $b, $a);

    for my $v (0 .. 1)
    {
        for my $u (0 .. 1)
        {
            my ($r0, $g0, $b0, $a0) = $self->_simple ($m + $u, $n + $v);

            my $weightxy = (1 - abs ($m - int ($m) - $u)) * (1 - abs ($n - int ($n) - $v));

            $r += $r0 * $weightxy;
            $g += $g0 * $weightxy;
            $b += $b0 * $weightxy;
            $a += $a0 * $weightxy;
        }
    }

    return ($r, $g, $b, $a);
}

=pod

'spline16' sampling is slow high-quality sampling, about 15 times
slower than 'simple' sampling.  Interpolated pixel values are just a
little bit higher quality than 'linear'.

=cut

sub _spline16
{
    my $self = shift;

    my $m = shift;
    my $n = shift;

    my ($r, $g, $b, $a);

    for my $v (-1 .. 2)
    {
        for my $u (-1 .. 2)
        {
            my ($r0, $g0, $b0, $a0) = $self->_simple ($m + $u, $n + $v);

            my $x = abs ($m - int ($m) - $u);
            my $y = abs ($n - int ($n) - $v);

            my ($weightx, $weighty);
           
            if ($x >= 1 && $x <= 2)
            { $weightx = ((((12 - (5 * ($x - 1))) / 15) * ($x - 1)) - (7/15)) * ($x - 1) }

            else
            { $weightx = (((($x - 1.8) * $x) - 0.2) * $x) + 1 }

            if ($y >= 1 && $y <= 2)
            { $weighty = ((((12 - (5 * ($y - 1))) / 15) * ($y - 1)) - (7/15)) * ($y - 1) }

            else
            { $weighty = (((($y - 1.8) * $y) - 0.2) * $y) + 1 }

            my $weightxy = $weightx * $weighty;

            $r += $r0 * $weightxy;
            $g += $g0 * $weightxy;
            $b += $b0 * $weightxy;
            $a += $a0 * $weightxy;
        }
    }

    # fix minor floating point errors, yes this is ugly.
    
    $r += 0.001;
    $g += 0.001;
    $b += 0.001;
    $a += 0.001;

    ($r, $g, $b, $a) = $self->_valid_pixel_values ($r, $g, $b, $a);

    return ($r, $g, $b, $a);
}

# various operations, curve fitting and brightness correction, can create
# non valid <0 >255 values, fix'em.
# 
# FIXME should support other than 1 byte per channel

sub _valid_pixel_values
{
    my $self = shift;

    my ($r, $g, $b, $a) = @_;

    $r = 255 if ($r > 255);
    $g = 255 if ($g > 255);
    $b = 255 if ($b > 255);
    $a = 255 if ($a > 255);

    $r = 0 if ($r < 0);
    $g = 0 if ($g < 0);
    $b = 0 if ($b < 0);
    $a = 0 if ($a < 0);

    return ($r, $g, $b, $a);
}

# take an array of pixel values and return packed bytes
# 
# FIXME should support other than 1 byte per pixel
    
sub _pack
{
    my $self = shift;

    my ($r, $g, $b, $a) = @_;

    pack ("CCCC", int ($r), int ($g), int ($b), int ($a));
}

# take packed bytes and return an array of pixel values
# 
# FIXME should support other than 1 byte per channel

sub _unpack
{
    my $self = shift;

    my $rgba = shift;
    
    map ord (substr $rgba, $_), (0, 1, 2, 3);
}

# retrieve raw bytes for a particular offset
# 
# FIXME should support other than 1 byte per channel

sub _get_offset
{
    my $self = shift;

    my $pixel_offset = shift;

    substr ${$self->{blob}}, 4 * $pixel_offset, 4;
}

# sets and retrieves raw bytes for a particular offset
# 
# FIXME should support other than 1 byte per channel

sub _set_offset
{
    my $self = shift;

    my $pixel_offset = shift;
    my $rgba = shift;

    substr ${$self->{blob}}, 4 * $pixel_offset, 4, $rgba;
}

# only used in new().  converts from imagemagick to a simpler format
# 
# FIXME should support other than 1 byte per pixel

sub _imagetoblob
{
    my $imagemagick = shift;

    $imagemagick->Set (magick => 'RGBA', depth => '8');
    \$imagemagick->ImageToBlob;
}

# used when we have an Image::RGBA object but we really need an
# Image::Magick object
# 
# FIXME should support other than 1 byte per pixel

sub _blobtoimage
{
    my $self = shift;

    my $imagemagick = new Image::Magick (magick => 'RGBA',
                                          depth => '8',
                                           size => $self->{width} ."x". $self->{height});

    $imagemagick->BlobToImage (${$self->{blob}});

    return $imagemagick;
}

=pod

=head1 COPYRIGHT

Copyright (c) 2002 Bruno Postle <bruno@postle.net>. All Rights Reserved.
This module is Free Software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut

1;

