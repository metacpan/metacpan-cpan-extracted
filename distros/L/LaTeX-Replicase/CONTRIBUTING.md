# Contributing Guidelines

This file describes requirements and procedures for developing and testing the
LaTeX::Replicase Perl module from its code repository.  For instructions installing
from CPAN or tarball, see the [README](README) file instead.

## Introduction

LaTeX::Replicase - Perl extension implementing a minimalistic engine
for filling real TeX-LaTeX files that act as templates.

## How to Contribute

The code for `LaTeX::Replicase` is hosted on GitHub at:

    https://github.com/AlessandroGorohovski/LaTeX-Replicase

and CPAN at:

    https://metacpan.org/pod/LaTeX::Replicase

If you would like to contribute code, documentation, tests, or bugfixes, etc. --
I prefer to get patches. Please email me first, so we can discuss it, 
and I can tag it as being worked on.

These are mostly guidelines, not rules. 
Use your best judgment, and feel free to propose changes to this document in a pull request.

## Compiler tool requirements

This module requires `make`.

For example, Debian and Ubuntu users should issue the following command:

    $ sudo apt-get install build-essential

Users of Red Hat based distributions (RHEL, CentOS, Amazon Linux, Oracle
Linux, Fedora, etc.) should issue the following command:

    $ sudo yum install make

On Windows, [StrawberryPerl](http://strawberryperl.com/) ships with a
GCC compiler.

On Mac, install XCode or just the [XCode command line
tools](https://developer.apple.com/library/ios/technotes/tn2339/_index.html).

## Configuration and dependencies

You will need to install Config::AutoConf and Path::Tiny to be able to run
the Makefile.PL.

    $ cpan Config::AutoConf Path::Tiny

To configure:

    $ perl Makefile.PL

The output will highlight any missing dependencies.  Install those with the
`cpan` client.

    $ cpan [list of dependencies]

## Building and testing

To build and test (after configuration):

    $ make
    $ make test
    $ sudo make install

Thank you for your contribution!
