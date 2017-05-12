# NAME

Image::Density::TIFF

# SYNOPSIS

    use Image::Density::TIFF;
    print "Density: %f\n", tiff_density("foo.tif"); # single-page
    print "Densities: ", join(", ", tiff_densities("bar.tif")), "\n"; # multi-page

# DESCRIPTION

A trivial density calculation would count the number of black pixels and
divide by the total number of pixels. However, it would produce misleading
results in the case where the image contains one or more target areas with
scanned content and large blank areas in between (imagine a photocopy of a
driver's license in the middle of a page).

The metric implemented here estimates the density of data where there _is_
data, and has a
reasonable correlation with goodness as judged by humans. That is, if you
let a human look at a set of images and judge quality, the density values for
those images as calculated here tend to correlate well with the human
judgement (densities that are too high or too low represent "bad" images).

This algorithm is intended for use on bitonal TIFF images, such as those from
scanning paper documents.

## The calculation

We omit the margins because there is likely to be noise there, such as black
strips due to page skew. This does admit the possibility that we are skipping
over something important, but the margin skipping here worked well on the
test images.

Leading and trailing white on a row are omitted from counting, as are runs of
white at least as long as the margin width. This helps out when we have images
with large blank areas, but decent density within the areas filled in, which
is what we really care about.

# AUTHOR

Gregor N. Purdy, Sr. <gnp@acm.org>

# COPYRIGHT

Copyright (C) 2003-2012 Gregor N. Purdy, Sr. All rights reserved.

# LICENSE

This program is free software. Its use is subject to the same license as Perl.