package Image::ThumbHash::PP;
use v5.10.0;  # //
use strict;
use warnings qw(all FATAL uninitialized);

use Exporter 5.57 qw(import);
use Carp qw(croak);
use List::Util qw(min max);
use MIME::Base64 ();

use constant {
    PI => 4 * atan2(1, 1),
};

our $VERSION = '0.04';

our @EXPORT_OK = qw(
    rgba_to_thumb_hash
    rgba_to_png
    rgba_to_data_url
    thumb_hash_to_rgba
    thumb_hash_to_average_rgba
    thumb_hash_to_approximate_aspect_ratio
    thumb_hash_to_data_url
);

sub _assert_w_h_rgba {
    my ($width, $height, $rgba, $sub) = @_;
    $sub //= (caller 1)[3];

    0 <= $width && $width <= 100
        or croak "$sub: width is not in range [0, 100]: $width";
    0 <= $height && $height <= 100
        or croak "$sub: height is not in range [0, 100]: $height";
    length($rgba) == $width * $height * 4
        or croak "$sub: rgba length does not match " . ($width * $height * 4) . ": " . length($rgba);
}

sub _assert_thumb_hash {
    my ($hash, $sub) = @_;
    $sub //= (caller 1)[3];

    length($hash) >= 5
        or croak "$sub: thumb hash length is less than 5: " . length($hash);
}

sub rgba_to_thumb_hash {
    my ($width, $height, $rgba) = @_;

    # Encoding an image larger than 100x100 is slow with no benefit
    _assert_w_h_rgba $width, $height, $rgba;

    # Determine the average color
    my ($avg_r, $avg_g, $avg_b, $avg_a) = (0, 0, 0, 0);
    for my $pixel (unpack '(a4)*', $rgba) {
        my ($pr, $pg, $pb, $pa) = unpack 'C*', $pixel;
        my $alpha = $pa / 255;
        my $alpha_f = $alpha / 255;
        $avg_r += $alpha_f * $pr;
        $avg_g += $alpha_f * $pg;
        $avg_b += $alpha_f * $pb;
        $avg_a += $alpha;
    }
    if ($avg_a > 0) {
        $_ /= $avg_a for $avg_r, $avg_g, $avg_b;
    }

    my $has_alpha = $avg_a < $width * $height;
    my $l_limit = $has_alpha ? 5 : 7;  # Use fewer luminance bits if there's alpha
    my $max_w_h = max $width, $height;
    my $lx = max 1, int($l_limit * $width / $max_w_h + 0.5);
    my $ly = max 1, int($l_limit * $height / $max_w_h + 0.5);
    my (
        @l,  # luminance
        @p,  # yellow - blue
        @q,  # red - green
        @a,  # alpha
    );

    # Convert the image from RGBA to LPQA (composite atop the average color)
    for my $pixel (unpack '(a4)*', $rgba) {
        my ($pr, $pg, $pb, $pa) = unpack 'C*', $pixel;
        my $alpha = $pa / 255;
        my $alpha_f = $alpha / 255;
        my $r = $avg_r * (1 - $alpha) + $alpha_f * $pr;
        my $g = $avg_g * (1 - $alpha) + $alpha_f * $pg;
        my $b = $avg_b * (1 - $alpha) + $alpha_f * $pb;
        push @l, ($r + $g + $b) / 3;
        push @p, ($r + $g) / 2 - $b;
        push @q, $r - $g;
        push @a, $alpha;
    }

    # Encode using the DCT into DC (constant) and normalized AC (varying) terms
    my $encode_channel = sub {
        my ($channel, $nx, $ny) = @_;
        my $dc = 0;
        my @ac;
        my $scale = 0;
        for my $cy (0 .. $ny - 1) {
            for (my $cx = 0; $cx * $ny < $nx * ($ny - $cy); $cx++) {
                my @fx = map cos(PI / $width * $cx * ($_ + 0.5)), 0 .. $width - 1;
                my $f = 0;
                for my $y (0 .. $height - 1) {
                    my $fy = cos(PI / $height * $cy * ($y + 0.5));
                    for my $x (0 .. $width - 1) {
                        $f += $channel->[$x + $y * $width] * $fx[$x] * $fy;
                    }
                }
                $f /= $width * $height;
                if ($cx || $cy) {
                    push @ac, $f;
                    $scale = max $scale, abs $f;
                } else {
                    $dc = $f;
                }
            }
        }
        if ($scale) {
            for my $ac (@ac) {
                $ac = 0.5 + 0.5 / $scale * $ac;
            }
        }
        ($dc, \@ac, $scale)
    };
    my ($l_dc, $l_ac, $l_scale) = $encode_channel->(\@l, max(3, $lx), max(3, $ly));
    my ($p_dc, $p_ac, $p_scale) = $encode_channel->(\@p, 3, 3);
    my ($q_dc, $q_ac, $q_scale) = $encode_channel->(\@q, 3, 3);
    my ($a_dc, $a_ac, $a_scale) = $has_alpha ? $encode_channel->(\@a, 5, 5) : (1, [], 1);

    # Write the constants
    my $is_landscape = $width > $height;
    my $header24 = int(0.5 + 63 * $l_dc)
        | int(0.5 + 31.5 + 31.5 * $p_dc) << 6
        | int(0.5 + 31.5 + 31.5 * $q_dc) << 12
        | int(0.5 + 31 * $l_scale) << 18
        | ($has_alpha ? 1 << 23 : 0);
    my $header16 = ($is_landscape ? $ly : $lx)
        | int(0.5 + 63 * $p_scale) << 3
        | int(0.5 + 63 * $q_scale) << 9
        | ($is_landscape ? 1 << 15 : 0);
    my $hash_const = pack 'C*', (
        $header24 & 0xff,
        $header24 >> 8 & 0xff,
        $header24 >> 16,
        $header16 & 0xff,
        $header16 >> 8,
        $has_alpha
            ? int(0.5 + 15 * $a_dc) | int(0.5 + 15 * $a_scale) << 4
            : (),
    );

    # Write the varying factors
    my $ac_index = 0;
    my $hash_vary = '';
    for my $ac ($l_ac, $p_ac, $q_ac, $has_alpha ? $a_ac : ()) {
        for my $f (@$ac) {
            vec($hash_vary, $ac_index++, 4) = int(0.5 + 15 * $f);
        }
    }

    $hash_const . $hash_vary
}

sub rgba_to_png {
    my ($width, $height, $rgba) = @_;
    _assert_w_h_rgba $width, $height, $rgba;

    my $row = $width * 4 + 1;
    my $idat = 6 + $height * (5 + $row);
    my @bytes = (
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0,
        $width >> 8 & 0xff, $width & 0xff, 0, 0, $height >> 8 & 0xff, $height & 0xff, 8, 6, 0, 0, 0, 0, 0, 0, 0,
        $idat >> 24 & 0xff, $idat >> 16 & 0xff, $idat >> 8 & 0xff, $idat & 0xff,
        73, 68, 65, 84, 120, 1,
    );
    my $a = 1;
    my $b = 0;
    for my $y (0 .. $height - 1) {
        push @bytes, (
            $y == $height - 1 ? 1 : 0,
            $row & 0xff,
            $row >> 8 & 0xff,
            $row & 0xff ^ 0xff,
            $row >> 8 & 0xff ^ 0xff,
            0,
        );
        $b = ($b + $a) % 65521;
        my $slice = ($row - 1) * $y;
        for my $i ($slice .. $slice + $row - 2) {
            my $u = vec $rgba, $i, 8;
            push @bytes, $u;
            $a = ($a + $u) % 65521;
            $b = ($b + $a) % 65521;
        }
    }
    push @bytes, (
        $b >> 8, $b & 0xff, $a >> 8, $a & 0xff, 0, 0, 0, 0,
        0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    );
    my @table = (
        0, 498536548, 997073096, 651767980, 1994146192, 1802195444, 1303535960,
        1342533948, 3988292384, 4027552580, 3604390888, 3412177804, 2607071920,
        2262029012, 2685067896, 3183342108,
    );
    for my $range ([12, 28], [37, 40 + $idat]) {
        my ($start, $end) = @$range;
        my $c = 0xffff_ffff;
        for my $i ($start .. $end) {
            $c ^= $bytes[$i];
            $c = $c >> 4 ^ $table[$c & 0xf];
            $c = $c >> 4 ^ $table[$c & 0xf];
        }
        $c ^= 0xffff_ffff;
        $bytes[$end + 1] = $c >> 24 & 0xff;
        $bytes[$end + 2] = $c >> 16 & 0xff;
        $bytes[$end + 3] = $c >> 8 & 0xff;
        $bytes[$end + 4] = $c & 0xff;
    }
    pack 'C*', @bytes
}

sub rgba_to_data_url {
    my ($width, $height, $rgba) = @_;
    _assert_w_h_rgba $width, $height, $rgba;
    'data:image/png;base64,' . MIME::Base64::encode(rgba_to_png($width, $height, $rgba), '')
}

sub thumb_hash_to_rgba {
    my ($hash) = @_;
    _assert_thumb_hash $hash;
    wantarray or croak "thumb_hash_to_rgba: must be called in list context";
    
    # Read the constants
    my $header24 = vec($hash, 0, 8) | vec($hash, 1, 8) << 8 | vec($hash, 2, 8) << 16;
    my $header16 = vec($hash, 3, 8) | vec($hash, 4, 8) << 8;
    my $l_dc = ($header24 & 63) / 63;
    my $p_dc = ($header24 >> 6 & 63) / 31.5 - 1;
    my $q_dc = ($header24 >> 12 & 63) / 31.5 - 1;
    my $l_scale = ($header24 >> 18 & 31) / 31;
    my $has_alpha = $header24 >> 23;
    my $p_scale = ($header16 >> 3 & 63) / 63;
    my $q_scale = ($header16 >> 9 & 63) / 63;
    my $is_landscape = $header16 >> 15;
    my $l_max = $has_alpha ? 5 : 7;
    my $l_min = max(3, $header16 & 7);
    my ($lx, $ly) = $is_landscape
        ? ($l_max, $l_min)
        : ($l_min, $l_max);
    my ($a_dc, $a_scale) = $has_alpha
        ? (map vec($hash, $_, 4) / 15,
            10, 11)
        : (1, 1);

    # Read the varying factors (boost saturation by 1.25x to compensate for quantization)
    my $ac_index = $has_alpha ? 12 : 10;
    my $decode_channel = sub {
        my ($nx, $ny, $scale) = @_;
        my @ac;
        for my $cy (0 .. $ny - 1) {
            for (my $cx = !$cy; $cx * $ny < $nx * ($ny - $cy); $cx++) {
                push @ac, (vec($hash, $ac_index++, 4) / 7.5 - 1) * $scale;
            }
        }
        \@ac
    };
    my $l_ac = $decode_channel->($lx, $ly, $l_scale);
    my $p_ac = $decode_channel->(3, 3, $p_scale * 1.25);
    my $q_ac = $decode_channel->(3, 3, $q_scale * 1.25);
    my $a_ac = $has_alpha ? $decode_channel->(5, 5, $a_scale) : [];

    # Decode using the DCT into RGB
    my $ratio = $is_landscape
        ? $l_max / ($header16 & 7)
        : ($header16 & 7) / $l_max;
    my ($width, $height) = $ratio > 1
        ? (32, int(0.5 + 32 / $ratio))
        : (int(0.5 + 32 * $ratio), 32);
    my $rgba = '';
    my (@fx, @fy);
    for my $y (0 .. $height - 1) {
        for my $x (0 .. $width - 1) {
            my $l = $l_dc;
            my $p = $p_dc;
            my $q = $q_dc;
            my $a = $a_dc;

            # Precompute the coefficients
            my @fx = map cos(PI / $width * ($x + 0.5) * $_), 0 .. max($lx, $has_alpha ? 5 : 3) - 1;
            my @fy = map cos(PI / $height * ($y + 0.5) * $_), 0 .. max($ly, $has_alpha ? 5 : 3) - 1;

            # Decode L
            {
                my $j = 0;
                for my $cy (0 .. $ly - 1) {
                    my $fy2 = $fy[$cy] * 2;
                    for (my $cx = !$cy; $cx * $ly < $lx * ($ly - $cy); $cx++) {
                        $l += $l_ac->[$j++] * $fx[$cx] * $fy2;
                    }
                }
            }

            # Decode P and Q
            {
                my $j = 0;
                for my $cy (0 .. 2) {
                    my $fy2 = $fy[$cy] * 2;
                    for my $cx (!$cy .. 2 - $cy) {
                        my $f = $fx[$cx] * $fy2;
                        $p += $p_ac->[$j] * $f;
                        $q += $q_ac->[$j] * $f;
                        $j++;
                    }
                }
            }

            # Decode A
            if ($has_alpha) {
                my $j = 0;
                for my $cy (0 .. 4) {
                    my $fy2 = $fy[$cy] * 2;
                    for my $cx (!$cy .. 4 - $cy) {
                        $a += $a_ac->[$j++] * $fx[$cx] * $fy2;
                    }
                }
            }

            # Convert to RGB
            my $b = $l - 2 / 3 * $p;
            my $r = (3 * $l - $b + $q) / 2;
            my $g = $r - $q;
            $rgba .= pack 'C*', map max(0, 255 * min(1, $_)), $r, $g, $b, $a;
        }
    }

    $width, $height, $rgba
}

sub thumb_hash_to_average_rgba {
    my ($hash) = @_;
    _assert_thumb_hash $hash;
    wantarray or croak "thumb_hash_to_average_rgba: must be called in list context";
    my $header = vec($hash, 0, 8) | vec($hash, 1, 8) << 8 | vec($hash, 2, 8) << 16;
    my $l = ($header & 63) / 63;
    my $p = ($header >> 6 & 63) / 31.5 - 1;
    my $q = ($header >> 12 & 63) / 31.5 - 1;
    my $has_alpha = $header >> 23;
    my $a = $has_alpha ? (vec($hash, 5, 8) & 15) / 15 : 1;
    my $b = $l - 2 / 3 * $p;
    my $r = (3 * $l - $b + $q) / 2;
    my $g = $r - $q;

    max(0, min(1, $r)),
    max(0, min(1, $g)),
    max(0, min(1, $b)),
    $a
}

sub thumb_hash_to_approximate_aspect_ratio {
    my ($hash) = @_;
    _assert_thumb_hash $hash;
    my $has_alpha = vec($hash, 2, 8) & 0x80;
    my $is_landscape = vec($hash, 4, 8) & 0x80;
    my $l_max = $has_alpha ? 5 : 7;
    my $l_min = vec($hash, 3, 8) & 0x7;
    $is_landscape
        ? $l_max / $l_min
        : $l_min / $l_max
}

sub thumb_hash_to_data_url {
    my ($hash) = @_;
    _assert_thumb_hash $hash;
    rgba_to_data_url thumb_hash_to_rgba $hash
}

1
__END__

=encoding utf8

=head1 NAME

Image::ThumbHash::PP - pure-perl implementation of Image::ThumbHash

=head1 DESCRIPTION

This module contains the pure-perl backend for L<Image::ThumbHash>, which see
for a description of the public interface.

=head1 SEE ALSO

L<Image::ThumbHash>

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

=cut
