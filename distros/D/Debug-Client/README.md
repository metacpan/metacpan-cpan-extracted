Debug::Client
[![Build Status](https://travis-ci.org/PadreIDE/Debug-Client.png?branch=master)](https://travis-ci.org/PadreIDE/Debug-Client)
[![Build status](https://ci.appveyor.com/api/projects/status/nkr4afuq1gk87b1x?svg=true)](https://ci.appveyor.com/project/szabgab/debug-client)
==========

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the README
file from a module distribution so that people browsing the archive
can use it to get an idea of the module's uses. It is usually a good idea
to provide version information here so that people can decide whether
fixes for the module are worth downloading.

## RELEASE

Install prerequisites:

    cpanm --installdeps .

Install release dependencies:

    cpanm install Test::Pod Test::Pod::Coverage

In order to release a new version of this project

    Update the version number in lib/Debug/Client.pm
    Update the Changes file

    perl Makefile.PL
    make
    RELEASE_TESTING=1 make test
    make manifest
    make dist

Tag the version in git with the appropriate version number:

    git -a v0.32 -m v0.32
    git push --tags


## INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

On Ubuntu you might need to install cpanm Term::ReadLine::Gnu manually:

    sudo apt install libreadline-dev
    cpanm Term::ReadLine::Gnu

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Debug::Client

You can also look for information at MetaCPAN https://metacpan.org/pod/Debug::Client


## LICENSE AND COPYRIGHT

Copyright (C) 2008-2021 Gabor Szabo

Some parts copyright (C) 2011-2014 Kevin Dawson


This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
