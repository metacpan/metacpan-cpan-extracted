# NAME

File::Rotate::Simple - no-frills file rotation

# SYNOPSIS

```perl
use File::Rotate::Simple qw/ rotate_files /;

rotate_files(
    file => '/foo/bar/backup.tar.gz',
    age  => 7,
    max  => 30,
);

rotate_files(
    files => [ qw{ /var/log/foo.log /var/log/bar.log } ],
    max   => 7,
);
```

or the legacy interface:

```perl
File::Rotate::Simple->rotate(
    file => '/foo/bar/backup.tar.gz',
    age  => 7,
    max  => 30,
);
```

or the object-oriented interface:

```perl
my $r = File::Rotate::Simple->new(
    file => '/foo/bar/backup.tar.gz',
    age  => 7,
    max  => 30,
);

$r->rotate;
```

# DESCRIPTION

This module implements simple file rotation.

Files are renamed to have a numeric suffix, e.g. `backup.tar.gz` is renamed to
`backup.tar.gz.1`.  Existing file numbers are incremented.

If ["max"](#max) is specified, then any files with a larger numeric suffix
are deleted.

If ["age"](#age) is specified, then any files older than that number of days
are deleted.

Note that files with the extension `0` are ignored.

# RECENT CHANGES

Changes for version v0.4.1 (2026-08-07)

- Bug Fixs
    - Fixed bug when older rotated files are dangling symlinks.
    - Fixed bug when rotating dandling symlinks and age > 0.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Exporter](https://metacpan.org/pod/Exporter)
- [Graph](https://metacpan.org/pod/Graph)
- [List::Util](https://metacpan.org/pod/List%3A%3AUtil) version 1.43 or later
- [Module::Runtime](https://metacpan.org/pod/Module%3A%3ARuntime)
- [Moo](https://metacpan.org/pod/Moo) version 1.001000 or later
- [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) version 0.018 or later
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [Time::Seconds](https://metacpan.org/pod/Time%3A%3ASeconds)
- [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.14.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan File::Rotate::Simple
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/File-Rotate-Simple/issues](https://github.com/robrwo/File-Rotate-Simple/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# SOURCE

The development version is on github at [https://github.com/robrwo/File-Rotate-Simple](https://github.com/robrwo/File-Rotate-Simple)
and may be cloned from [https://github.com/robrwo/File-Rotate-Simple.git](https://github.com/robrwo/File-Rotate-Simple.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# CONTRIBUTOR

Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

The following modules have similar functionality:

- [File::Rotate::Backup](https://metacpan.org/pod/File%3A%3ARotate%3A%3ABackup)
- [File::Write::Rotate](https://metacpan.org/pod/File%3A%3AWrite%3A%3ARotate)

There are also several logging modules that support log rotation.
