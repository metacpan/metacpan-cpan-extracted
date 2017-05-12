HON-Deploy
==========

[![Build Status](https://travis-ci.org/healthonnet/HON-Deploy.svg?branch=master)](https://travis-ci.org/healthonnet/HON-Deploy)

Deploy perl module + bin + cgi.

Installation
------------

To install this module, run

```bash
cpanm HON::Deploy
```

or from source with the following commands:

```bash
perl Build.PL
./Build
./Build test
./Build install
```

Usage
-----

```bash
hon-deploy-perl-distrib.pl --help

hon-deploy-perl-distrib.pl --dist=path/to/HON-Deploy.tar.gz --dir-base=/path/to/base

hon-deploy-perl-distrib.pl --dist=http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Deploy.tar.gz --dir-base=/path/to/base

hon-deploy-perl-distrib.pl --dist=http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Utils-latest.tar.gz,http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Http-Mirror-latest.tar.gz --dir-base=$HOME/perl --dir-cgi=$HOME/public_html/cgi-bin --perl-interpreter=$(which perl)
```


Support and documentation
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc HON::Deploy

You can also look for information at:

* RT, CPAN's request tracker (report bugs here)
  http://rt.cpan.org/NoAuth/Bugs.html?Dist=HON-Deploy

* AnnoCPAN, Annotated CPAN documentation
  http://annocpan.org/dist/HON-Deploy

* CPAN Ratings
  http://cpanratings.perl.org/d/HON-Deploy

*  Search CPAN
   http://search.cpan.org/dist/HON-Deploy/

Author
------
 * [Alexandre Masselot](https://github.com/alexmasselot)
 
Maintainer
----------
 * [William Belle](https://github.com/williambelle)

License
-------

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

