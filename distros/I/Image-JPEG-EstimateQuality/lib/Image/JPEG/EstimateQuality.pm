package Image::JPEG::EstimateQuality;
use 5.008005;
use strict;
use warnings;
use Exporter 'import';
use Carp;

our $VERSION = "0.02";

our @EXPORT = qw( jpeg_quality );

use constant {
    SECTION_MARKER => "\xFF",
    SOI => "\xFF\xD8",
    EOI => "\xFF\xD8",
    SOS => "\xFF\xDA",
    DQT => "\xFF\xDB",

    ERR_NOT_JPEG  => "Not a JPEG file",
    ERR_FILE_READ => "File read error",
    ERR_FAILED    => "Could not determine quality",
};

sub jpeg_quality {
    my ($file) = @_;

    my ($fh, $r);
    if (! ref $file) {
        open $fh, '<', $file  or croak ERR_FILE_READ . qq{($file): $!};
        binmode $fh;
        $r = _jpeg_quality_for_fh($fh);
        close $fh;
        return $r;
    } elsif (ref $file eq 'SCALAR') {
        # image data in memory
        open $fh, '<', $file  or croak ERR_FILE_READ . qq{: $!};
        binmode $fh;
        $r = _jpeg_quality_for_fh($fh);
        close $fh;
        return $r;
    } elsif (ref $file eq 'GLOB' || eval { $file->isa('IO::Handle') }) {
        binmode $file;
        $fh = $file;
        $r = _jpeg_quality_for_fh($fh);
        return $r;
    } else {
        croak "Unsupported file: $file";
    }
}

# TODO: lossless support

sub _jpeg_quality_for_fh {
    my ($fh) = @_;
    my ($buf);

    read $fh, $buf, 2  or croak ERR_FILE_READ . qq{: $!};
    croak ERR_NOT_JPEG unless $buf eq SOI;

    while (1) {
        read $fh, $buf, 2  or croak ERR_FILE_READ . qq{: $!};

        if ($buf eq EOI) {
            croak ERR_FAILED;
        }
        if ($buf eq SOS) {
            croak ERR_FAILED;
        }

        my $marker = substr $buf, 0, 1;
        croak ERR_NOT_JPEG unless $marker eq SECTION_MARKER;

        if ($buf ne DQT) {
            # skip to next segment
            read $fh, $buf, 2  or croak ERR_FILE_READ . qq{: $!};
            my $len = unpack 'n', $buf;
            seek $fh, $len - 2, 1  or croak ERR_FILE_READ . qq{: $!};
            next;
        }

        # read DQT length
        read $fh, $buf, 2  or croak ERR_FILE_READ . qq{: $!};
        my $len = unpack 'n', $buf;
        $len -= 2;
        croak ERR_FAILED unless $len >= 64+1;

        # read DQT
        read $fh, $buf, $len  or croak ERR_FILE_READ . qq{: $!};

        my $dqt8bit = ((ord substr($buf, 0, 1) & 0xF0) == 0);

        return _judge_quality($buf, $dqt8bit);
    }

    # NEVER REACH HERE
}

# Precalculated sums of luminance quantization table for each qualities.
# Base table is from Table K.1 in JPEG Standard Annex K

my @sums_dqt = (
    16320, 16315, 15946, 15277, 14655, 14073, 13623, 13230, 12861, 12560,
    12245, 11867, 11467, 11084, 10718, 10371, 10027,  9702,  9371,  9056,
     8680,  8345,  8005,  7683,  7376,  7092,  6829,  6586,  6360,  6148,
     5949,  5771,  5584,  5422,  5265,  5122,  4980,  4852,  4729,  4616,
     4502,  4396,  4290,  4194,  4097,  4008,  3929,  3845,  3755,  3688,
     3621,  3541,  3467,  3396,  3323,  3247,  3170,  3096,  3021,  2952,
     2874,  2804,  2727,  2657,  2583,  2509,  2437,  2362,  2290,  2211,
     2136,  2068,  1996,  1915,  1858,  1773,  1692,  1620,  1552,  1477,
     1398,  1326,  1251,  1179,  1109,  1031,   961,   884,   814,   736,
      667,   592,   518,   441,   369,   292,   221,   151,    86,    64,
);

sub _judge_quality {
    my ($buf, $is_8bit) = @_;

    my $sum = 0;
    if ($is_8bit) {
        $sum += $_ for map { unpack('C', substr($buf, 1+1*$_, 1)) } (1..64);
    } else {
        $sum += $_ for map { unpack('n', substr($buf, 1+2*$_, 2)) } (1..64);
        $sum /= 256;
    }

    for my $i (0 .. 99) {
        if ($sum < $sums_dqt[99 - $i]) {
            return 100 - $i;
        }
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Image::JPEG::EstimateQuality - Estimate quality of JPEG images.

=head1 SYNOPSIS

    use Image::JPEG::EstimateQuality;

    jpeg_quality('filename.jpg');   # => 1..100 integer value
    jpeg_quality(FILEHANDLE);
    jpeg_quality(\$image_data);

=head1 DESCRIPTION

Image::JPEG::EstimateQuality determines quality of JPEG file.
It's approximate value because the quality is not stored in the file explicitly.
This module calculates quality from luminance quantization table stored in the file.

=head1 METHODS

=over 4

=item jpeg_quality($stuff)

Returns quality (1-100) of JPEG file.

    scalar:     filename
    scalarref:  JPEG data itself
    file-glob:  file handle

=back

=head1 SCRIPT

A script F<jpeg-quality> distributed with the module prints the quality of a JPEG specified on the command line:

    jpeg-quality image.jpg
    90

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>daydream.trippers@gmail.comE<gt>

=cut

