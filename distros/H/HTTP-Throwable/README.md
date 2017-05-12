# HTTP-Throwable

This is a set of strongy-typed, PSGI-friendly exception
classes corresponding to the HTTP error status code
(4xx-5xx) as well as the redirection codes (3xx).

## Installation

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

## Dependencies

This module requires these other modules and libraries:

    Moo
    MooX::StrictConstructor
    Throwable
    Plack
    List::AllUtils
    Types::Standard
    Type::Tiny
    Package::Variant
    namespace::clean

## Copyright and License

Copyright (C) 2011 Infinity Interactive, Inc.

(http://www.iinteractive.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.









