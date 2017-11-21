
## Finance::YahooQuote [![Build Status](https://travis-ci.org/eddelbuettel/finance-yahooquote.svg)](https://travis-ci.org/eddelbuettel/finance-yahooquote) [![License](http://img.shields.io/badge/license-GPL%20%28%3E=%202%29-brightgreen.svg?style=flat)](http://www.gnu.org/licenses/gpl-2.0.html)

Finance::YahooQuote is a Perl 5 module that will pull one or more stock quotes from
[Yahoo! Finance](http://finance.yahoo.com). It was written by 
[Dj Padzensky](https://www.padz.net/wp/), and is now maintained by 
[Dirk Eddelbuettel](http://dirk.eddelbuettel.com).  See the files 
CHANGES.old for DJ's log of changes, and ChangeLog for changes since Dirk took over.

### Yahoo! Status

*Important Note:* As of November 2017, Yahoo! no longer support this interface, so
the module ceases to be of any use or value.  An epic 20-year run has come to
an end. Consider this repo to be of historic value only.

### CPAN

The package is also available from [CPAN](http://www.cpan.org) via 
[this page](http://search.cpan.org/~edd/Finance-YahooQuote/YahooQuote.pm).

### Source Installation 

Once the archive has been unpacked, the following steps are needed
to build and install the module (to be done in the directory which
contains the Makefile.PL)

```{.sh}
perl Makefile.PL
make
```

A few simple tests are provided. Please note that the second test
may fail if your internet connection is down, requires a proxy or if
Yahoo! is down. That said,

```{.sh}
make test
```

can be used to test the integrity of the module prior to installation.

If the build and test succeed, install it with the following command:

```{.sh}
make install
```

An example script is installed as `yahooquote`. Two more example scripts
are include to help examine available services at different Yahoo! servers,
and to examine the possible mapping between stock symbols for a given
company. 

### Binary Installation

For [Debian](http://www.debian.org) and derivatives such as [Ubuntu](http://www.ubuntu.com), 
a package is available via

```{.sh}
sudo apt-get install libfinance-yahooquote-perl
```

For Windows users, ActiveState does maintain a pre-build package that can be
installed with their ppm tool

### Status

The package is in maintenance mode.  Bugs are being fixed, but additions of new functionality
are unlikely.

### License

GPL (>= 2)

### Authors

DJ Padzensky and Dirk Eddelbuettel

### Maintainer

Dirk Eddelbuettel
