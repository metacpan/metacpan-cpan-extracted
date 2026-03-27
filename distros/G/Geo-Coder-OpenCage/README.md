# Geo::Coder::OpenCage

This module provides a Perl interface to the [OpenCage geocoding API](https://opencagedata.com).

## Build status

[![Build Tests](https://github.com/OpenCageData/perl-Geo-Coder-OpenCage/actions/workflows/ci.yml/badge.svg)](https://github.com/OpenCageData/perl-Geo-Coder-OpenCage/actions/workflows/ci.yml)[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-OpenCage.svg?style=flat-square)](https://metacpan.org/pod/Geo::Coder::OpenCage)
[![Coverage Status](https://coveralls.io/repos/github/OpenCageData/perl-Geo-Coder-OpenCage/badge.svg?branch=master)](https://coveralls.io/github/OpenCageData/perl-Geo-Coder-OpenCage?branch=master)
![Mastodon Follow](https://img.shields.io/mastodon/follow/109287663468501769?domain=https%3A%2F%2Fen.osm.town%2F&style=social)

## Usage

For docs please see [the Geo::Coder::OpenCage page on search.metacpan.org](https://metacpan.org/pod/Geo::Coder::OpenCage)
or `perldoc Geo::Coder::OpenCage`.

## INSTALLATION

To install into your Perl environment you can use the following command:

    $ cpan Geo::Coder::OpenCage

Alternatively to work on the source:

    $ git clone https://github.com/opencagedata/perl-Geo-Coder-OpenCage.git
    $ cd perl-Geo-Coder-OpenCage
    $ cpan Dist::Zilla
    $ dzil authordeps | xargs cpan
    $ dzil listdeps | xargs cpan
    $ GEO_CODER_OPENCAGE_API_KEY="<your key>" dzil test

## COPYRIGHT AND LICENCE

Copyright OpenCage GmbH <cpan@opencagedata.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.16 or, at your option, any later version of Perl 5 you may have available.

### Who is OpenCage GmbH?

<a href="https://opencagedata.com"><img src="opencage_logo_300_150.png"></a>

We run a worldwide [geocoding API](https://opencagedata.com/api) and [geosearch](https://opencagedata.com/geosearch) service based on open data. 
Learn more [about us](https://opencagedata.com/about). 

We also run [Geomob](https://thegeomob.com), a series of regular meetups for location based service creators, where we do our best to highlight geoinnovation. If you like geo stuff, you will probably enjoy [the Geomob podcast](https://thegeomob.com/podcast/).


