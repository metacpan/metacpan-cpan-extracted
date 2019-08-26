[![Build Status](https://travis-ci.org/mtw/FileDirUtil.svg?branch=master)](https://travis-ci.org/mtw/FileDirUtil) [![Anaconda-Server Badge](https://anaconda.org/bioconda/perl-filedirutil/badges/installer/conda.svg)](https://conda.anaconda.org/bioconda)  [![Anaconda-Server Badge](https://anaconda.org/bioconda/perl-filedirutil/badges/version.svg)](https://anaconda.org/bioconda/perl-filedirutil)

# FileDirUtil version 0.04

FileDirUtil is a convenience Moose Role for basic File IO, providing
transparent access to Path::Class::File and Path::Class::Dir for
input files and output directories, respectively.

## INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## DEPENDENCIES

This module requires these other modules and libraries:

* Moose::Role
* Moose::Util::TypeConstraints
* Path::Class::File
* Path::Class::Dir
* Params::Coerce
* File::Basename
* namespace::autoclean

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc FileDirUtil

You can also look for information at:

    metaCPAN
      https://metacpan.org/pod/FileDirUtil

## COPYRIGHT AND LICENCE

Copyright (C) 2017-2019 Michael T. Wolfinger

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
L<http://www.gnu.org/licenses/>.
