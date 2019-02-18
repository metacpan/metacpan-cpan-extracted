# NAME

Math::FitRect - Resize one rect in to another while preserving aspect ratio.

# SYNOPSIS

    use Math::FitRect;
    
    # This will return: {w=>40, h=>20, x=>0, y=>10}
    my $rect = fit_rect( [80,40] => 40 );
    
    # This will return: {w=>80, h=>40, x=>-19, y=>0}
    my $rect = crop_rect( [80,40] => 40 );

# DESCRIPTION

This module is very simple in its content but can save much time, much like
other simplistic modules like [Data::Pager](https://metacpan.org/pod/Data::Pager).  This module is useful for
calculating what size you should resize images as for such things as
thumbnails.

# RECTANGLES

Rectangles may be specified in several different forms to fit your needs.

- A simple scalar integer containg the pixel width/height of a square.
- An array ref containing the width and height of a rectangle: \[$width,$height\]
- A hash ref containg a w (width) and h (height) key: {w=>$width,h=>$height}

# FUNCTIONS

## fit\_rect

    # This will return: {w=>40, h=>20, x=>0, y=>10}
    my $rect = fit_rect( [80,40] => 40 );

Takes two rectangles and fits the first one inside the second one.  The rectangle
that will be returned will be a hash ref with a 'w' and 'h' parameter as well
as 'x' and 'y' parameters which will specify any offset.

## crop\_rect

    # This will return: {w=>80, h=>40, x=>-19, y=>0}
    my $rect = crop_rect( [80,40] => 40 );

Like the fit\_rect function, crop\_rect takes two rectangles as a parameter and it
makes $rect1 completely fill $rect2.  This can mean that the top and bottom or
the left and right get chopped off (cropped).  This method returns a hash ref just
like fit\_rect.

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
