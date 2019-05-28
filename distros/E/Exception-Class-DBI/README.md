Exception/Class/DBI version 1.02
================================

This module offers a set of DBI-specific exception classes. They inherit from
Exception::Class::Base, the base class for all exception objects created by
the [Exception::Class](http://search.cpan.org/perldoc?Exception::Class) module
from the CPAN. Exception::Class::DBI itself offers a single class method,
`handler()`, that returns a code reference appropriate for passing the
[DBI](http://search.cpan.org/perldoc?DBI) `HandleError` attribute.

The exception classes created by Exception::Class::DBI are designed to be
thrown in certain DBI contexts; the code reference returned by `handler()` and
passed to the DBI `HandleError attribute determines the context, assembles the
necessary metadata, and throws the apopropriate exception.

Each of the Exception::Class::DBI classes offers a set of object accessor
methods in addition to those provided by Exception::Class::Base. These can be
used to output detailed output in the event of an exception.

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

This module requires these other modules and libraries:

* Perl 5.6 or later
* DBI 1.28 or later (1.30 or later strongly recommended).
* Exception::Class 1.02 or later (1.05 or later strongly recommended).
* Test::Simple 0.40 (for testing).

Copyright and Licence
---------------------

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

