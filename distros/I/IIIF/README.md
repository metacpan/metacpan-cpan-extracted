# NAME

IIIF - IIIF Image API implementation

[![MetaCPAN Release](https://badge.fury.io/pl/IIIF.svg)](https://metacpan.org/release/IIIF)
[![Linux Build Status](https://travis-ci.com/nichtich/IIIF.svg?branch=master)](https://travis-ci.com/nichtich/IIIF)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/dko0d7647jvfgu8w?svg=true)](https://ci.appveyor.com/project/nichtich/iiif)
[![Coverage Status](https://coveralls.io/repos/nichtich/IIIF/badge.svg)](https://coveralls.io/r/nichtich/IIIF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/IIIF.png)](http://cpants.cpanauthors.org/dist/IIIF)

# DESCRIPTION

Module IIIF provides an implementation of [IIIF ImageAPI](https://iiif.io/api/image/3.0/)
based on the [ImageMagick](https://www.imagemagick.org/) command line application.

# MODULES

- [IIIF::Request](https://metacpan.org/pod/IIIF::Request)

    parse and express an IIIF Image API request build of region, size, rotation, quality, and format

- [IIIF::Magick](https://metacpan.org/pod/IIIF::Magick)

    get image information and convert images as specified with IIIF Image API request using ImageMagick

- [IIIF::ImageAPI](https://metacpan.org/pod/IIIF::ImageAPI)

    provide a [Plack](https://metacpan.org/pod/Plack) web service to access images via IIIF Image API

# SCRIPTS

This module provides the command line script [i3f](https://metacpan.org/pod/i3f) to apply IIIF Image API requests without a web service.

# SEE ALSO

- [https://github.com/IIIF/awesome-iiif](https://github.com/IIIF/awesome-iiif)
- [Image::Magick](https://metacpan.org/pod/Image::Magick)
- [Plack::App::ImageMagick](https://metacpan.org/pod/Plack::App::ImageMagick)

# LICENSE

Copyright (C) Jakob Voß.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jakob Voß <voss@gbv.de>
