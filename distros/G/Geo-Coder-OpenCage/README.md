
[![Build Status](https://travis-ci.org/OpenCageData/perl-Geo-Coder-OpenCage.svg?branch=master)](https://travis-ci.org/OpenCageData/perl-Geo-Code-OpenCage)
[![Kritika Analysis Status](https://kritika.io/users/OpenCage/repos/2893424605329847/heads/master/status.svg)](https://kritika.io/orgs/OpenCage/repos/2893424605329847/heads/master/)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-OpenCage.svg?style=flat-square)](https://metacpan.org/pod/Geo::Coder::OpenCage)

# Geo::Coder::OpenCage

This module provides an interface to the OpenCage geocoding service.
For more details see https://opencagedata.com/api

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

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself,
either Perl version 5.16 or, at your option, any later version of Perl 5 you may have available.
