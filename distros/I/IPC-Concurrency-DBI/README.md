IPC-Concurrency-DBI
===================

[![Build Status](https://travis-ci.org/guillaumeaubert/IPC-Concurrency-DBI.svg?branch=master)](https://travis-ci.org/guillaumeaubert/IPC-Concurrency-DBI)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/IPC-Concurrency-DBI/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/IPC-Concurrency-DBI?branch=master)
[![CPAN](https://img.shields.io/cpan/v/IPC-Concurrency-DBI.svg)](https://metacpan.org/release/IPC-Concurrency-DBI)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

IPC::Concurrency::DBI controls how many instances of a given application are
allowed to run in parallel, using DBI as the IPC method.


INSTALLATION
------------

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install


SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

	perldoc IPC::Concurrency::DBI


You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
   (https://github.com/guillaumeaubert/IPC-Concurrency-DBI/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/IPC-Concurrency-DBI)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/IPC-Concurrency-DBI)

 * [MetaCPAN]
   (https://metacpan.org/release/IPC-Concurrency-DBI)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2011-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
