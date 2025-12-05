package Image::ThumbHash;
use strict;
use warnings qw(all FATAL uninitialized);

use Carp qw(croak);
use Exporter 5.57 qw(import);

our $VERSION = '0.03';

our $_BACKEND = 'PP';

use Image::ThumbHash::PP our @EXPORT_OK = qw(
    rgba_to_thumb_hash
    rgba_to_png
    rgba_to_data_url
    thumb_hash_to_rgba
    thumb_hash_to_average_rgba
    thumb_hash_to_approximate_aspect_ratio
    thumb_hash_to_data_url
);

push our @EXPORT_OK, qw(
    imager_to_rgba
    imager_to_thumb_hash
);

sub imager_to_rgba {
    my ($img) = @_;
    wantarray or croak "imager_to_rgba: must be called in list context";
    $img = $img->to_rgb8;
    $img = $img->scale(
        xpixels => 100,
        ypixels => 100,
        type    => 'min',
        qtype   => 'mixing',
    ) or croak "imager_to_rgba: cannot scale: " . $img->errstr;
    $img = $img->convert(preset => 'addalpha');
    $img->write(type => 'raw', data => \my $data)
        or croak "imager_to_rgba: cannot write: " . $img->errstr;
    $img->getwidth, $img->getheight, $data
}

sub imager_to_thumb_hash {
    my ($img) = @_;
    rgba_to_thumb_hash imager_to_rgba $img
}

1
__END__

=encoding utf8

=head1 NAME

Image::ThumbHash - A very compact representation of an image placeholder

=head1 SYNOPSIS

=for highlighter language=perl

    use Image::ThumbHash qw(
        imager_to_rgba
        imager_to_thumb_hash
        rgba_to_thumb_hash
        rgba_to_png
        rgba_to_data_url
        thumb_hash_to_rgba
        thumb_hash_to_average_rgba
        thumb_hash_to_approximate_aspect_ratio
        thumb_hash_to_data_url
    );

=head1 DESCRIPTION

This module implements the L<ThumbHash|https://evanw.github.io/thumbhash/>
image placeholder generation algorithm by
L<Evan Wallace|https://madebyevan.com/>.

This algorithm reduces small (thumbnail) images to an even smaller chunk of
bytes, the "thumb hash". The thumb hash can then be used to recreate a lossy
approximation of the original image.

The main use case of this algorithm is to reduce initial loading times of image
galleries on the web. You would either convert the thumb hash to a small
(inline) PNG on the server and embed in your HTML, or embed the raw thumb hash
and convert it to a PNG on the client side (using JavaScript). In either case,
you end up with small placeholder images that load instantly while the original
images can be loaded in asynchronously.

=head1 FUNCTIONS

This module exports the following functions on request.

=head2 imager_to_rgba

    my ($width, $height, $rgba) = imager_to_rgba($imager);

Converts an image (an instance of L<Imager>) to RGBA (see below).

The return value is a list containing the image width, height, and pixels as a
byte string in RGBA format.

=head2 imager_to_thumb_hash

    my $thumbhash = imager_to_thumb_hash($imager);

Encodes an image (an instance of L<Imager>) to a thumb hash.

The return value is a byte string containing the thumb hash.

=head2 rgba_to_thumb_hash

    my $thumbhash = rgba_to_thumb_hash($width, $height, $rgba);

Encodes an RGBA image to a thumb hash. RGB should not be premultiplied by A.

C<$width> is the image width; C<$height> is the image height. Both are in
pixels and must be 100 or less.

C<$rgba> is a raw byte string containing 4 bytes for each pixel in the image,
representing the red, green, blue, and alpha channels, respectively. That is,
C<length($rgba) == $width * $height * 4>.

The return value is a byte string containing the thumb hash.

=head2 rgba_to_png

    my $png = rgba_to_png($width, $height, $rgba);

Encodes an RGBA image to PNG. RGB should not be premultiplied by A. The
resulting PNG is not optimized for size or compressed in any way.

C<$width> is the image width; C<$height> is the image height. Both are in
pixels and must be 100 or less.

C<$rgba> is a raw byte string containing 4 bytes for each pixel in the image,
representing the red, green, blue, and alpha channels, respectively. That is,
C<length($rgba) == $width * $height * 4>.

The return value is a byte string containing the PNG.

=head2 rgba_to_data_url

    my $url = rgba_to_data_url($width, $height, $rgba);

Encodes an RGBA image to a PNG data URL. RGB should not be premultiplied by A.

C<$width> is the image width; C<$height> is the image height. Both are in
pixels and must be 100 or less.

C<$rgba> is a raw byte string containing 4 bytes for each pixel in the image,
representing the red, green, blue, and alpha channels, respectively. That is,
C<length($rgba) == $width * $height * 4>.

The return value is a string containing a C<data:> URL.

This is equivalent to:

    use MIME::Base64 qw(encode_base64);
    my $url = 'data:image/png;base64,' . encode_base64(rgba_to_png($width, $height, $rgba), "");

=head2 thumb_hash_to_rgba

    my ($width, $height, $rgba) = thumb_hash_to_rgba($thumbhash);

Decodes a thumb hash to an RGBA image. RGB is not premultiplied by A.

The return value is a list containing the image width, height, and pixels as a
byte string in RGBA format.

=head2 thumb_hash_to_average_rgba

    my ($red, $green, $blue, $alpha) = thumb_hash_to_average_rgba($thumbhash);

Extracts the average color from a thumb hash. RGB is not premultiplied by A.

The return value is a list containing the numeric RGBA values for the average
color, in the range from 0 to 1.

=head2 thumb_hash_to_approximate_aspect_ratio

    my $aspect_ratio = thumb_hash_to_approximate_aspect_ratio($thumbhash);

Extracts and returns the approximate aspect ratio of the original image, i.e.
width/height.

=head2 thumb_hash_to_data_url

    my $url = thumb_hash_to_data_url($thumbhash);

Decodes a thumb hash to a PNG data URL.

This is equivalent to:

    my $url = rgba_to_data_url(thumb_hash_to_rgba($thumbhash));

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

The original concept and code are:

=over

Copyright (c) 2023 Evan Wallace

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=back

See L<https://github.com/evanw/thumbhash>.

The Perl implementation, documentation, and tests are:

Copyright 2023 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<https://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Imager>
