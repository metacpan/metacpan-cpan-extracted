package IIIF;
use 5.014001;

our $VERSION = "0.07";

1;
__END__

=encoding utf-8

=head1 NAME

IIIF - IIIF Image API implementation

=begin markdown 

[![MetaCPAN Release](https://badge.fury.io/pl/IIIF.svg)](https://metacpan.org/release/IIIF)
[![Linux Build Status](https://travis-ci.com/nichtich/IIIF.svg?branch=master)](https://travis-ci.com/nichtich/IIIF)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/dko0d7647jvfgu8w?svg=true)](https://ci.appveyor.com/project/nichtich/iiif)
[![Coverage Status](https://coveralls.io/repos/nichtich/IIIF/badge.svg)](https://coveralls.io/r/nichtich/IIIF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/IIIF.png)](http://cpants.cpanauthors.org/dist/IIIF)

=end markdown

=head1 DESCRIPTION

Package IIIF provides an implementation of L<IIIF ImageAPI|https://iiif.io/api/image/3.0/>
based on the L<ImageMagick|https://www.imagemagick.org/> command line application: Requests
to get a specific segment of an image are mapped to command line arguments of ImageMagick
to perform the requested segment extraction. See L<i3f/EXAMPLES> for examples.

=head1 FEATURES

=over

=item

Full L<IIIF ImageAPI 3.0|https://iiif.io/api/image/3.0/> level 2 compliance

=item

Support abbreviated requests (e.g. C<300,200> to select size, C<90/gray> to
select rotation and quality...).

=item

Web service (L<IIIF::ImageAPI>) and command line client (L<i3f>)

=item

fully passing the L<IIIF Image API Validator|https://iiif.io/api/image/validator/>
with all Level 2 features (except some 
L<inexplicable test failures|https://github.com/nichtich/IIIF/issues/8#issuecomment-545852786>
with PDF, WebP, and JP2 format).

=item

works with ImageMagick 6 (tested on Ubuntu Linux) and ImageMagick 7 (tested on Windows)

=item 

100% L<test coverage|https://coveralls.io/github/nichtich/IIIF> on statement
level, (>90% on branch level and >70% on condition level).

=back

=head1 INSTALLATION

See also L<IIIF::Magick/REQUIREMENTS> for additional installation for optional
features.

=head2 UNIX

Most Unixes include system Perl by default. You should also install ImageMagick and
L<cpanminus|https://metacpan.org/pod/App::cpanminus#INSTALLATION>. For instance at
Ubuntu Linux:

  sudo apt-get install imagemagick cpanminus

To speed up installation of Perl dependencies of this package, optionally:

  sudo apt-get install libplack-perl libplack-middleware-crossorigin-perl

And for optional support of WebP format:

  sudo apt-get install webp libwebp-dev

Then install IIIF with Perl package manager:

  cpanm IIIF

=head2 WINDOWS

Install ImageMagick and Perl, for instance with L<Chocolatey|https://chocolatey.org>:

  choco install imagemagick.tool
  choco install strawberryperl

Then install IIIF with Perl package manager:

  cpanm IIIF

=head1 MODULES

=over

=item L<IIIF::Request>

parse and express an IIIF Image API request build of region, size, rotation, quality, and format

=item L<IIIF::Magick>

get image information and convert images as specified with IIIF Image API request using ImageMagick

=item L<IIIF::ImageAPI>

provide a L<Plack> web service to access images via IIIF Image API

=back

=head1 SCRIPTS

This module provides the command line script L<i3f> to apply IIIF Image API requests without a web service.

=head1 SEE ALSO

=over

=item L<https://github.com/IIIF/awesome-iiif>

=item L<Image::Magick>

=item L<Plack::App::ImageMagick>

=back

=head1 LICENSE

Copyright (C) Jakob Voß.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jakob Voß E<lt>voss@gbv.deE<gt>

=cut

