[![Build Status](https://travis-ci.org/dayflower/p5-Image-JPEG-EstimateQuality.png?branch=master)](https://travis-ci.org/dayflower/p5-Image-JPEG-EstimateQuality)
# NAME

Image::JPEG::EstimateQuality - Estimate quality of JPEG images.

# SYNOPSIS

    use Image::JPEG::EstimateQuality;

    jpeg_quality('filename.jpg');   # => 1..100 integer value
    jpeg_quality(FILEHANDLE);
    jpeg_quality(\$image_data);

# DESCRIPTION

Image::JPEG::EstimateQuality determines quality of JPEG file.
It's approximate value because the quality is not stored in the file explicitly.
This module calculates quality from luminance quantization table stored in the file.

# METHODS

- jpeg\_quality($stuff)

    Returns quality (1-100) of JPEG file.

        scalar:     filename
        scalarref:  JPEG data itself
        file-glob:  file handle

# SCRIPT

A script `jpeg-quality` distributed with the module prints the quality of a JPEG specified on the command line:

    jpeg-quality image.jpg
    90

# LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ITO Nobuaki <daydream.trippers@gmail.com>
