
# Geo::Address::Formatter

A Perl module to take structured address data and format it
according to the various global/country rules.

The module runs against a set of templates and test cases from the
[address-formatting](https://github.com/opencagedata/address-formatting) project.

## Build status

[![Build Status](https://api.travis-ci.com/OpenCageData/perl-Geo-Address-Formatter.svg?branch=master)](https://travis-ci.com/github/OpenCageData/perl-Geo-Address-Formatter)
[![CPAN](https://img.shields.io/cpan/v/Geo-Address-Formatter.svg?style=flat-square)](https://metacpan.org/pod/Geo::Address::Formatter)
[![Coverage Status](https://coveralls.io/repos/github/OpenCageData/perl-Geo-Address-Formatter/badge.svg?branch=master)](https://coveralls.io/github/OpenCageData/perl-Geo-Address-Formatter?branch=master)
![Mastodon Follow](https://img.shields.io/mastodon/follow/109287663468501769?domain=https%3A%2F%2Fen.osm.town%2F&style=social)

## Usage

For docs please see [the Geo::Address::Formatter page on search.metacpan.org](https://metacpan.org/pod/Geo::Address::Formatter)
or `perldoc Geo::Address::Formatter`.

## Installation

To install into your Perl environment you can use the following command:

    $ cpan Geo::Address::Formatter

or (recommended) use `cpanm`

The address-formatting repository is added as a [git submodule](http://git-scm.com/book/en/Git-Tools-Submodules). It is
versioned, that means it won't automatically update when you run `git
pull`. To point it to a newer version of the configuration run

1. `git submodule init`
2. `git submodule update`

This will give you the templates as versions with this repository.
To fetch the latest templates available use
`git submodule foreach git pull origin master`

See also: <http://git-scm.com/book/en/Git-Tools-Submodules>

To submit new countries/territories please see the details in the
[address-formatting repository](https://github.com/opencagedata/address-formatting), this module just processes the templates

### DEVELOPMENT

    # first install Dist::Zilla
    dzil clean

    # running the test-suite
    dzil test --author

    # don't forget to increase the version number in dist.ini and CHANGES file
    dzil build

    # git push, upload to CPAN
    dzil release


### COPYRIGHT AND LICENCE

Copyright OpenCage GmbH
<cpan@opencagedata.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

### Who is OpenCage GmbH?

<a href="https://opencagedata.com"><img src="opencage_logo_300_150.png"></a>

We run a worldwide [geocoding API](https://opencagedata.com/api) and [geosearch](https://opencagedata.com/geosearch) service based on open data. 
Learn more [about us](https://opencagedata.com/about). 

We also organize [Geomob](https://thegeomob.com), a series of regular meetups for location based service creators, where we do our best to highlight geoinnovation. If you like geo stuff, you will probably enjoy [the Geomob podcast](https://thegeomob.com/podcast/).

