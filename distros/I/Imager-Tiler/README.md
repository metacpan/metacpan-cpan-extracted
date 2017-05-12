# NAME

Imager::Tiler - package to aggregate images into a single tiled image via Imager

# SYNOPSIS

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

# DESCRIPTION

Creates a new tiled image from a set of input images. Various arguments
may be specified to position individual images, or the default
behaviors can be used to create an reasonable placement to fill a
square image.

# METHODS

Only a single method is provided:

#### $image = Imager::Tiler->tile( %args )

#### ($image, @coords) = Imager::Tiler->tile( %args )

Returns a Imager::Image object of the images specified in %args,
positioned according to the directives in %arg. In array context,
also returns the list of upper left corner coordinates of each image,
so e.g., an application can adjust the image map coordinate values
for individual images.

Valid %args are:

- **Background =>** `$color` _(optional)_

    specifies a color to be used as the tiled image background. Must be a string
    of either hexadecimal RGB values, _e.g.,_ **'#FFAC24'**, or a name from
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

- **Center =>** `$boolean` _(optional)_

    If set to a "true" value, causes images to be centered within
    their computed tile location; ignored if **Coordinates** is specified.
    Default is false, which causes images to be anchored to the
    upper left corner of their tile.

- **Coordinates =>** `\@coords` _(optional)_

    arrayref of (X, Y) coordinates of the upper left corner of each tiled image;
    must have an (X, Y) element for each input image. If not provided,
    the default is a computed layout to fit images into an equal (or nearly equal)
    number of rows and columns, in a left to right, top to bottom mapping in the
    order specified in **Images**. **Note that this is not a best fit algorithm**.

    If **Coordinates** is specified, then **Height** and **Width** must also be
    specified, and any margin values are ignored.

- **EdgeMargin =>** `$pixels` _(optional)_

    outer edge margin for both top and bottom;
    If either HEdgeMargin or VEdgeMargin, they override this value.

- **Format =>** `$format` _(optional)_

    Output image format; default is 'PNG'; valid values depend on the
    Imager installations; see [Imager::Files](https://metacpan.org/pod/Imager::Files) for details.

- **HEdgeMargin =>** `$pixels` _(optional)_

    horizontal edge margin; space in pixels at left and right of output image;
    default zero.

- **Height =>** `$height` _(optional)_

    total height of output image; if not specified, defaults to
    minimum height needed to contain the images

- **HTileMargin =>** `$pixels` _(optional)_

    horizontal margin between tile images;
    default zero.

- **Images =>** `\@images` _(required)_

    arrayref of images to be tiled; may be either Imager::Image objects,
    or filenames; if the latter, the format is derived from
    the file qualifier

- **ImagesPerRow =>** `$count` _(optional)_

    Specifies the number of images per row in the layout; ignored if
    **Coordinates** is also specified. Permits an alternate layout to
    the default approximate square layout.

- **Shadow =>** `boolean` _(optional)_

    When set to a true value, causes tiled image to have a small
    drop shadow behind them (10 pixels along the right and lower edges).
    Default false.

- **TileMargin =>** `$pixels` _(optional)_

    tile image margin, both top and bottom; if either
    HTileMargin or VTileMargin are specified, they override this value.

- **VEdgeMargin =>** `$pixels` _(optional)_

    vertical edge margin; space in pixels at top and bottom of output image;
    default zero.

- **VTileMargin =>** `$pixels` _(optional)_

    vertical margin between tile images;
    default zero.

- **Width =>** `$width` _(optional)_

    total width of output image; if not specified, defaults to
    minimum width needed to contain the images

# SEE ALSO

[Imager](https://metacpan.org/pod/Imager)

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Imager-Tiler](https://github.com/zoffixznet/Imager-Tiler)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Imager-Tiler/issues](https://github.com/zoffixznet/Imager-Tiler/issues)

If you can't access GitHub, you can email your request
to `bug-imager-tiler at rt.cpan.org`

# MAINTAINER

Zoffix Znet (zoffix 'at' cpan.org)

# AUTHOR, COPYRIGHT, and LICENSE

Dean Arnold [mailto:darnold@presicient.com](mailto:darnold@presicient.com)

Copyright(C) 2007, 2008, Dean Arnold, Presicient Corp., USA.

Permission is granted to use, copy, modify, and redistribute this
software under the terms of the Academic Free License version 3.0, as specified at the
Open Source Initiative website [http://www.opensource.org/licenses/afl-3.0.php](http://www.opensource.org/licenses/afl-3.0.php).
