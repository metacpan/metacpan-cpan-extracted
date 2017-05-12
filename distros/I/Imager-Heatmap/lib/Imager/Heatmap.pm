package Imager::Heatmap;
use 5.008000;
use strict;
use warnings;
use utf8;
use XSLoader;
use Carp;
use Imager;
use List::Util qw/ max /;

our $VERSION = '0.03';
our %DEFAULTS = (
    xsigma      => 1,
    ysigma      => 1,
    correlation => 0.0,
);

XSLoader::load __PACKAGE__, $VERSION;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    unless (exists $args{xsize} && exists $args{ysize}) {
        croak "You need to specify xsize and ysize";
    }
    $self->xsize(delete $args{xsize});
    $self->ysize(delete $args{ysize});

    $self->xsigma     ((exists $args{xsigma})      ? delete $args{xsigma}      : $DEFAULTS{xsigma});
    $self->ysigma     ((exists $args{ysigma})      ? delete $args{ysigma}      : $DEFAULTS{ysigma});
    $self->correlation((exists $args{correlation}) ? delete $args{correlation} : $DEFAULTS{correlation});

    if (keys %args) {
        croak "You did specify some unkown options: " . join ',', keys %args;
    }

    return $self;
}

sub xsize {
    my $self = shift;

    if (@_) {
        if ($_[0] < 0) { croak "xsize must be a positive number" }
        $self->{xsize} = $_[0];

        $self->_invalidate_matrix;
    }
    return $self->{xsize};
}

sub ysize {
    my $self = shift;

    if (@_) {
        if ($_[0] < 0) { croak "ysize must be a positive number" }
        $self->{ysize} = $_[0];

        $self->_invalidate_matrix;
    }
    return $self->{ysize};
}

sub xsigma {
    my $self = shift;

    if (@_) {
        if ($_[0] < 0.0) { croak "xsigma should be a positive number" }
        $self->{xsigma} = $_[0];
    }
    return $self->{xsigma}
}

sub ysigma {
    my $self = shift;

    if (@_) {
        if ($_[0] < 0.0) { croak "ysigma should be a positive number" }
        $self->{ysigma} = $_[0];
    }
    return $self->{ysigma}
}

sub correlation {
    my $self = shift;

    if (@_) {
        if ($_[0] < -1 || $_[0] > 1) {
            croak "correlation should be a number between -1 and 1";
        }
        $self->{correlation} = $_[0];
    }
    return $self->{correlation}
}

sub _invalidate_matrix {
    (shift)->{matrix} = undef;
}

sub matrix {
    my $self = shift;

    # Initialize array for size xsize * ysize and fill it by zero
    unless (defined $self->{matrix}) {
        $self->{matrix} = [ (0)x($self->xsize*$self->ysize) ];
    }

    return $self->{matrix};
}

sub insert_datas {
    my $self = shift;

    $self->{matrix} = xs_build_matrix(
        $self->matrix, \@_, # Insert datas
        $self->xsize, $self->ysize,
        $self->xsigma, $self->ysigma, $self->correlation,
    );
}

sub draw {
    my $self = shift;

    my $img = Imager->new(
        xsize    => $self->xsize,
        ysize    => $self->ysize,
        channels => 4,
    );

    my $matrix  = $self->matrix;

    my ($w, $h) = ($self->xsize, $self->ysize);
    my $max     = max(@{ $matrix });

    unless ($max) {
        carp "Nothing to be rendered";
        return $img;
    }

    my %color_cache;
    for (my $y = 0; $y < $h; $y++) {
        my @linedata = map {
            my $hue   = int((1 - $_/$max)*240);
            my $alpha = int(sqrt($_/$max)*255);

            $color_cache{"$hue $alpha"} ||= Imager::Color->new(
                hue        => $hue,
                saturation => 1.0,
                value      => 1.0,
                alpha      => $alpha,
            );
        } @$matrix[$y*$w..$y*$w+$w-1];

        $img->setscanline('y' => $y, pixels => \@linedata);
    }

    return $img;
}

1;
__END__

=head1 NAME

Imager::Heatmap - Perl extension for drawing Heatmap using Imager

=head1 SYNOPSIS

    use Imager::Heatmap;
    my $hmap = Imager::Heatmap->new(
        xsize  => 640,        # Image width
        ysize  => 480,        # Image height
        xsigma => 10,         # Sigma value of X-direction
        ysigma => 10,         # Sigma value of Y-direction
    );

    # Add point datas to construct density matrix
    $hmap->insert_datas(@piont_datas); # @point_datas should be: ( [ x1, y1, weight1 ], [ x2, y2, weight2 ] ... )

    $hmap->insert_datas(...); # You can call multiple times to add large data that cannot process at a time.

    # After adding datas, you could get heatmap as Imager instance.
    my $img = $hmap->draw;

    # Returned image is 4-channels image. So you can overlay it on other images.
    $base_img->rubthrough( src => $hmap->img );  # Overlay on other images(see Imager::Transformations)

    # And you can access probability density matrix using matrix method if you like.
    # In case, maybe you would like to create some graduations which be assigned to color of heatmap and its value.
    $hmap->matrix;

=head1 DESCRIPTION

Imager::Heatmap is a module to draw heatmap using Imager.

This module calculates probability density matrix from input data and
map a color for each pixels to represent density of input data.

=head1 METHODS

=head2 new()

Create a blessed object of Imager::Heatmap.
You can specify some options as follows.
See the accessors description for more details about each parameters.

    $hmap = Imager::Heatmap->new(xsize => 300, ysize => 300);

=head3 Options

=over

=item o xsize       (required)

X-direction size of heatmap image.
 
=item o ysize       (required)

Y-direction size of heatmap image.

=item o xsigma      (optional, default: 1.0)

Sigma value of X-direction.

=item o ysigma      (optional, default: 1.0)

Sigma value of Y-direction.

=item o correlation (optional, default: 0.0)

Correlation between X and Y.

=back

=head2 xsize()

Set/Get the X-direction size of heatmap image.
Constructed matrix will invalidated after call this method as "Setter".

    $hmap->xsize(100);
    $xsize = $hmap->xsize;

=head2 ysize()

Set/Get the Y-direction size of heatmap image.
Constructed matrix will invalidated after call this method as "Setter".

    $hmap->ysize(100);
    $ysize = $hmap->ysize;

=head2 xsigma()
    
Set/Get the Sigma value of X-direction.
This value represents the standard deviation of X-direction.
This value should be positive number.
You will see the heatmap that amplicifed for X-direction if you increment this number.

    $hmap->xsigma(10.0);
    $xsigma = $hmap->xsigma;

=head2 ysigma()
    
Set/Get the Sigma value of Y-direction.
This value represents the standard deviation of Y-direction.
This value should be positive number.
You will see the heatmap that amplicifed for Y-direction if you increment this number.

    $hmap->ysigma(10.0);
    $ysigma = $hmap->ysigma;

=head2 correlation()
    
Set/Get the correlation coefficient of XY;
This value represents correlation between X and Y.
This value should be the number between -1 and 1. (includeing -1 and 1)

    $hmap->correlation(0.5);
    $correlation = $hmap->correlation;

=head2 insert_datas()

Construct the matrix that represents probability density of each pixels of image.
This method may be take a while if the datas are large.

    $hmap->insert_datas([ $x1, $y1, $weight1 ], [ $x2, $y2 ], ...);

Each element of array should contain
x([0]), y([1]), and optionally weight([2]) as follows:
    
@insert_datas = ( [ x1, y1, weight1 ], [ x2, y2, weight2 ] ... );

The default value of weight is 1.

x and y will implicitly cast to integer in XS,
so it doesn't make any sense specifying real numbers to these parameters.

weight can be a real number.

=head2 draw()

Draw a heatmap from a constructed probability density matrix and return it.

    my $img = $hmap->draw;

Rerturn value is blessed object of Imager.
It is created as following options($self is blessed object of Imager::Heatmap)

    my $img = Imager->new(
        xsize    => $self->xsize,
        ysize    => $self->ysize,
        channels => 4,
    );

=head2 matrix()

Get the processed probability density matrix.

    $matrix = $hmap->matrix;

Return value is flat array. You can access the value of pixel(x,y) as follows:

    $pixel_value = $matrix->[$y * $hmap->xsize + $x];

=head1 2-dimensional Probability Desnsity Matrix

Imager::Heatmap calculates probability density matrix of input datas.

You can find the equation used to calculate 2-dimensional probability density matrix at following location:

    http://en.wikipedia.org/wiki/Multivariate_normal_distribution#Bivariate_case

=head1 SEE ALSO

Imager(3), Imager::Transformations(3)
    
The equation used to calculate 2-dimensional probability density matrix: 
    Multivariate normal distribution - Wikipedia, the free encyclopedia
        http://en.wikipedia.org/wiki/Multivariate_normal_distribution#Bivariate_case

=head1 AUTHOR

Yuto KAWAMURA(kawamuray), E<lt>kawamuray.dadada@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Yuto KAWAMURA(kawamuray)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
