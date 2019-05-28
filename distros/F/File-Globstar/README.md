[![Price](https://img.shields.io/badge/price-FREE-0098f7.svg)](https://github.com/gflohr/File-Globstar/blob/master/LICENSE)
[![Travis (.org)](https://img.shields.io/travis/gflohr/File-Globstar.svg)](https://travis-ci.org/gflohr/File-Globstar)
[![Coverage Status](https://coveralls.io/repos/github/gflohr/File-Globstar/badge.svg?branch=master)](https://coveralls.io/github/gflohr/File-Globstar?branch=master)

# File-Globstar

This library implements globbing with support for "**" in Perl.

Two consecutive asterisks stand for all files and directories in the
current directory and all of its descendants.

See [File::Globstar](https://github.com/gflohr/File-Globstar/blob/master/lib/File/Globstar.pod) for more information.

The library also contains [File::Globstar::ListMatch](https://github.com/gflohr/File-Globstar/blob/master/lib/File/Globstar/ListMatch.pod), a module that implements matching against lists of patterns in the style of [gitignore](https://git-scm.com/docs/gitignore).

## Webpages

- [CPAN](http://cpan.org/~guido/File-Globstar/)
- [Github](https://github.com/gflohr/File-Globstar/)
- [Introduction and Motivation](http://www.guido-flohr.net/globstar-for-perl/)

## Installation

Via CPAN:

```
$ perl -MCPAN -e install 'File::Globstar'
```

From source:

```
$ perl Build.PL
Created MYMETA.yml and MYMETA.json
Creating new 'Build' script for 'File-Globstar' version '0.1'
$ ./Build
$ ./Build install
```

From source with "make":

```
$ git clone https://github.com/gflohr/File-Globstar.git
$ cd File-Globstar
$ perl Makefile.PL
$ make
$ make install
```

## Usage

See [File::Globstar](lib/File/Globstar.pod) and [File::Globstar::ListMatch](lib/File/Globstar/ListMatch.pod).

## Contributing

Translate

## Bugs

Please report bugs at
[https://github.com/gflohr/File-Globstar/issues](https://github.com/gflohr/File-Globstar/issues)

## Copyright

Copyright (C) 2016-2019, Guido Flohr, <guido.flohr@cantanea.com>,
all rights reserved.
