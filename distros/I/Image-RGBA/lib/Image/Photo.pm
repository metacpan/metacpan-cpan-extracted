package Image::Photo;

=head1 NAME

Image::Photo - Functions for sampling simple Photographic images

=head1 SYNOPSIS

Photographic lens correction.

=head1 DESCRIPTION

An extension of the Image::RGBA suitable for sampling photographic
images

Provided is optional radial luminance correction - Suitable for sampling
photographs where there is a known light falloff from the centre of the
image to the edges.

Also radial lens distortion can be corrected at the same time.

=head1 USAGE

You can start by creating an Image::Magick object:

    my $input = new Image::Magick;
    $input->Read ('input.jpg');

=cut

use strict;
use warnings;

use Image::RGBA;

use vars qw /@ISA/;
@ISA = qw /Image::RGBA/;

our $VERSION = '0.01';

=pod

Use an Image::Magick object as the basis of an Image::Photo
object:

    my $rgba = new Image::Photo (sample => 'linear',
                                 radlum => 0,
                                  image => $input,
                                      a => 0.0,
                                      b => -0.2,
                                      c => 0.0);

The parameters 'sample', 'radlum', 'a', 'b' and 'c' are quality settings
(see descriptions below).

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;

    my $params = {@_};

    #my $self = new Image::RGBA (%$params);

    my $self = $class->SUPER::new (%$params);

    # various photo calculations reuse values derived from the width
    # and height.  May as well calculate them at the start.

    $self->{w2} = $self->{width} / 2;
    $self->{h2} = $self->{height} / 2;

    if ($self->{width} < $self->{height}) { $self->{diameter} = $self->{width} }
    else { $self->{diameter} = $self->{height} }

    $self->{radius} = $self->{diameter} / 2;

    # attributes specific to photos

    $self->{radlum} = $params->{radlum} || 0;

    $self->{a} = $params->{a} || 0;
    $self->{b} = $params->{b} || 0;
    $self->{c} = $params->{c} || 0;

#    bless $self, $class;

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

    # lens correction is expensive, so only do it if necessary.

    ($m, $n) = $self->Correct ($m, $n)
        unless ($self->{a} eq 0 && $self->{b} eq 0 && $self->{c} eq 0);

    # do the actual sampling

    my ($r, $g, $b, $a) = $self->_sample ($m, $n);

    # radial luminance correction is expensive, so only do it if necessary.
    
    ($r, $g, $b, $a) = $self->_adjust_luminance ($m, $n, $r, $g, $b, $a)
        if ($self->{radlum});

    return $self->_pack ($r, $g, $b, $a);
}

=pod

=head1 OPTIONS

=head2 LENS CORRECTION

'a', 'b' and 'c' parameters relate to lens correction of images.  For an
explanation, see:

 http://www.fh-furtwangen.de/~dersch/barrel/barrel.html

The default values are all '0', which equates to no lens correction.

In addition, the mathematical distortion can be queried directly using the
Correct method:

    ($p, $q) = $self->Correct ($m, $n)

=cut

sub Correct
{
    my $self = shift;

    my $m = shift;
    my $n = shift;

    my $rd = sqrt (($m - $self->{w2}) * ($m - $self->{w2}) + ($n - $self->{h2}) * ($n - $self->{h2}))
           / $self->{radius};

    my $foo = $self->{a} * $rd * $rd * $rd
            + $self->{b} * $rd * $rd
            + $self->{c} * $rd
            + 1 - $self->{a} - $self->{b} - $self->{c};

    $m = (($m - $self->{w2}) * $foo) + $self->{w2};
    $n = (($n - $self->{h2}) * $foo) + $self->{h2};

    return ($m, $n);

}

=pod

=head2 RADIAL LUMINANCE

The 'radlum' value can be used to fix radial luminance variation in the
source image.  Typically a photograph will be brighter in the centre
than at the edges - A small positive number, eg. '10', will try to
correct for this.

The number represents the difference in luminance between the centre and the
nearest edge, the units assume a range of 256 between black and white.

The default is '0', no radial luminance correction.

Radial luminance correction is loosely based on that provided by the
Panorama Tools Correct plugin, with a couple of variations that should
make it more suitable for batch processing images.

=cut

sub _adjust_luminance
{
    my $self = shift;

    my ($m, $n, $r, $g, $b, $a) = @_;

    my $factor = $self->_calc_luminance ($m, $n);

    $r *= $factor; $g *= $factor; $b *= $factor;

    # adjusting luminance may send some pixels out-of-range

    $self->_valid_pixel_values ($r, $g, $b, $a);
}

sub _calc_luminance
{
    my $self = shift;

    my $m = shift;
    my $n = shift;

    # The first bit is the same method as ptools 'correct'

    $m = $m - $self->{w2};
    $n = $n - $self->{h2};

    my $k = ($self->{radlum} / 2)
          - ((($m * $m) + ($n * $n)) * ($self->{radlum} / ($self->{radius} * $self->{radius})));

    # ptools just subtracts $k from the colour values, shifting the
    # brightness
    # $r -= $k; $g -= $k; $b -= $k;
    # alternative method scales rather than shifts values

    return 1 - ($k / 127);
}

=pod

=head1 COPYRIGHT

Copyright (c) 2002 Bruno Postle <bruno@postle.net>. All Rights Reserved.
This module is Free Software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut

1;

