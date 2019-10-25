# -*- perl -*-

#
# Copyright (C) 2019 Preisvergleich Internet Services AG. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

# File magic is
# R I F F
# length (4 bytes)
# WEPB

=begin register

MAGIC: /^RIFF.{4}WEBP/s

VP8 (lossy), VP8L (lossless) and VP8X (extended) files are supported.
Sets the key C<Animation> to true if the file is an animation. Otherwise
sets the key C<Compression> to either C<VP8> or C<Lossless>.

=end register

=cut

package Image::Info::WEBP;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

sub my_read
{
    my($source, $len) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    die "read failed: $!" unless defined $n;
    die "short read ($len/$n) at pos " . tell($source) unless $n == $len;
    $buf;
}

my @upscale = (1, 5/4, 5/3, 2);

sub process_file
{
    my($info, $fh) = @_;

    my $signature = my_read($fh, 16);
    die "Bad WEBP signature"
	unless $signature =~ /\ARIFF....WEBPVP8([ LX])/s;

    my $type = $1;

    $info->push_info(0, "file_media_type" => "image/webp");
    $info->push_info(0, "file_ext" => "webp");

    # This code is (arguably) 4 bytes out of sync with the description in the
    # spec, because the spec describes ChunkHeader('ABCD') as an 8-byte quantity
    # and we've processed the first 4 bytes above, but need to handle the second
    # 4 (the length) here:
    if ($type eq 'X') {
        # 32 bits of length
        # 8 bits of flags
        # 24 bits reserved
        # 24 bits canvas width
        # 24 bits canvas height
        # and then chunks...
        my ($length, $flags, $raw_width, $raw_height)
            = unpack 'VVVv', my_read($fh, 14);
        # Of the 14 bytes now read, 10 were included in length:
        $length -= 10;
        die sprintf "Bad WEBP VP8X reserved bits 0x%02X", $flags & 0xC1
            if $flags & 0xC1;
        die sprintf "Bad WEBP VP8X reserved bits 0x%06X", $flags >> 8
            if $flags >> 8;

        # Shuffle the 24 bit values into shape:
        $raw_height = ($raw_height << 8) | ($raw_width >> 24);
        $raw_width &= 0xFFFFFF;
        # Strictly this is the canvas width/height, not that of the first frame.
        # But 1 image, that might be animated. Hence it doesn't quite map to the
        # "$n images in a file" model that Image::Info::GIF provides.

        $info->push_info(0, "width", 1 + $raw_width);
        $info->push_info(0, "height", 1 + $raw_height);

        if ($flags & 0x02) {
            $info->push_info(0, "Animation", 1);
        } else {
            # Possibly could also handle EXIF chunks here, although it's unclear
            # how much code that should share with
            # Image::Info::JPEG::process_app1_exif(), as that seems to have both
            # JPEG-specific logic, and more generic EXIF logic.

            while (1) {
                # Spec says that length is actual length, without accounting for
                # padding. Odd sizes are padded to the next even size:
                ++$length
                    if $length & 1;
                die "seek failed: $!"
                    unless seek $fh, $length, 1;
                my $buf;
                my $n = read $fh, $buf, 8;
                die "read failed: $!" unless defined $n;
                die "No VP8 or VP8L chunk found in WEPB Extended File Format"
                    if $n == 0;
                die "short read (8/$n) at pos " . tell $fh
                    unless $n == 8;
                (my $chunk, $length) = unpack "a4V", $buf;
                if ($chunk eq 'VP8 ') {
                    $info->push_info(0, "Compression", "VP8");
                    last;
                } elsif ($chunk eq 'VP8L') {
                    $info->push_info(0, "Compression", "Lossless");
                    last;
                }
            }
        }
    } elsif ($type eq 'L') {
        # There doesn't seem to be a better name for this:
        $info->push_info(0, "Compression", "Lossless");
        # Discard the 4 bytes of length; grab the next 5.
        my ($sig, $size_and_flags) = unpack "x4CV", my_read($fh, 9);
        die sprintf "Bad WEBP Lossless signature 0x%02X", $sig
            unless $sig == 0x2f;
        my $version = $size_and_flags >> 30;
        die "Bad WEBP Lossless version $sig"
            unless $version == 0;
        $info->push_info(0, "width", 1 + $size_and_flags & 0x3FFF);
        $info->push_info(0, "height", 1 + ($size_and_flags >> 14)  & 0x3FFF);
    } else {
        $info->push_info(0, "Compression", "VP8");
        # The fun format for a key frame is
        # 32 bits of length
        # 24 bits of frame tag
        # 3 signature bytes
        # 2+14 bits of width
        # 2+14 bits of height
        # We don't have a pack format for 3 bytes, but the bits we need can be
        # got by approximating it as 2, 4, 2, 2:
        my ($type, $start, $raw_horiz, $raw_vert)
            = unpack "x4vVvv", my_read($fh, 14);
        die "Bad WEBP VP8 type 1 (ie interframe)"
            if $type & 1;
        $start >>= 8;
        die sprintf "Bad WEBP VP8 key frame start signature 0x%06X", $start
            unless $start == 0x2a019d;

        # The top two bits of the raw width and height values are used as to
        # flag a ratio to upscale.
        # However, testing against dwebp and webpmux and then re-checking the
        # documentation, it seems that these are really intended as information
        # for the video hardware to render the image, because they don't change
        # the size of bitmap returned from the decoder library. So return them
        # as extra information, but don't recalculate the width and height.
        $info->push_info(0, "width", ($raw_horiz & 0x3FFF));
        $info->push_info(0, "height", ($raw_vert & 0x3FFF));
        $info->push_info(0, "Width_Upscale", $upscale[$raw_horiz >> 14]);
        $info->push_info(0, "Height_Upscale", $upscale[$raw_vert >> 14]);

    }
}
