# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [METHODS](#methods)
  * [new(distribution => NAME)](#newdistribution-=>-name)
  * [dir](#dir)
  * [path(RELATIVE)](#pathrelative)
  * [copy(SOURCE, DESTINATION, recursive => 1)](#copysource-destination-recursive-=>-1)
  * [list](#list)
* [SEE ALSO](#see-also)
* [LICENSE](#license)
* [AUTHOR](#author)
# NAME

File::DistDir - locate and copy installed Perl distribution resources

# SYNOPSIS

    use File::DistDir;

    my $dist = File::DistDir->new( distribution => 'Bedrock' );

    my $root = $dist->dir;
    my $file = $dist->path('config/tagx.xml');

    $dist->copy('config/tagx.xml', './config/tagx.xml');
    $dist->copy('config', './config', recursive => 1);
    $dist->copy('.', '.', recursive => 1);

    my @resources = $dist->list;

# DESCRIPTION

`File::DistDir` provides an object-oriented interface to the resources
installed in a distribution's share directory. Resource discovery uses
[File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir). The `dist-dir` command is provided by
[File::DistDir::CLI](https://metacpan.org/pod/File%3A%3ADistDir%3A%3ACLI) in the same distribution.

# METHODS

## new(distribution => NAME)

Create an accessor for an installed distribution. `NAME` is the
CPAN distribution name, not a Perl package name. A missing distribution
or share directory causes an exception.

## dir

Return the absolute path to the installed share directory.

## path(RELATIVE)

Resolve an existing resource path relative to the share directory.
Absolute source paths and paths resolving outside the share directory
are rejected. This method does not copy anything.

## copy(SOURCE, DESTINATION, recursive => 1)

Copy a resource. For a file, `DESTINATION` is required. An existing
destination directory receives the source basename; otherwise the parent
of the destination filename must already exist.

For directories, specify `recursive => 1`. The **contents** of the
source directory are copied into `DESTINATION`, which is created if
necessary. For `copy('.', '.', recursive => 1)`, the destination
may be omitted. Existing files are overwritten.

Sources outside the share directory are rejected. Copies reject
symbolic links in source or destination paths, including intermediate
path components. Recursive copies also reject non-file resources; this method does not copy
file permissions or provide atomic multi-file transactions. A failed
copy may leave a partially populated destination.

Returns a true value on success; failures throw exceptions.

## list

Return a sorted list of paths relative to the share root, including
directory entries. Symlinked directories are listed but not traversed.
Paths are returned as data and are not printed.

# SEE ALSO

[File::DistDir::CLI](https://metacpan.org/pod/File%3A%3ADistDir%3A%3ACLI), [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir)

# LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See
https://dev.perl.org/licenses/ for more information.

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>
