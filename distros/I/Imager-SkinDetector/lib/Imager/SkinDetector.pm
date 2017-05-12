# vim: ts=4 sw=4 tw=0 et
# $Id: SkinDetector.pm 136 2008-10-18 21:11:51Z Cosimo $

package Imager::SkinDetector;

use strict;
use Carp q(croak);
use File::Temp ();
use base q(Imager);

our $VERSION = '0.05';

sub new {
    my ($class, %opt) = @_;

    return unless %opt;

    my $file = $opt{file};
    my $url  = $opt{url};

    if (! defined $file && ! defined $url) {
        return;
    }

    $class = ref($class) || $class;
    my $self = Imager->new();

    # If url, download it and open a temp file
    if (defined $url && $url =~ m{^https?://}) {
        $file = _download_temp_file($url);
    }

    if (! $self->open(file=>$file)) {
        croak $self->errstr();
    }

    bless $self, $class;
}

# A rough estimate, based on all other meaningful factors
sub contains_nudity {
    my ($img) = @_;

    # All factors should have range (0..1)
    my $skinniness = $img->skinniness();
    my $coloriness = $img->has_different_colors() || 0.0001;

    # Apply gaussian function to $coloriness.

    # We assume that 0.2 (7 distinct color hues, 0.2*36)
    # is the center and maximum of our gaussian curve,
    # rapidly decreasing to zero for values lower and higher
    # than 7.

    # If the image has a color histogram with many different
    # hue intervals (max=36) then it's unlikely it contains nudity.
    # Same goes for images with 1 or 2 distinct color hues.

    # See: http://en.wikipedia.org/wiki/Gaussian_function

    $coloriness = exp(-(($coloriness - 0.2)**2 / 20));

    my $nudity_factor = $skinniness * $coloriness;

    return $nudity_factor;
}

# Make a HTTP request and save it as temporary file
sub _download_temp_file {
    my ($url) = @_;

    eval { require LWP::Simple };
    if ($@) {
        croak "Can't download URL $url without LWP";
    }

    my $pic = LWP::Simple::get($url);
    if (! $pic) {
        croak "Failed to load image at URL $url";
    }

    my $tmpf = File::Temp->new( UNLINK => 0 );
    my $file_name = $tmpf->filename();
    binmode $tmpf;
    print $tmpf $pic;
    close $tmpf;

    return $file_name;
}

sub hue_frequencies {
    my ($img) = @_;

    return unless $img;

    my $width  = $img->getwidth() - 1;
    my $height = $img->getheight() - 1;
    my @frequency = (0) x 36;
    my ($r, $g, $b,    $h, $s, $v);
    my $color;
    my $color_interval;
    my $total = 0;

    # Sample the image and check pixel colors
    for (my $x = 0; $x < $width; $x += 5) {

        for (my $y = 0; $y < $height; $y += 5) {

            next unless $color = $img->getpixel(x => $x, y => $y);

            ($r, $g, $b) = $color->rgba();
            ($h, $s, $v) = rgb2hsv($r, $g, $b);

            $color_interval = int ($h / 10);
            $frequency[$color_interval]++;
            $total++;
        }
    }

    # Normalize frequencies, removing spurious results
    if (! $total) {
        return;
    }

    for my $value (@frequency) {
        $value /= $total;
    }

    return @frequency;
}

sub minmax {
    local $_;
    my $max = my $min = $_[0];

    for(@_) {
        $max = $_ if $_ > $max;
        $min = $_ if $_ < $min;
    }
    return($min, $max);
}

# Naive rgb-to-hsv conversion. Slooow...
sub rgb2hsv {
    my($r, $g, $b) = @_;

    #$r = 255 if $r > 255;
    #$g = 255 if $g > 255;
    #$b = 255 if $b > 255;

    my($h1, $s1, $v1);
    my($max, $min, $diff);

    ($min, $max) = minmax($r, $g, $b);
    $diff = $max - $min;

    if($max == 0) {
        $h1 = $s1 = $v1 = 0;
    }
    else {
        $v1 = $max;
        $s1 = $diff / $max;
        if($s1 == 0) {
            $h1 = 0;
        }
        else {
            # Foley & VanDam HSV space
            if ($r == $max) {
                $h1 = ($g - $b) / $diff;
            }
            if ($g == $max) {
                $h1 = 2 + ($b - $r) / $diff;
            }
            if ($b == $max) {
                $h1 = 4 + ($r - $g) / $diff;
            }

            # Convert to range [0, 360] degrees
            $h1 *= 60; 
            $h1 += 360 if $h1 < 0;
        }
    }

    return($h1, $s1, $v1);
}

sub is_skin {
    my ($color) = $_[0];
    my ($r, $g, $b, $a) = $color->rgba;
    my ($h, $s, $v) = rgb2hsv($r, $g, $b);

    #print "RGBA(", join(', ', $r, $g, $b, $a), ")\n";
    #print "HSV (", join(', ', $h, $s, $v), "\n";
    #<STDIN>;

    # Hue 5..40 could be a good approximation of "white" skin
    if ($h >= 5 && $h <= 40 && $v > 60) {
        return 1;
    }

    # TODO Detect also black skin
    return 0;
}

sub is_fuzzy {
    my ($img) = @_;

    return unless $img;

    my $width  = $img->getwidth() - 1;
    my $height = $img->getheight() - 1;

    my $differences = 0;
    my $total_samples = 0;
    my ($r, $g, $b);

    # Sample first pixel
    my $color = $img->getpixel(x=>0, y=>0);
    my($r2, $g2, $b2, undef) = $color->rgba();
    my $pixel_diff = 0;
    my $pixel_diff_threshold = 40;

    # Sample the image and check how much "variance"
    # there is between pixels
    for (my $x = 5; $x < $width - 5; $x += 1) {

        for (my $y = 5; $y < $height - 5; $y += 1) {

            $color = $img->getpixel(x => $x, y => $y);
            ($r, $g, $b, undef) = $color->rgba();

            if ($r < 5 && $g < 5 && $b < 5) {
                next
            }

            $pixel_diff  = abs($r2 - $r);
            $pixel_diff += abs($g2 - $g);
            $pixel_diff += abs($b2 - $b);

            if ($pixel_diff > $pixel_diff_threshold) {
                $differences += $pixel_diff;
            }

            $r2 = $r;
            $g2 = $g;
            $b2 = $b;

            $total_samples++;
        }

    }

    if ($total_samples == 0) {
        return
    }

    $differences = $differences / $total_samples;

    return $differences;
}

sub has_different_colors {
    my ($img) = @_;

    # Filter out colors with <= 3%
    my $value_threshold = 0.04;

    # Extract hue histogram
    my @freq = $img->hue_frequencies();

    my $distinct = 0;
    for (@freq) {
        ++$distinct if $_ > $value_threshold;
    }

    # 36 is total possible different hue intervals
    return $distinct / 36;
}

sub skinniness {
    my ($img) = @_;

    return unless $img;

    my $width  = $img->getwidth() - 1;
    my $height = $img->getheight() - 1;

    my $skin_colors = 0;
    my $total_samples = 0;
    my $color;

    # Sample the image and check pixel colors
    for (my $x = 0; $x < $width; $x += 10) {
        for (my $y = 0; $y < $height; $y += 10) {

            $color = $img->getpixel(x => $x, y => $y);

            if ($color && is_skin($color)) {
                $skin_colors++;
            }

            $total_samples++;
        }
    }

    if ($total_samples == 0) {
        return
    }

    return $skin_colors / $total_samples;
}

1;

__END__

=head1 NAME

Imager::SkinDetector - Try to detect skin tones and nudity in images

=head1 SYNOPSIS

    use Imager::SkinDetector;

    # Use whatever format your Imager supports
    my $name = 'mypic.png';

    # Check a local file
    my $image = Imager::SkinDetector->new(file => $name)
        or die "Can't load image [$name]\n";

    # ... or download a remote picture via HTTP
    my $image = Imager::SkinDetector->new(url => 'http://some.server/some.pic')
        or die "Can't load image!\n";

    my $skinniness = $image->skinniness();
    printf "Image is %3.2f%% skinny\n", $skinniness * 100;

    my $prob = $image->contains_nudity();
    printf "Contains nudity with a %.2f%% probability\n", $prob * 100;

=head1 DESCRIPTION

Have you ever needed to know if an image has some amount of
skin tone color? Did you find some tool to do it?
Free software? Yes? If so, please tell me right now!

If not, welcome to Imager-SkinDetector. It uses Imager as
processing engine, so it should have a decent speed.
Don't expect miracles, though.

I'm planning to use this as part of a set of tools
to automatically classify images as nudity or
"containing skin". It's only a plan. I might succeed
one day. Most probably I won't. :-)

Feel free to provide feedback and code.


=head1 FUNCTIONS

=head2 C<is_skin($color)>

Examines an C<Imager::Color> object and tells you if it
seems to be similar to skin color.

The algorithm is as stupid as you can get. No less.
And it only detects "white" skin colors for now. Sorry.

Example:

    my $color = Imager::Color->new(0, 255, 255);
    if (Imager::SkinDetector::is_skin($color)) {
        print 'Yes, it seems to be skinny';
    } else {
        print 'Mmhhh, probably not';
    }

=head2 C<rgb2hsv(@rgb)>

Converts an RGB triplet into HSV, returned as a list of values.
C<H> is hue, 0 to 360.
C<S> is saturation, 0 to 1.
C<V> is value, 0 to 255.

Example:

    my @rgb = (255, 0, 0);
    my @hsv = Imager::SkinDetector::rgb2hsv(@rgb);

=head1 METHODS

=head2 C<contains_nudity()>

Tries to detect if image contains nudity,
by using all available methods, like C<hue_frequencies()>
and C<skinniness()>, and trying to combine their results
into something reasonable.

Returns a real value between 0 and 1.

The algorithm is basically crap, so I would be seriously
surprised if it works even for a small percentage of the
images you throw at it.

Anyway, feel free to send me interesting test cases :-)

=head2 C<hue_frequencies()>

Examines the image and returns a list of 36 relative frequencies
for color hues in the picture.

Now it outputs 36 values, corresponding to 36 intervals
in the entire spectrum, conventionally ranged from 0 to 360,
where first interval corresponds to red.

The relation between hue and number is approximately as follows:

    Hue value   Color
    ----------------------
    0 - 60	    red
    60 - 120	yellow
    120 - 180	green
    180 - 240	cyan
    240 - 300   blue
    300 - 360   magenta

=head2 C<is_fuzzy()>

Return a floating point value that tries to represent
how "fuzzy" your image is. The higher the number, the
"fuzzier" the image.

I don't know how to explain what I mean by "fuzzy", but
probably an example can:

http://search.cpan.org/src/COSIMO/Imager-SkinDetector-0.05/examples/fractal.gif

While this other one has a very low "fuzzy" factor:

http://search.cpan.org/src/COSIMO/Imager-SkinDetector-0.05/examples/sand.jpg

=head2 C<skinniness()>

Returns a real value from 0 to 1, indicating how much skin
tone color is present in the given picture.
A return value of zero means no skin tone colors.
A return value of one means a picture that contains only skin
colors.

Example:

    # You might not be able to load '.png' pictures,
    # depending on your version of Imager and OS
    my $pic = 'coolpic.png';
    my $img = Imager::SkinDetector->new(file => $pic);
    my $skin = $img->skinniness();

    # $skin = 0.21313   -> 21.3% of skin colors

=head1 AUTHOR

Cosimo Streppone, C<< <cosimo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imager-skindetector at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Imager-SkinDetector>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Imager::SkinDetector


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-SkinDetector>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Imager-SkinDetector>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Imager-SkinDetector>

=item * Search CPAN

L<http://search.cpan.org/dist/Imager-SkinDetector>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Cosimo Streppone, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

