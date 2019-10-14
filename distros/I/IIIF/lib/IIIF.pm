package IIIF;
use 5.014001;

our $VERSION = "0.05";

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

Module IIIF provides an implementation of L<IIIF ImageAPI|https://iiif.io/api/image/3.0/>
based on the L<ImageMagick|https://www.imagemagick.org/> command line application.

=head1 FEATURES

=over

=item

Full IIIF Image API 3.0 level 2 compliance.

=item

Tested with ImageMagick 6 (Ubuntu) and 7 (Windows)

=item 

100% L<test coverage|https://coveralls.io/github/nichtich/IIIF> on statement
level, (>90% on branch level and >70% on condition level).

=back

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

