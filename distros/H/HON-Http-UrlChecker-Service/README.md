HON-Http-UrlChecker-Service
===========================

[![Build Status](https://travis-ci.org/healthonnet/hon-http-urlchecker-service.svg?branch=master)](https://travis-ci.org/healthonnet/hon-http-urlchecker-service)
[![Coverage Status](https://coveralls.io/repos/github/healthonnet/hon-http-urlchecker-service/badge.svg?branch=master)](https://coveralls.io/github/healthonnet/hon-http-urlchecker-service?branch=master)

Check status code, response headers, redirect location and redirect chain
of a HTTP connection.

Usage
-----

```perl
use HON::Http::UrlChecker::Service qw/checkUrl/;

my @listOfStatus = checkUrl('http://www.example.com');
```

Installation
------------

Via CPAN with :

```bash
$ cpan install HON::Http::UrlChecker::Service
```

or download this module and run the following commands:

```bash
$ perl Build.PL
$ ./Build
$ ./Build test
$ ./Build install
```

Support and documentation
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

```bash
perldoc HON::Http::UrlChecker::Service
```

You can also look for information at:

  * RT, CPAN's request tracker (report bugs here)
    http://rt.cpan.org/NoAuth/Bugs.html?Dist=HON-Http-UrlChecker-Service

  * AnnoCPAN, Annotated CPAN documentation
    http://annocpan.org/dist/HON-Http-UrlChecker-Service

  * CPAN Ratings http://cpanratings.perl.org/d/HON-Http-UrlChecker-Service

  * Search CPAN http://search.cpan.org/dist/HON-Http-UrlChecker-Service/


License
-------

Copyright (C) 2016 William Belle

This program is distributed under the MIT (X11) License: http://www.opensource.org/licenses/mit-license.php
