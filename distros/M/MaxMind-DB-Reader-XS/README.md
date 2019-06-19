# NAME

MaxMind::DB::Reader::XS - Fast XS implementation of MaxMind DB reader

# VERSION

version 1.000008

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

# UBUNTU SUPPORT

The version of libmaxminddb that is available by default with Ubuntu may be
too old for this level of MaxMind::DB::Reader::XS.  However, we do maintain a
Launchpad PPA for all supported levels of Ubuntu.

    https://launchpad.net/~maxmind/+archive/ubuntu/ppa

Please visit the PPA page for more information, or, to configure your system,
run as root:

    # apt-add-repository ppa:maxmind/ppa
    # apt-get update

The PPA is now configured, and you may install (or upgrade) the libmaxminddb
library via the usual apt commands.

# SUPPORT

This module is deprecated and will only receive fixes for major bugs and
security vulnerabilities. New features and functionality will not be added.

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/MaxMind-DB-Reader-XS/issues](https://github.com/maxmind/MaxMind-DB-Reader-XS/issues).

Bugs may be submitted through [https://github.com/maxmind/MaxMind-DB-Reader-XS/issues](https://github.com/maxmind/MaxMind-DB-Reader-XS/issues).

# AUTHORS

- Boris Zentner <bzentner@maxmind.com>
- Dave Rolsky <drolsky@maxmind.com>
- Ran Eilam <reilam@maxmind.com>

# CONTRIBUTORS

- Andy Jack <github@veracity.ca>
- Chris Weyl <cweyl@alumni.drew.edu>
- Florian Ragwitz <rafl@debian.org>
- Greg Oschwald <goschwald@maxmind.com>
- Hidenori Sugiyama <madogiwa@gmail.com>
- Mark Fowler <mark@twoshortplanks.com>
- Olaf Alders <oalders@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2019 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
