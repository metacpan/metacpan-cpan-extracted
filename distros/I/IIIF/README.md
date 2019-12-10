# NAME

IIIF - IIIF Image API implementation

[![MetaCPAN Release](https://badge.fury.io/pl/IIIF.svg)](https://metacpan.org/release/IIIF)
[![Linux Build Status](https://travis-ci.com/nichtich/IIIF.svg?branch=master)](https://travis-ci.com/nichtich/IIIF)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/dko0d7647jvfgu8w?svg=true)](https://ci.appveyor.com/project/nichtich/iiif)
[![Coverage Status](https://coveralls.io/repos/nichtich/IIIF/badge.svg)](https://coveralls.io/r/nichtich/IIIF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/IIIF.png)](http://cpants.cpanauthors.org/dist/IIIF)

# DESCRIPTION

Package IIIF provides an implementation of [IIIF ImageAPI](https://iiif.io/api/image/3.0/)
based on the [ImageMagick](https://www.imagemagick.org/) command line application: Requests
to get a specific segment of an image are mapped to command line arguments of ImageMagick
to perform the requested segment extraction. See ["EXAMPLES" in i3f](https://metacpan.org/pod/i3f#EXAMPLES) for examples.

# FEATURES

- Full [IIIF ImageAPI 3.0](https://iiif.io/api/image/3.0/) level 2 compliance
- Support abbreviated requests (e.g. `300,200` to select size, `90/gray` to
select rotation and quality...).
- Web service ([IIIF::ImageAPI](https://metacpan.org/pod/IIIF::ImageAPI)) and command line client ([i3f](https://metacpan.org/pod/i3f))
- fully passing the [IIIF Image API Validator](https://iiif.io/api/image/validator/)
with all Level 2 features (except some 
[inexplicable test failures](https://github.com/nichtich/IIIF/issues/8#issuecomment-545852786)
with PDF, WebP, and JP2 format).
- works with ImageMagick 6 (tested on Ubuntu Linux) and ImageMagick 7 (tested on Windows)
- 100% [test coverage](https://coveralls.io/github/nichtich/IIIF) on statement
level, (>90% on branch level and >70% on condition level).

# INSTALLATION

See also ["REQUIREMENTS" in IIIF::Magick](https://metacpan.org/pod/IIIF::Magick#REQUIREMENTS) for additional installation for optional
features.

## UNIX

Most Unixes include system Perl by default. You should also install ImageMagick and
[cpanminus](https://metacpan.org/pod/App::cpanminus#INSTALLATION). For instance at
Ubuntu Linux:

    sudo apt-get install imagemagick cpanminus

To speed up installation of Perl dependencies of this package, optionally:

    sudo apt-get install libplack-perl libplack-middleware-crossorigin-perl

And for optional support of WebP format:

    sudo apt-get install webp libwebp-dev

Then install IIIF with Perl package manager:

    cpanm IIIF

## WINDOWS

Install ImageMagick and Perl, for instance with [Chocolatey](https://chocolatey.org):

    choco install imagemagick.tool
    choco install strawberryperl

Then install IIIF with Perl package manager:

    cpanm IIIF

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
