package Imager::Tiler;

use Imager;
use Exporter;

our @ISA = qw(Exporter);

our @EXPORT = ();
our @EXPORT_OK = qw(tile);

use strict;
use warnings;

our $VERSION = '1.010002'; # VERSION

=pod

=for stopwords EdgeMargin ImagesPerRow PNG RGB TileMargin zoffix HEdgeMargin HTileMargin VEdgeMargin VTileMargin

=head1 NAME

Imager::Tiler - package to aggregate images into a single tiled image via Imager

=head1 SYNOPSIS

    use Imager::Tiler qw(tile);
    #
    #   use computed coordinates for layout, and retrieve the
    #   coordinates for later use (as imported method)
    #
    my ($img, @coords) = tile(
        Images => [ 'chart1.png', 'chart2.png', 'chart3.png', 'chart4.png'],
        Background => 'lgray',
        Center => 1,
        VEdgeMargin => 10,
        HEdgeMargin => 10,
        VTileMargin => 5,
        HTileMargin => 5);
    #
    #   use explicit coordinates for layout (as class method)
    #
    my $explimg = Imager::Tiler->tile(
        Images => [ 'chart1.png', 'chart2.png', 'chart3.png', 'chart4.png'],
        Background => 'lgray',
        Width => 500,
        Height => 500,
        Coordinates => [
            10, 10,
            120, 10,
            10, 120,
            120, 120 ]);

=head1 DESCRIPTION

Creates a new tiled image from a set of input images. Various arguments
may be specified to position individual images, or the default
behaviors can be used to create an reasonable placement to fill a
square image.

=head1 METHODS

Only a single method is provided:

=head4 $image = Imager::Tiler->tile( %args )

=head4 ($image, @coords) = Imager::Tiler->tile( %args )

Returns a Imager::Image object of the images specified in %args,
positioned according to the directives in %arg. In array context,
also returns the list of upper left corner coordinates of each image,
so e.g., an application can adjust the image map coordinate values
for individual images.

Valid %args are:

=over 4

=item B<Background =E<gt>> C<$color> I<(optional)>

specifies a color to be used as the tiled image background. Must be a string
of either hexadecimal RGB values, I<e.g.,> B<'#FFAC24'>, or a name from
the following list of supported colors:

    white     lyellow     lpurple     lbrown
    lgray     yellow      purple      dbrown
    gray      dyellow     dpurple     transparent
    dgray     lgreen      lorange
    black     green       orange
    lblue     dgreen      pink
    blue      lred        dpink
    dblue     red         marine
    gold      dred        cyan

Default is white.

=item B<Center =E<gt>> C<$boolean> I<(optional)>

If set to a "true" value, causes images to be centered within
their computed tile location; ignored if B<Coordinates> is specified.
Default is false, which causes images to be anchored to the
upper left corner of their tile.

=item B<Coordinates =E<gt>> C<\@coords> I<(optional)>

arrayref of (X, Y) coordinates of the upper left corner of each tiled image;
must have an (X, Y) element for each input image. If not provided,
the default is a computed layout to fit images into an equal (or nearly equal)
number of rows and columns, in a left to right, top to bottom mapping in the
order specified in B<Images>. B<Note that this is not a best fit algorithm>.

If B<Coordinates> is specified, then B<Height> and B<Width> must also be
specified, and any margin values are ignored.

=item B<EdgeMargin =E<gt>> C<$pixels> I<(optional)>

outer edge margin for both top and bottom;
If either HEdgeMargin or VEdgeMargin, they override this value.

=item B<Format =E<gt>> C<$format> I<(optional)>

Output image format; default is 'PNG'; valid values depend on the
Imager installations; see L<Imager::Files> for details.

=item B<HEdgeMargin =E<gt>> C<$pixels> I<(optional)>

horizontal edge margin; space in pixels at left and right of output image;
default zero.

=item B<Height =E<gt>> C<$height> I<(optional)>

total height of output image; if not specified, defaults to
minimum height needed to contain the images

=item B<HTileMargin =E<gt>> C<$pixels> I<(optional)>

horizontal margin between tile images;
default zero.

=item B<Images =E<gt>> C<\@images> I<(required)>

arrayref of images to be tiled; may be either Imager::Image objects,
or filenames; if the latter, the format is derived from
the file qualifier

=item B<ImagesPerRow =E<gt>> C<$count> I<(optional)>

Specifies the number of images per row in the layout; ignored if
B<Coordinates> is also specified. Permits an alternate layout to
the default approximate square layout.

=item B<Shadow =E<gt>> C<boolean> I<(optional)>

When set to a true value, causes tiled image to have a small
drop shadow behind them (10 pixels along the right and lower edges).
Default false.

=item B<TileMargin =E<gt>> C<$pixels> I<(optional)>

tile image margin, both top and bottom; if either
HTileMargin or VTileMargin are specified, they override this value.

=item B<VEdgeMargin =E<gt>> C<$pixels> I<(optional)>

vertical edge margin; space in pixels at top and bottom of output image;
default zero.

=item B<VTileMargin =E<gt>> C<$pixels> I<(optional)>

vertical margin between tile images;
default zero.

=item B<Width =E<gt>> C<$width> I<(optional)>

total width of output image; if not specified, defaults to
minimum width needed to contain the images

=back

=head1 SEE ALSO

L<Imager>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Imager-Tiler>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Imager-Tiler/issues>

If you can't access GitHub, you can email your request
to C<bug-imager-tiler at rt.cpan.org>

=head1 MAINTAINER

Zoffix Znet (zoffix 'at' cpan.org)

=head1 AUTHOR, COPYRIGHT, and LICENSE

Dean Arnold L<mailto:darnold@presicient.com>

Copyright(C) 2007, 2008, Dean Arnold, Presicient Corp., USA.

Permission is granted to use, copy, modify, and redistribute this
software under the terms of the Academic Free License version 3.0, as specified at the
Open Source Initiative website L<http://www.opensource.org/licenses/afl-3.0.php>.

=cut

my %colors = (
    white    => [255,255,255],
    lgray    => [191,191,191],
    gray    => [127,127,127],
    dgray    => [63,63,63],
    black    => [0,0,0],
    lblue    => [0,0,255],
    blue    => [0,0,191],
    dblue    => [0,0,127],
    gold    => [255,215,0],
    lyellow    => [255,255,125],
    yellow    => [255,255,0],
    dyellow    => [127,127,0],
    lgreen    => [0,255,0],
    green    => [0,191,0],
    dgreen    => [0,127,0],
    lred    => [255,0,0],
    red        => [191,0,0],
    dred    => [127,0,0],
    lpurple    => [255,0,255],
    purple    => [191,0,191],
    dpurple    => [127,0,127],
    lorange    => [255,183,0],
    orange    => [255,127,0],
    pink    => [255,183,193],
    dpink    => [255,105,180],
    marine    => [127,127,255],
    cyan    => [0,255,255],
    lbrown    => [210,180,140],
    dbrown    => [165,42,42],
    transparent => [1,1,1, 0]
);
#
#   compute coordinates for tiled images
#
sub _layout {
    my ($center, $vedge, $hedge, $vtile, $htile, $imgsperrow, $shadow, @images) = @_;
    my ($rows, $cols);

    my $imgcnt = scalar @images;
    if (defined($imgsperrow)) {
        $cols = $imgsperrow;
        $rows = int($imgcnt/$cols);
        $rows++
            unless (($rows * $cols) >= $imgcnt);
    }
    else {
        $rows = $cols = int(sqrt($imgcnt));
        unless (($rows * $cols) == $imgcnt) {
            $cols++;
            $rows++
                unless (($rows * $cols) >= $imgcnt);
        }
    }
#
#   compute width and height based on input images
#
    my @rowh = ( (0) x $rows );
    my @colw = ( (0) x $cols );
    my @coords = ();
    $shadow = $shadow ? 10 : 0;
    foreach my $r (0..$rows-1) {
        $rowh[$r] = 0;
        foreach my $c (0..$cols - 1) {
            my $img = ($r * $cols) + $c;
            last unless $images[$img];

            my $w = $images[$img]->getwidth() + $shadow +
                ((($r == 0) || ($r == $rows - 1)) ? (($vtile >> 1) + $vedge) : $vtile);
            my $h = $images[$img]->getheight() + $shadow +
                ((($c == 0) || ($c == $cols - 1)) ? (($htile >> 1) + $hedge) : $htile);

            $colw[$c] = $w
                if ($colw[$c] < $w);
            $rowh[$r] = $h
                if ($rowh[$r] < $h);
        }
    }
#
#   compute total image size
#
    my ($totalw, $totalh) = ($vedge * 2, $hedge * 2);
    map $totalw += $_, @colw;
    map $totalh += $_, @rowh;
#
#   now compute placement coords
#
    my ($left, $top) = ($vedge, $hedge);
    foreach my $r (0..$#rowh) {
        foreach my $c (0..$#colw) {
            my $img = ($r * $cols) + $c;
            last unless $images[$img];

            if ($center) {
                push @coords,
                    $left + (($colw[$c] - $images[$img]->getwidth() - $shadow) >> 1),
                    $top  + (($rowh[$r] - $images[$img]->getheight() - $shadow) >> 1);
            }
            else {
                push @coords, $left, $top;
            }
            $left += $colw[$c];
        }

        $top += $rowh[$r];
        $left = $vedge;
    }
    return ($totalw, $totalh, @coords);
}

sub tile {
    shift if ($_[0] eq 'Imager::Tiler');    # if called as a object, not class, method
    my %args = @_;

    die 'No images specified.'
        unless $args{Images} && ref $args{Images} &&
            (ref $args{Images} eq 'ARRAY');

    foreach (@{$args{Images}}) {
        next if (ref $_ && $_->isa('Imager'));
        my $img = Imager->new;
        die 'Cannot load image $_:' . $img->errstr()
            unless $img->read(file => $_);
        $_ = $img;
    }

    $args{TileMargin} = 0
        unless exists $args{TileMargin};

    $args{EdgeMargin} = 0
        unless exists $args{EdgeMargin};

    $args{VEdgeMargin} = $args{EdgeMargin}
        unless exists $args{VEdgeMargin};

    $args{HEdgeMargin} = $args{EdgeMargin}
        unless exists $args{HEdgeMargin};

    $args{VTileMargin} = $args{TileMargin}
        unless exists $args{VTileMargin};

    $args{HTileMargin} = $args{TileMargin}
        unless exists $args{HTileMargin};

    my $background = $colors{white};
    if (exists $args{Background}) {
        die "Invalid Background $args{Background}."
            unless exists $colors{$args{Background}} ||
                ($args{Background}=~/^#[0-9a-fA-F]+$/);
        $background = $colors{$args{Background}} || $args{Background};
    }

    $args{Format} = 'png'
        unless exists $args{Format};

    my $format = lc $args{Format};

    my ($w, $h) = ($args{Width}, $args{Height});

    my @coords;
    if (exists $args{Coordinates}) {
        die "Width not specified for explicit placement."
            unless exists $args{Width};

        die "Height not specified for explicit placement."
            unless exists $args{Height};

        @coords = @{$args{Coordinates}};
        my $imgcnt = scalar @{$args{Images}};

        die "$imgcnt images require " . ($imgcnt * 2) . " coordinates, but only" . scalar @coords . " specified."
            if ($imgcnt * 2) > scalar @coords;
#
#   we'll permit more coords than images;
#   we also permit coords to place images outside the Width/Height
#
    }
    else {
        ($w, $h, @coords) = _layout(
            $args{Center},
            $args{VEdgeMargin},
            $args{HEdgeMargin},
            $args{VTileMargin},
            $args{HTileMargin},
            $args{ImagesPerRow},
            $args{Shadow},
            @{$args{Images}});

        die "Specified Width $args{Width} less than computed width of $w."
            if (exists $args{Width}) && ($args{Width} < $w);

        die "Specified Height $args{Height} less than computed height of $h."
            if (exists $args{Height}) && ($args{Height} < $h);
    }
#
#   now create and populate the image
#   (need a way to support truecolor ?)
#
    my $tiled = Imager->new(xsize => $w, ysize => $h, channels => 4)
        or die "Unable to create image.";

    $background = ref $background
        ? Imager::Color->new(@$background)
        : Imager::Color->new($background);
    die "Unable to create background color."
        unless defined $background;

    my $shadow = $args{Shadow}
        ? Imager::Color->new(120, 120, 120, 80)
        : undef;
    $tiled->box(box => [ 0,0, $w - 1, $h - 1], color => $background, filled => 1)
        or die $tiled->errstr();

    my $x = 0;
    foreach (@{$args{Images}}) {
        $_ = $_->convert(preset => 'addalpha');
        $w = $coords[$x++];
        $h = $coords[$x++];
        $tiled->box(box => [ $w + 9, $h + 9, $w + $_->getwidth() + 9, $h + $_->getheight() + 9],
            color => $shadow, filled => 1)
            if $shadow;
        $tiled->rubthrough(src => $_, tx => $w, ty => $h) or die $tiled->errstr();
    }
#
#   in array context, returns the coordinates so e.g. any image maps
#   can be adjusted to the tiled image's newl location
#
    my $imgdata;
    $tiled->write(data => \$imgdata, type => $format) or
        die $tiled->errstr();
    return wantarray ? ($imgdata, @coords) : $imgdata;
}

1;