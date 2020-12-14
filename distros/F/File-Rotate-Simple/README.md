# NAME

File::Rotate::Simple - no-frills file rotation

# VERSION

version v0.2.5

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

# ATTRIBUTES

## `age`

The maximum age of files (in days), relative to the ["time"](#time)
attribute.  Older files will be deleted.

A value `0` (default) means there is no maximum age.

## `max`

The maximum number of files to keep.  Numbered files larger than this
will be deleted.

A value of `0` (default) means that there is no maximum number.

Note that it does not track whether intermediate files are missing.

## `file`

The file to rotate. This can be a string or [Path::Tiny](https://metacpan.org/pod/Path::Tiny) object.

## `files`

When ["rotate"](#rotate) is called as a constructor, you can specify an array
reference of files to rotate:

```perl
File::Rotate::Simple->rotate(
   files => \@files,
   ...
);
```

## `start_num`

The starting number to use when rotating files. Defaults to `1`.

Added in v0.2.0.

## `extension_format`

The extension to add when rotating. This is a string that is passed to
["strftime" in Time::Piece](https://metacpan.org/pod/Time::Piece#strftime) with the following addition of the `%#` code,
which corresponds to the rotation number of the file.

Added in v0.2.0.

## `replace_extension`

If defined, it replaces the extension with the one specified by
["extension\_format"](#extension_format) rather than appending it.  Use this when you want
to preserve the existing extension in a rotated backup, e.g.

```perl
my $r = File::Rotate::Simple->new(
    file              => 'myapp.log',
    extension_format  => '.%#.log',
    replace_extension => '.log',
);
```

will rotate the log as `myapp.1.log`.

Added in v0.2.0.

## `if_missing`

When true, rotate the files even when ["file"](#file) is missing. True by
default, for backwards compatability.

Added in v0.2.0.

## `touch`

Touch ["file"](#file) after rotating.

## `time`

A time object corresponding to the time used for generating
timestamped extensions in ["extension\_format"](#extension_format).  It defaults to a
[Time::Piece](https://metacpan.org/pod/Time::Piece) object with the current local time.

You can specify an alternative time (including time zone) in the
constructor, e.g.

```perl
use Time::Piece;

my $r = File::Rotate::Simple->new(
    file              => 'myapp.log',
    time              => gmtime(),
    extension_format  => '.%Y%m%d',
);
```

[Time::Moment](https://metacpan.org/pod/Time::Moment) and [DateTime](https://metacpan.org/pod/DateTime) objects can also be given.

Unlike other attributes, ["time"](#time) is read-write, so that it can be
updated between calls to ["rotate"](#rotate):

```perl
use Time::Piece;

$r->time( localtime );
$r->rotate;
```

Added in v0.2.0.

# METHODS

## `rotate`

Rotates the files.

This can be called as a constructor.

# EXPORTS

None by default. All exports must be made manually.

## `rotate_files`

This is an optionally exported function for rotating files.

```perl
use File::Rotate::Simple qw/ rotate_files /;

rotate_files(
    file => '/foo/bar/backup.tar.gz',
    age  => 7,
    max  => 30,
);
```

Added in v0.2.0.

# SEE ALSO

The following modules have similar functionality:

- [File::Rotate::Backup](https://metacpan.org/pod/File::Rotate::Backup)
- [File::Write::Rotate](https://metacpan.org/pod/File::Write::Rotate)

There are also several logging modueles that support log rotation.

# SOURCE

The development version is on github at [https://github.com/robrwo/File-Rotate-Simple](https://github.com/robrwo/File-Rotate-Simple)
and may be cloned from [git://github.com/robrwo/File-Rotate-Simple.git](git://github.com/robrwo/File-Rotate-Simple.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/File-Rotate-Simple/issues](https://github.com/robrwo/File-Rotate-Simple/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
