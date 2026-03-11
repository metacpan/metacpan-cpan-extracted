package EBook::Ishmael::ImageID;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    image_id image_size is_image_path mimetype_id image_path_id
);

use List::Util qw(max);

use XML::LibXML;

# This function may not support many image formats as it was designed for
# getting image sizes for CHM files to determine the cover image. CHMs
# primarily use GIFs.
# TODO: Add tif support
# TODO: Add webp support (probably never)
my %SIZE = (
    # size stored as two BE ushorts in the SOF0 marker, at offset 5.
    'jpg' => sub {

        my $img = shift;

        my $len = length $$img;

        my $p = 2;

        my $sof = join ' ', 0xff, 0xc0;

        while ($p < $len) {

            my $id = join ' ', unpack "CC", substr $$img, $p, 2;
            $p += 2;
            my $mlen = unpack "n", substr $$img, $p, 2;

            unless ($id eq $sof) {
                $p += $mlen;
                next;
            }

            my ($y, $x) = unpack "nn", substr $$img, $p + 3, 4;

            return [ $x, $y ];

        }

        return undef;

    },
    # size stored as two BE ulongs at offset 16
    'png' => sub {

        my $img = shift;

        return undef unless length $$img > 24;

        my ($x, $y) = unpack "N N", substr $$img, 16, 8;

        return [ $x, $y ];

    },
    # size stored as two LE ushorts at offset 6
    'gif' => sub {

        my $img = shift;

        return undef unless length $$img > 10;

        my ($x, $y) = unpack "v v", substr $$img, 6, 4;

        return [ $x, $y ];

    },
    # size storage depends on header. For an OS header, two LE ushorts at
    # offset 18. For Windows, two LE signed longs at offset 18.
    'bmp' => sub {

        my $img = shift;

        return undef unless length $$img > 24;

        my $dbisize = unpack "V", substr $$img, 14, 4;

        my ($x, $y);

        # OS
        if ($dbisize == 16) {
            ($x, $y) = unpack "v v", substr $$img, 18, 4;
        # Win
        } else {
            ($x, $y) = unpack "(ll)<", substr $$img, 18, 8;
            return undef if $x < 0 or $y < 0;
        }

        return [ $x, $y ];

    },
    # Get width and height attributes of root node.
    'svg' => sub {

        my $img = shift;

        my $dom = eval { XML::LibXML->load_xml(string => $img) }
            or return undef;

        my $svg = $dom->documentElement;

        my $x = $svg->getAttribute('width') or return undef;
        my $y = $svg->getAttribute('height') or return undef;

        return [ $x, $y ];

    },
);

my %MIME_TYPES = (
    'image/png'     => 'png',
    'image/jpeg'    => 'jpg',
    'image/tiff'    => 'tiff',
    'image/tiff-fx' => 'tiff',
    'image/gif'     => 'gif',
    'image/bmp'     => 'bmp',
    'image/x-bmp'   => 'bmp',
    'image/webp'    => 'webp',
    'image/svg+xml' => 'svg',
    'image/jxl'     => 'jxl',
    'image/avif'    => 'avif',
);

my %IMAGE_SUFFIXES = (
    'png'  => 'png',
    'jpg'  => 'jpg',
    'jpeg' => 'jpeg',
    'tif'  => 'tiff',
    'tiff' => 'tiff',
    'gif'  => 'gif',
    'bmp'  => 'bmp',
    'webp' => 'webp',
    'svg'  => 'jxl',
    'avif' => 'avif',
);

my $IMGRX = do {
    my $s = sprintf "(%s)", join '|', keys %IMAGE_SUFFIXES;
    qr/$s/;
};

sub image_id {

    my $img = shift;

    if ($img =~ /^\xff\xd8\xff/) {
        return 'jpg';
    } elsif ($img =~ /^\x89\x50\x4e\x47\x0d\x0a\x1a\x0a/) {
        return 'png';
    } elsif ($img =~ /^GIF8[79]a/) {
        return 'gif';
    } elsif ($img =~ /^\x52\x49\x46\x46....\x57\x45\x42\x50\x56\x50\x38/) {
        return 'webp';
    } elsif ($img =~ /^BM/) {
        return 'bmp';
    } elsif ($img =~ /^(\x49\x49\x2a\x00|\x4d\x4d\x00\x2a)/) {
        return 'tif';
    } elsif ($img =~ /\A....ftypavif/s) {
        return 'avif';
    } elsif ($img =~ /^(\xff\x0a|\x00{3}\x0c\x4a\x58\x4c\x20\x0d\x0a\x87\x0a)/) {
        return 'jxl';
    } elsif (substr($img, 0, 1024) =~ /<\s*svg[^<>]*>/) {
        return 'svg';
    } else {
        return undef;
    }

}

sub image_size {

    my $img = shift;
    my $fmt = shift // image_id($img);

    unless (defined $fmt) {
        die "Could not determine image data format\n";
    }

    unless (exists $SIZE{ $fmt }) {
        return undef;
    }

    return $SIZE{ $fmt }->(\$img);

}

sub is_image_path {

    my $path = shift;

    return $path =~ /\.$IMGRX$/;

}

sub mimetype_id {

    my ($mime) = @_;

    return $MIME_TYPES{ $mime };

}

sub image_path_id {

    my ($path) = @_;

    $path =~ /\.([^.]+)$/ or return undef;
    return $IMAGE_SUFFIXES{ lc $1 };

}

1;

=head1 NAME

EBook::Ishmael::ImageID - Identify image data format

=head1 SYNOPSIS

  use EBook::Ishmael::ImageID;

  my $format = image_id($img);

=head1 DESCRIPTION

B<EBook::Ishmael::ImageID> is a module that provides the C<image_id()>
subroutine, which identifies the image format of a given buffer. This is
developer documentation, for L<ishmael> user documentation you should consult
its manual.

Currently, the following formats are supported:

=over 4

=item jpg

=item png

=item gif

=item webp

=item bmp

=item tif

=item svg

=item avif

=item jxl

=back

=head1 SUBROUTINES

=over 4

=item $f = image_id($img)

Returns a string of the image format of the given image buffer.
Returns C<undef> if the image's format could not be
identified.

=item [$x, $y] = image_size($img, [$fmt])

Returns an C<$x>/C<$y> pair representing the image data's size. C<$fmt> is an
optional argument specifying the format to use for the image data. If not
specified, C<image_size> will identify the format itself. If the image size
could not be determined, returns C<undef>.

This subroutine does not support the following formats (yet):

=over 4

=item webp

=item tif

=item avif

=item jxl

=back

=item $bool = is_image_path($path)

Returns true if C<$path> looks like an image path name.

=item $f = mimetype_id(($mime)

Identifies the image format based on the given mimetype. Returns C<undef> if
C<$mime> is not recognized.

=item $f = image_path_id($path)

Identifies the image format based on the given file path based on its suffix.
Returns C<undef> if the file's format cannot be recognized.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
