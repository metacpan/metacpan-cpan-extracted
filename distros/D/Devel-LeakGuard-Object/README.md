# Devel::LeakGuard::Object

[![Build Status](https://travis-ci.org/paultcochrane/Devel--LeakGuard--Object.svg?branch=master)](https://travis-ci.org/paultcochrane/Devel--LeakGuard--Object)

This module provides tracking of objects, for the purpose of detecting memory
leaks due to circular references or innappropriate caching schemes.

It is derived from, and backwards compatible with Adam Kennedy's
[Devel::Leak::Object](https://metacpan.org/pod/Devel::Leak::Object). Any
errors are mine.

## Installation

The simplest way to install this module is via the `cpanm` utility:

    cpanm Devel::LeakGuard::Object

## Installation from source

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Copyright and Licence

Copyright (C) 2009-2015, Andy Armstrong

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
