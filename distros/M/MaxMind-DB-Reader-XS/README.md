# NAME

MaxMind::DB::Reader::XS - Fast XS implementation of MaxMind DB reader

# VERSION

version 1.000004

# SYNOPSIS

    my $reader = MaxMind::DB::Reader->new( file => 'path/to/database.mmdb' );

    my $record = $reader->record_for_address('1.2.3.4');

# DESCRIPTION

Simply installing this module causes [MaxMind::DB::Reader](https://metacpan.org/pod/MaxMind::DB::Reader) to use the XS
implementation, which is much faster than the Perl implementation.

The XS implementation links against the
[libmaxminddb](http://maxmind.github.io/libmaxminddb/) library.

See [MaxMind::DB::Reader](https://metacpan.org/pod/MaxMind::DB::Reader) for API details.

# VERSIONING POLICY

This module uses semantic versioning as described by
[http://semver.org/](http://semver.org/). Version numbers can be read as X.YYYZZZ, where X is the
major number, YYY is the minor number, and ZZZ is the patch number.

# MAC OS X SUPPORT

If you're running into install errors under Mac OS X, you may need to force a
build of the 64 bit binary. For example, if you're installing via `cpanm`:

    ARCHFLAGS="-arch x86_64" cpanm MaxMind::DB::Reader::XS

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/MaxMind-DB-Reader-XS/issues](https://github.com/maxmind/MaxMind-DB-Reader-XS/issues).

Bugs may be submitted through [https://github.com/maxmind/MaxMind-DB-Reader-XS/issues](https://github.com/maxmind/MaxMind-DB-Reader-XS/issues).

# AUTHORS

- Boris Zentner <bzentner@maxmind.com>
- Dave Rolsky <drolsky@maxmind.com>
- Ran Eilam <reilam@maxmind.com>

# CONTRIBUTORS

- Andy Jack <github@veracity.ca>
- Florian Ragwitz <rafl@debian.org>
- Greg Oschwald <goschwald@maxmind.com>
- Olaf Alders <oalders@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
