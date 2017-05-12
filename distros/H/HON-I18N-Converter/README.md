HON-I18N-Converter
==================

[![Build Status](https://travis-ci.org/healthonnet/HON-I18N-Converter.svg?branch=master)](https://travis-ci.org/healthonnet/HON-I18N-Converter)
[![Coverage Status](https://coveralls.io/repos/healthonnet/HON-I18N-Converter/badge.svg?branch=master)](https://coveralls.io/r/healthonnet/HON-I18N-Converter?branch=master)

Perl i18n Converter

Usage
-----

Convert an Excel (2003) file to another format

```perl
use HON::I18N::Converter;

my $converter = HON::I18N::Converter->new( excel => 'path/to/my/file.xls' );
$converter->build_properties_file('INI', 'destination/folder/', $comment);
...
$converter->build_properties_file('JS', 'destination/folder/', $comment);
```

Via the command-line program

```
./build-properties-JS-file.pl --i18n=path/to/my/file.xls --output=/tmp/js

./build-properties-INI-file.pl --i18n=path/to/my/file.xls --output=/tmp/ini
```

Installation
------------

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install
  
Support and documentation
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc HON::I18N::Converter

You can also look for information at:

* RT, CPAN's request tracker (report bugs here)
  http://rt.cpan.org/NoAuth/Bugs.html?Dist=HON-I18N-Converter

* AnnoCPAN, Annotated CPAN documentation
  http://annocpan.org/dist/HON-I18N-Converter

* CPAN Ratings
  http://cpanratings.perl.org/d/HON-I18N-Converter

* Search CPAN
  http://search.cpan.org/dist/HON-I18N-Converter/

Author
------
 * [Samia Chahlal](https://github.com/samiachahlal)
 
Maintainer
----------
 * [William Belle](https://github.com/williambelle)

License and Copyright
---------------------

Copyright (C) 2013 Samia Chahlal

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.