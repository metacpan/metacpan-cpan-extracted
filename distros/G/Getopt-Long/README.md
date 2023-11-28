# Getopt::Long

*Perl module for Extended processing of command line options*

![Version](https://img.shields.io/github/v/release/sciurius/perl-Getopt-Long)
![GitHub issues](https://img.shields.io/github/issues/sciurius/perl-Getopt-Long)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)

## Introduction

Module Getopt::Long implements an extended getopt function called
GetOptions(). This function implements the POSIX standard for command
line options, with GNU extensions, while still capable of handling
the traditional one-letter options.
In general, this means that command line options can have long names
instead of single letters, and are introduced with a double dash `--`.

Optionally, Getopt::Long can support the traditional bundling of
single-letter command line options.

Getopt::Long is part of the Perl 5 distribution. It is the successor
of newgetopt.pl that came with Perl 4. It is fully upward compatible.
In fact, the Perl 5 version of newgetopt.pl is just a wrapper around
the module.

For complete documentation, see
[MetaCPAN](https://metacpan.org/release/Getopt-Long)
or use the command

    perldoc Getopt::Long

## Features

### Long option names

Major advantage of using long option names is that it is much easier
to memorize the option names. Using single-letter names one quickly
runs into the problem that there is no logical relationship between
the semantics of the selected option and its option letter.
Disadvantage is that it requires more typing. Getopt::Long provides
for option name abbreviation, so option names may be abbreviated to
uniqueness. Also, modern shells like Cornell's tcsh support option
name completion. As a rule of thumb, you can use abbreviations freely
while running commands interactively but always use the full names in
scripts. 

Examples (POSIX):

`--long`  
`--width=80`  
`--height=24`

Extensions:

`-long` (*convenience*)  
`+width=80` (*deprecated*)  
`-height 24` (*traditional*)

By default, long option names are case insensitive.

### Single-letter options and bundling

When single-letter options are requested, Getopt::Long allows the
option names to be bundled, e.g. `-abc` is equivalent to `-a -b -c`.
In this case, long option names must be introduced with the POSIX `--`
introducer.

Examples:

`-lgAd` (*bundle*)  
`-xw 80` (*bundle, w takes a value*)  
`-xw80` (*same*)  
`-l24w80` (*l = 24 and w = 80*)

By default, single-letter option names are case sensitive.

### Flexibility:

  - Options can have alternative names, using an alternative name
    will behave as if the primary name was used.
  - Options can be negatable, e.g. `--debug` will switch it on, while
    `--no-debug` will switch it off.  
  - Options can set values, but also add values producing an array
    of values instead of a single scalar value, or set values in a hash.
  - Options can have multiple values, e.g., `--position 25 624`.

### Options linkage

Using Getopt::Long gives the programmer ultimate control over the
command line options and how they must be handled:

  - By setting a global variable in the calling program.
  - By setting a specified variable.
  - By entering the option name and the value in an associative array
    (hash) or object (if it is a blessed hash).
  - By calling a user-specified subroutine with the option name and
    the value as arguments (for hash options: the name, key and value);
  - Combinations of the above.

### Customization:

The module can be customized by specifying settings in the `use`
directive, or by calling a special method, Getopt::Long::Configure.
For example, the following two cases are functionally equal:

    use Getopt::Long qw(:config bundling no_ignore_case);

and

    use Getopt::Long;
    Getopt::Long::Configure qw(bundling no_ignore_case);

See the documentation for all possibilities.

### Object oriented interface:

Using the object oriented interface, multiple parser objects can be
instantiated, each having their own configuration settings:

    use Getopt::Long::Parser;
    $p1 = Getopt::Long::Parser->new(config => ["bundling"]);
    $p2 = Getopt::Long::Parser->new(config => ["posix"]);
    if ($p1->getoptions(...options descriptions...)) ...

## Installation

The official version for module Getopt::Long comes pre-installed with the Perl 5
distribution. 
Newer versions will be made available on the Comprehensive Perl Archive
Network (CPAN), see
[MetaCPAN](https://metacpan.org/release/Getopt-Long).

### Install directly from CPAN

Use the `cpan` or `cpanm` tools:

    cpan Getopt::Long

### Install from a (downloaded) CPAN kit

Unpack the kit and `cd` into the unpacked directory. Issue the
following commands:

    perl Makefile.PL
    make all test
    make install

### Install from the (cloned) repository

`cd` into the checked out repository and issue the following commands:

    perl Makefile.PL
    make all test
    make install

### Examples

The kit contains an `examples` directory with some program skeleton
files that can be used to start writing application programs. It uses
Getopt::Long in a standard way, automatically providing version and
help information. For the latter, it uses the Pod::Usage module to
extracts help texts from the embedded documentation.

The `examples` directory and the skeleton files are **not** installed.

## Development

Getopt::Long is a standard Perl5 (core) module, but maintained
separately.

Development is hosted on Github, 
https://github.com/sciurius/perl-Getopt-Long .
Please use the Github bug tracker
https://github.com/sciurius/perl-Getopt-Long/issues
to report issues.

Note that this source tree contains a Makefile.PL (for Perl) and a
GNUmakefile (for development).

Relevant targets of the GNUmakefile are

* `test` : runs the standard tests

* `regtest` : runs the extended regression tests

* `dist` : creates a new tar.gz distribution

A Github release is a snapshot of this repository. An
official CPAN release must be made with the `dist` target of the
GNUmakefile.

## Copyright and Disclaimer

Perl module Getopt::Long is Copyright 1990,2013,2023 by Johan Vromans.
This program is free software; you can redistribute it and/or
modify it under the terms of the Perl Artistic License or the
GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any
later version.
