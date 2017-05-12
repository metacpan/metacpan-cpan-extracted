HON-EC2-Snapshots-Monitoring
============================

[![Build Status](https://travis-ci.org/healthonnet/hon-ec2-snapshots-monitoring.svg?branch=master)](https://travis-ci.org/healthonnet/hon-ec2-snapshots-monitoring)
[![Coverage Status](https://coveralls.io/repos/healthonnet/hon-ec2-snapshots-monitoring/badge.svg?branch=master&service=github)](https://coveralls.io/github/healthonnet/hon-ec2-snapshots-monitoring?branch=master)

Log file monitoring

Usage
-----

```bash
$ hon-ec2-snapshots-monitoring.pl --help
$ hon-ec2-snapshots-monitoring.pl --log=/path/to/file.log
```

Installation
------------

Via CPAN with :

```bash
$ cpan install HON::EC2::Snapshots::Monitoring
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
perldoc HON::EC2::Snapshots::Monitoring
```

You can also look for information at:

  * RT, CPAN's request tracker (report bugs here)
    http://rt.cpan.org/NoAuth/Bugs.html?Dist=HON-EC2-Snapshots-Monitoring

  * AnnoCPAN, Annotated CPAN documentation
    http://annocpan.org/dist/HON-EC2-Snapshots-Monitoring

  * CPAN Ratings
    http://cpanratings.perl.org/d/HON-EC2-Snapshots-Monitoring

  * Search CPAN
    http://search.cpan.org/dist/HON-EC2-Snapshots-Monitoring/


License
-------

Copyright (C) 2015 William Belle

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

See the LICENSE file.
