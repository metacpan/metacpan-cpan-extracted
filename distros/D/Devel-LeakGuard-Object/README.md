# Devel::LeakGuard::Object

[![GitHub build status](https://github.com/AndyA/Devel--LeakGuard--Object/actions/workflows/linux.yml/badge.svg)](https://github.com/AndyA/Devel--LeakGuard--Object/actions/workflows/linux.yml)
[![Coverage
Status](https://coveralls.io/repos/github/AndyA/Devel--LeakGuard--Object/badge.svg)](https://coveralls.io/github/AndyA/Devel--LeakGuard--Object)
[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/7l5bjd6yknpiij2x/branch/master?svg=true)](https://ci.appveyor.com/project/paultcochrane/devel-leakguard-object-livqc/branch/master)

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

Copyright (C) 2009-2026, Andy Armstrong

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
