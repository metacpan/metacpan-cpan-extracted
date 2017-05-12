# HTTP-Cache-Transparent

HTTP::Cache::Transparent is an implementation of http get that keeps a local
cache of fetched pages to avoid fetching the same data from the server
if it hasn't been updated. The cache is stored on disk and is thus
persistent between invocations.

The http-headers If-Modified-Since and ETag are used to let the server
decide if the version in the cache is up-to-date or not.

HTTP::Cache::Transparent was initially called HTTP::TransparentCache. It
was renamed on request from modules@perl.org.

## Limitations

This module has a number of limitations that you should be aware of
before using it. They are documented in the POD-documentation for the
module.

## Installation

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

## Dependencies

- LWP
- Storable    (included with perl)
- Digest::MD5 (included with perl)

All http-requests are made through the LWP module. Data is stored on disk
by the Storable module. Digest::MD5 is used for creating a hash of the
url.

## Git repository

A git repository with the sourcecode for HTTP::Cache::Transparent can
be found at https://github.com/mattiash/HTTP-Cache-Transparent.

## Copyright and license

Copyright (C) 2004-2017 by Mattias Holmlund

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


