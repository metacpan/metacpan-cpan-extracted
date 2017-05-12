package Image::PNM;
BEGIN {
  $Image::PNM::AUTHORITY = 'cpan:DOY';
}
$Image::PNM::VERSION = '0.01';
use strict;
use warnings;
# ABSTRACT: parse and generate PNM (PBM, PGM, PPM) files



sub new {
    my $class = shift;
    my ($data) = @_;

    my $self = bless {}, $class;

    if (ref $data) {
        $self->_parse_string($data);
    }
    elsif ($data) {
        $self->_parse_file($data);
    }
    else {
        $self->{w}      = 1;
        $self->{h}      = 1;
        $self->{max}    = 1;
        $self->{pixels} = [[0]];
    }

    return $self;
}


sub as_string {
    my $self = shift;
    my ($format) = @_;

    my $method = "_as_string_$format";
    die "Unknown format $format"
        unless $self->can($method);

    return $self->$method;
}


sub width {
    my $self = shift;
    my ($w) = @_;
    if (defined($w)) {
        for my $row (@{ $self->{pixels} }) {
            if ($w > $self->{w}) {
                push @$row, 0
                    for 1..($w - $self->{w});
            }
            else {
                pop @$row
                    for 1..($self->{w} - $w);
            }
        }
        $self->{w} = $w;
    }
    return $self->{w};
}


sub height {
    my $self = shift;
    my ($h) = @_;
    if (defined($h)) {
        if ($h > $self->{h}) {
            push @{ $self->{pixels} }, [ (0) x $self->{w} ]
                for 1..($h - $self->{h});
        }
        else {
            pop @{ $self->{pixels} }
                for 1..($self->{h} - $h);
        }
        $self->{h} = $h;
    }
    return $self->{h};
}


sub max_pixel_value {
    my $self = shift;
    my ($max) = @_;
    if (defined($max)) {
        for my $row (@{ $self->{pixels} }) {
            @$row = map { $_ * $self->{max} / $max } @$row;
        }
        $self->{max} = $max;
    }
    return $self->{max};
}


sub pixel {
    my $self = shift;
    my ($row, $col, $new_value) = @_;

    if (defined($new_value)) {
        $new_value = ref($new_value)
            ? [ map { $_ * $self->{max} } @$new_value ]
            : $new_value * $self->{max};
    }
    my $pixel = $self->raw_pixel($row, $col, $new_value);
    return [ map { $_ / $self->{max} } @$pixel ];
}


sub raw_pixel {
    my $self = shift;
    my ($row, $col, $new_value) = @_;

    my $pixel = $self->{pixels}[$row][$col];
    die "invalid pixel location ($row, $col)"
        unless defined $pixel;

    if (defined($new_value)) {
        $self->{pixels}[$row][$col] = $new_value;
        $pixel = $new_value;
    }

    if (!ref $pixel) {
        $pixel = [ $pixel, $pixel, $pixel ];
    }

    return $pixel;
}

sub _as_string_P1 {
    my $self = shift;

    my $data = <<HEADER;
P1
$self->{w} $self->{h}
HEADER

    for my $row (@{ $self->{pixels} }) {
        $data .= join(' ', map {
            my $val;
            if (ref($_)) {
                $val = $self->_to_greyscale(@$_);
            }
            else {
                $val = $_;
            }
            $val * 2 > $self->{max} ? '0' : '1'
        } @$row) . "\n";
    }

    return $data;
}

sub _as_string_P2 {
    my $self = shift;

    my $data = <<HEADER;
P2
$self->{w} $self->{h}
$self->{max}
HEADER

    for my $row (@{ $self->{pixels} }) {
        $data .= join(' ', map {
            if (ref($_)) {
                $self->_to_greyscale(@$_)
            }
            else {
                $_
            }
        } @$row) . "\n";
    }

    return $data;
}

sub _as_string_P3 {
    my $self = shift;

    my $data = <<HEADER;
P3
$self->{w} $self->{h}
$self->{max}
HEADER

    for my $row (@{ $self->{pixels} }) {
        $data .= join(' ', map {
            ref($_) ? join(' ', @$_) : "$_ $_ $_"
        } @$row) . "\n";
    }

    return $data;
}

sub _as_string_P4 {
    my $self = shift;

    my $data = <<HEADER;
P4
$self->{w} $self->{h}
HEADER

    for my $row (@{ $self->{pixels} }) {
        my @vals = map {
            my $val;
            if (ref($_)) {
                $val = $self->_to_greyscale(@$_);
            }
            else {
                $val = $_;
            }
            $val * 2 > $self->{max} ? '0' : '1'
        } @$row;
        push @vals, '0' until @vals % 8 == 0;
        while (@vals) {
            my $bits = join('', splice(@vals, 0, 8));
            my $byte = oct("0b$bits");
            $data .= pack("C", $byte);
        }
    }

    return $data;
}

sub _as_string_P5 {
    my $self = shift;

    my $data = <<HEADER;
P5
$self->{w} $self->{h}
$self->{max}
HEADER

    for my $row (@{ $self->{pixels} }) {
        $data .= pack("C*", map {
            if (ref($_)) {
                $self->_to_greyscale(@$_)
            }
            else {
                $_
            }
        } @$row);
    }

    return $data;
}

sub _as_string_P6 {
    my $self = shift;

    my $data = <<HEADER;
P6
$self->{w} $self->{h}
$self->{max}
HEADER

    for my $row (@{ $self->{pixels} }) {
        $data .= pack("C*", map {
            ref($_) ? @$_ : ($_, $_, $_)
        } @$row);
    }

    return $data;
}

sub _parse_string {
    my $self = shift;
    my ($string) = @_;

    return $self->_parse_pnm(sub {
        my ($line, $rest) = split /\n/, $string, 2;
        return unless length($line) || length($rest);
        $string = $rest;
        return "$line\n";
    });
}

sub _parse_file {
    my $self = shift;
    my ($filename) = @_;

    open my $fh, '<', $filename
        or die "Couldn't open $filename for reading: $!";

    return $self->_parse_pnm(sub { scalar <$fh> });
}

sub _parse_pnm {
    my $self = shift;
    my ($next_line) = @_;

    my $next_line_nocomments = sub {
        my $line;
        while (!length($line)) {
            $line = $next_line->();
            return unless defined($line);
            $line =~ s/#.*//s;
        }
        return $line;
    };

    chomp(my $format = $next_line_nocomments->());
    chomp(my $dimensions = $next_line_nocomments->());

    my ($w, $h) = $dimensions =~ /^([0-9]+)\s+([0-9]+)$/;
    die "Invalid dimensions: $dimensions"
        unless $w && $h;
    $self->{w} = $w;
    $self->{h} = $h;

    my $method = "_parse_pnm_$format";
    die "Don't know how to parse PNM files of format $format"
        unless $self->can($method);
    return $self->$method($next_line_nocomments);
}

sub _parse_pnm_P1 {
    my $self = shift;
    my ($next_line) = @_;

    $self->{max} = 1;

    my $next_word = $self->_make_next_word($next_line, 0);

    $self->{pixels} = [];
    for my $i (1..$self->{h}) {
        my $row = [];
        for my $j (1..$self->{w}) {
            push @$row, $next_word->() ? '0' : '1';
        }
        push @{ $self->{pixels} }, $row;
    }
}

sub _parse_pnm_P2 {
    my $self = shift;
    my ($next_line) = @_;

    chomp (my $max = $next_line->());
    die "Invalid max color value: $max"
        unless $max =~ /^[0-9]+$/ && $max > 0;
    $self->{max} = $max;

    my $next_word = $self->_make_next_word($next_line, 1);

    $self->{pixels} = [];
    for my $i (1..$self->{h}) {
        my $row = [];
        for my $j (1..$self->{w}) {
            push @$row, $next_word->();
        }
        push @{ $self->{pixels} }, $row;
    }
}

sub _parse_pnm_P3 {
    my $self = shift;
    my ($next_line) = @_;

    chomp (my $max = $next_line->());
    die "Invalid max color value: $max"
        unless $max =~ /^[0-9]+$/ && $max > 0;
    $self->{max} = $max;

    my $next_word = $self->_make_next_word($next_line, 1);

    $self->{pixels} = [];
    for my $i (1..$self->{h}) {
        my $row = [];
        for my $j (1..$self->{w}) {
            push @$row, [
                $next_word->(),
                $next_word->(),
                $next_word->(),
            ];
        }
        push @{ $self->{pixels} }, $row;
    }
}

sub _parse_pnm_P4 {
    my $self = shift;
    my ($next_line) = @_;

    $self->{max} = 1;

    my $next_word = $self->_make_next_bitfield($next_line, 1);

    $self->{pixels} = [];
    for my $i (1..$self->{h}) {
        my $row = [];
        for my $j (1..$self->{w}) {
            push @$row, $next_word->() ? '0' : '1';
        }
        push @{ $self->{pixels} }, $row;
    }
}

sub _parse_pnm_P5 {
    my ($self) = shift;
    my ($next_line) = @_;

    chomp (my $max = $next_line->());
    die "Invalid max color value: $max"
        unless $max =~ /^[0-9]+$/ && $max > 0;
    $self->{max} = $max;

    my $next_word = $self->_make_next_bitfield($next_line, 0);

    $self->{pixels} = [];
    for my $i (1..$self->{h}) {
        my $row = [];
        for my $j (1..$self->{w}) {
            push @$row, $next_word->();
        }
        push @{ $self->{pixels} }, $row;
    }
}

sub _parse_pnm_P6 {
    my $self = shift;
    my ($next_line) = @_;

    chomp (my $max = $next_line->());
    die "Invalid max color value: $max"
        unless $max =~ /^[0-9]+$/ && $max > 0;
    $self->{max} = $max;

    my $next_word = $self->_make_next_bitfield($next_line, 0);

    $self->{pixels} = [];
    for my $i (1..$self->{h}) {
        my $row = [];
        for my $j (1..$self->{w}) {
            push @$row, [
                $next_word->(),
                $next_word->(),
                $next_word->(),
            ];
        }
        push @{ $self->{pixels} }, $row;
    }
}

sub _make_next_word {
    my $self = shift;
    my ($next_line, $ws) = @_;

    my @words;
    return sub {
        if (!@words) {
            my $line = $next_line->();
            return unless $line;
            chomp($line);
            if ($ws) {
                @words = split ' ', $line;
            }
            else {
                @words = split '', $line;
            }
        }
        my $word = shift @words;
        die "Invalid color: $word"
            unless $word =~ /^[0-9]+$/ && $word >= 0 && $word <= $self->{max};
        return $word;
    };
}

sub _make_next_bitfield {
    my $self = shift;
    my ($next_line, $bits) = @_;

    my @words;
    return sub {
        if (!@words) {
            my $line = $next_line->();
            return unless $line;
            if ($bits) {
                my $padding = 8 - ($self->{w} % 8);
                my $per = int($self->{w} / 8) + 1;
                while (length($line)) {
                    my $chunk = substr($line, 0, $per, '');
                    push @words, map {
                        split '', sprintf("%08b", $_)
                    } unpack("C*", $chunk);
                    pop @words for 1..$padding;
                }
            }
            else {
                @words = unpack("C*", $line);
            }
        }
        my $word = shift @words;
        die "Invalid color: $word"
            unless $word =~ /^[0-9]+$/ && $word >= 0 && $word <= $self->{max};
        return $word;
    };
}

sub _to_greyscale {
    my $self = shift;
    my ($r, $g, $b) = @_;
    # luma calculation
    # https://en.wikipedia.org/wiki/YUV
    int(0.2126*$r + 0.7152*$g + 0.0722*$b + 0.5)
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::PNM - parse and generate PNM (PBM, PGM, PPM) files

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Image::PNM;

  my $image = Image::PNM->new("image.pbm");
  my $pixel_value = $image->pixel(1, 2);
  open my $fh, '>', 'new_image.ppm';
  $fh->print($image->as_string("P3")); # convert to rgb format

=head1 DESCRIPTION

This module can read and write images in any of the PNM formats (PBM, PGM, or
PPM).

=head1 METHODS

=head2 new($data)

Creates a new image object. If C<$data> is a string, it is interpreted as a
filename to open, otherwise if it is a scalar reference, it is interpreted as a
reference to a string containing the contents of a PNM file. If it is not
passed at all, a new PNM file is created with width and height of 1, a max
pixel value of 1, and the sole pixel having value 0.

=head2 as_string($format)

Converts the image object into a PNM format (given by the required argument).
Returns the PNM data as a string.

=head2 width($w)

Returns the width of the image in pixels. If C<$w> is given, sets the width of
the image to C<$w>.

=head2 height($h)

Returns the height of the image in pixels. If C<$h> is given, sets the height
of the image to C<$h>.

=head2 max_pixel_value

Returns the maximum value allowed for a pixel. Pixel values must be integers,
and they are interpreted as being scaled by this value.

=head2 pixel($row, $col, $new_value)

Returns the value of a pixel at the given C<$row> and C<$col>. The value is
returned as an arrayref of three RGB values, where each value ranges from
C<0.0> to C<1.0>.

=head2 raw_pixel($row, $col, $new_value)

Returns the value of a pixel at the given C<$row> and C<$col>. The value is
returned as an arrayref of three RGB values, where each value is an integer
ranging from C<0> to C<< $image->max_pixel_value >>.

=head1 BUGS

Please report any bugs to GitHub Issues at
L<https://github.com/doy/image-pnm/issues>.

=head1 SEE ALSO

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Image::PNM

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Image-PNM>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-PNM>

=item * Github

L<https://github.com/doy/image-pnm>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-PNM>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
