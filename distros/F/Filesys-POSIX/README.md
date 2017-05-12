# NAME

Filesys::POSIX - Provide POSIX-like filesystem semantics in pure Perl

# SYNOPSIS

    use Filesys::POSIX
    use Filesys::POSIX::Mem;

    my $fs = Filesys::POSIX->new(Filesys::POSIX::Mem->new,
        'noatime' => 1
    );

    $fs->umask(0700);
    $fs->mkdir('foo');

    my $fd = $fs->open('/foo/bar', $O_CREAT | $O_WRONLY);
    my $inode = $fs->fstat($fd);
    $fs->printf("I have mode 0%o\n", $inode->{'mode'});
    $fs->close($fd);

# DESCRIPTION

Filesys::POSIX provides a fairly complete suite of tools comprising the
semantics of a POSIX filesystem, with path resolution, mount points, inodes,
a VFS, and some common utilities found in the userland.  Some features not
found in a normal POSIX environment include the ability to perform cross-
mountpoint hard links (aliasing), mapping portions of the real filesystem into
an instance of a virtual filesystem, and allowing the developer to attach and
replace inodes at arbitrary points with replacements of their own
specification.

Two filesystem types are provided out-of-the-box: A filesystem that lives in
memory completely, and a filesystem that provides a "portal" to any given
portion of the real underlying filesystem.

By and large, the manner in which data is structured is quite similar to a
real kernel filesystem implementation, with some differences: VFS inodes are
not created for EVERY disk inode (only mount points); inodes are not referred
to numerically, but rather by Perl reference; and, directory entries can be
implemented in a device-specific manner, as long as they adhere to the normal
interface specified within.

# INSTANTIATING THE FILESYSTEM ENVIRONMENT

- `Filesys::POSIX->new($rootfs, %opts)`

    Create a new filesystem environment, specifying a reference to an
    uninitialized instance of a filesystem type object to be mounted at the root
    of the virtual filesystem.  Options passed will be passed to the filesystem
    initialization method `$rootfs->init()` in flat hash form, and passed on
    again to the VFS, where the options will be stored for later retrieval.

# ERROR HANDLING

Errors are emitted in the form of exceptions thrown by
[`Carp::confess()`](https://metacpan.org/pod/Carp#confess), with full stack traces.  Where possible,
[`$!`](https://metacpan.org/pod/perlvar#pod) is set with an appropriate error code from [Errno](https://metacpan.org/pod/Errno), and a
stringified [`$!`](https://metacpan.org/pod/perlvar#pod) is thrown.

# SYSTEM CALLS

- `$fs->umask()`
- `$fs->umask($mode)`

    When called without an argument, the current umask value is returned.  When a
    value is specified, the current umask is modified to that value, and is
    returned once set.

- `$fs->stat($path)`

    Resolve the given path for an inode in the filesystem.  If the inode found is
    a symlink, the path of that symlink will be resolved in turn until the desired
    inode is located.

    Paths will be resolved relative to the current working directory when not
    prefixed with a slash ('`/`'), and will be resolved relative to the root
    directory when prefixed with a slash ('`/`').

- `$fs->lstat($path)`

    Resolve the given path for an inode in the filesystem.  Unlinke
    `$fs->stat()`, the inode found will be returned literally in the case of a
    symlink.

- `$fs->fstat($fd)`

    Return the inode corresponding to the open file descriptor passed.  An
    exception will be thrown by the file descriptor lookup module if the file
    descriptor passed does not correspond to an open file.

- `$fs->chdir($path)`

    Change the current working directory to the path specified.  An
    `$fs->stat()` call will be used internally to lookup the inode for that
    path; an ENOTDIR will be thrown unless the inode found is a directory.  The
    internal current working directory pointer will be updated with the directory
    inode found; this same inode will also be returned.

- `$fs->fchdir($fd)`

    When passed a file descriptor for a directory, update the internal pointer to
    the current working directory to that directory resolved from the file
    descriptor table, and return the same directory inode.  If the inode is not a
    directory, an ENOTDIR will be thrown.

- `$fs->chown($path, $uid, $gid)`

    Using `$fs->stat()` to locate the inode of the path specified, update that
    inode object's 'uid' and 'gid' fields with the values specified.  The inode of
    the file modified will be returned.

- `$fs->fchown($fd, $uid, $gid)`

    Using `$fs->fstat()` to locate the inode of the file descriptor specified,
    update that inode object's 'uid' and 'gid' fields with the values specified.  A
    reference to the affected inode will be returned.

- `$fs->chmod($path, $mode)`

    Using `$fs->stat()` to locate the inode of the path specified, update that
    inode object's 'mode' field with the value specified.  A reference to the
    affected inode will be returned.

- `$fs->fchmod($fd, $mode)`

    Using `$fs->fstat()` to locate the inode of the file descriptor specified,
    update that inode object's 'mode' field with the value specified.  A reference
    to that inode will be returned.

- `$fs->mkdir($path)`
- `$fs->mkdir($path, $mode)`

    Create a new directory at the path specified, applying the permissions field in
    the mode value specified.  If no mode is specified, the default permissions of
    _0777_ will be modified by the current umask value.  An ENOTDIR exception will
    be thrown in case the intended parent of the directory to be created is not
    actually a directory itself.

    A reference to the newly-created directory inode will be returned.

- `$fs->link($src, $dest)`

    Using `$fs->stat()` to resolve the path of the link source, and the parent
    of the link destination, `$fs->link()` place a reference to the source
    inode in the location specified by the destination.

    If a destination inode already exists, it will only be able to be replaced by
    the source if both are either directories or non-directories.  If the source
    and destination are both directories, the destination will only be replaced if
    the directory entry for the destination is empty.

    Links traversing filesystem mount points are not allowed.  This functionality
    is provided in the `alias()` call provided by the [Filesys::POSIX::Extensions](https://metacpan.org/pod/Filesys::POSIX::Extensions)
    module.  Upon success, a reference to the inode for which a new link is to be
    created will be returned.

    Exceptions thrown:

    - EXDEV (Cross-device link)

        The inode resolved for the link source is not associated with the same device
        as the inode of the destination's parent directory.

    - EISDIR (Is a directory)

        Thrown if the source inode is a directory.  Hard links can only be made for
        non-directory inodes.

    - EEXIST (File exists)

        Thrown if an entry at the destination path already exists.

- `$fs->symlink($old, $new)`

    The path in the first argument specified, `$old`, is cleaned up using
    `Filesys::POSIX::Path->full`, and stored in a new symlink inode created
    in the location specified by `$new`.  An EEXIST exception will be thrown if an
    inode at the path indicated by `$new` exists.  A reference to the newly-created
    symlink inode will be returned.

- `$fs->readlink($path)`

    Using `$fs->lstat()` to resolve the given path for an inode, the symlink
    destination path associated with the inode is returned as a string.  An EINVAL
    exception is thrown unless the inode found is indeed a symlink.

- `$fs->unlink($path)`

    Using `$fs->lstat()` to resolve the given path for an inode specified,
    said inode will be removed from its parent directory entry.  The following
    exceptions will be thrown in the event of certain errors:

    - ENOENT (No such file or directory)

        No entry was found in the path's parent directory for the item specified in the
        path.

    - EISDIR (Is a directory)

        `$fs->unlink()` was called with a directory specified.
        `$fs->rmdir()` must be used instead for removing directory inodes.

    Upon success, a reference to the inode removed from its parent directory will
    be returned.

- `$fs->rename($old, $new)`

    Relocate the item specified by the `$old` argument to the new path specified by
    $new.

    Using `$fs->lstat`, the inode for the old pathname is resolved;
    `$fs->stat` is then used to resolve the path of the parent directory of
    the argument specified in `$new`.

    If an inode exists at the path specified by `$new`, it will be replaced by
    `$old` in the following circumstances:

    - Both the source `$old` and destination `$new` are non-directory inodes.
    - Both the source `$old` and destination `$new` are directory inodes, and
    the destination is empty.

    The following exceptions are thrown for error conditions:

    - EPERM (Operation not permitted)

        Currently, `$fs->rename()` cannot operate if the inode at the old location
        is an inode associated with a Filesys::POSIX::Real filesystem type.

    - EXDEV (Cross-device link)

        The inode at the old path does not exist on the same filesystem device as the
        inode of the parent directory specified in the new path.

    - ENOTDIR (Not a directory)

        The old inode is a directory, but an existing inode found in the new path
        specified, is not.

    - EISDIR (Is a directory)

        The old inode is not a directory, but an existing inode found in the new path
        specified, is.

    - ENOTEMPTY (Directory not empty)

        Both the old and new paths correspond to a directory, but the new path is not
        of an empty directory.

    Upon success, a reference to the inode to be renamed will be returned.

- `$fs->rmdir($path)`

    Unlinks the directory inode at the specified path.  Exceptions are thrown in
    the following conditions:

    - ENOENT (No such file or directory)

        No inode exists by the name specified in the final component of the path in
        the parent directory specified in the path.

    - EBUSY (Device or resource busy)

        The directory specified is an active mount point.

    - ENOTDIR (Not a directory)

        The inode found at `$path` is not a directory.

    - ENOTEMPTY (Directory not empty)

        The directory is not empty.

    Upon success, a reference to the inode of the directory to be removed will be
    returned.

- `$fs->mknod($path, $mode)`
- `$fs->mknod($path, $mode, $dev)`

    Create a new inode at the specified `$path`, with the inode permissions and
    format specified in the `$mode` argument.  If `$mode` specifies a `$S_IFCHR`
    or `$S_IFBLK` value, then the device number specified in `$dev` will be given
    to the new inode.

    Code contained within the `Filesys::POSIX` distribution assumes that the device
    identifier shall contain the major and minor numbers in separate 16-bit fields,
    in the following manner:

        my $major = ($dev & 0xffff0000) >> 16;
        my $minor =  $dev & 0x0000ffff;

    Returns a reference to a [Filesys::POSIX::Inode](https://metacpan.org/pod/Filesys::POSIX::Inode) object upon success.

- `$fs->mkfifo($path, $mode)`

    Create a new FIFO device at the specified `$path`, with the permissions listed
    in `$mode`.  Internally, this function is a frontend to
    `Filesys::POSIX->mknod`.

    Returns a reference to a [Filesys::POSIX::Inode](https://metacpan.org/pod/Filesys::POSIX::Inode) object upon success.

# EXTENSION MODULES

- [Filesys::POSIX::Extensions](https://metacpan.org/pod/Filesys::POSIX::Extensions)

    This module provides a variety of functions for performing inode operations in
    novel ways that take advantage of the unique characteristics and features of
    Filesys::POSIX.  For example, one method is provided that allows a developer to
    map a file or directory from the system's underlying, actual filesystem, into
    any arbitrary point in the virtual filesystem.

- [Filesys::POSIX::Userland::Find](https://metacpan.org/pod/Filesys::POSIX::Userland::Find)

    Provides the ability to perform breadth-first operations on file hierarchies
    within an instance of a `Filesys::POSIX` filesystem, in a subset of the
    functionality provided in [File::Find](https://metacpan.org/pod/File::Find).

- [Filesys::POSIX::Userland::Tar](https://metacpan.org/pod/Filesys::POSIX::Userland::Tar)

    Provides an implementation of the POSIX ustar and certain aspects of the GNU tar
    standard.  Currently allows for the creation of tar archives based on
    hierarchies within a `Filesys::POSIX` instance.

- [Filesys::POSIX::Userland::Test](https://metacpan.org/pod/Filesys::POSIX::Userland::Test)

    Provides a series of truth tests that can be performed on files and directories
    specified by paths.

# UTILITIES

- [Filesys::POSIX::Path](https://metacpan.org/pod/Filesys::POSIX::Path)

    A publicly-accessible interface for the path name string manipulation functions
    used by Filesys::POSIX itself.

# INTERFACES

- [Filesys::POSIX::Directory](https://metacpan.org/pod/Filesys::POSIX::Directory)

    Lists the requirements for writing modules that act as directory structures.

- [Filesys::POSIX::Inode](https://metacpan.org/pod/Filesys::POSIX::Inode)

    Lists the requirements for writing modules that act as inodes.

- [Filesys::POSIX::Module](https://metacpan.org/pod/Filesys::POSIX::Module)

    Provides an interface for loading methods from modules that extend
    Filesys::POSIX.

# INTERNALS

- [Filesys::POSIX::Bits](https://metacpan.org/pod/Filesys::POSIX::Bits)

    A listing of bitfields and constants used in various places by Filesys::POSIX.

- [Filesys::POSIX::FdTable](https://metacpan.org/pod/Filesys::POSIX::FdTable)

    The Filesys::POSIX implementation of the file descriptor allocation table.

- [Filesys::POSIX::Userland](https://metacpan.org/pod/Filesys::POSIX::Userland)

    Imported by Filesys::POSIX by default.  Provides many POSIX command line
    tool-like functions not documented in the current manual page.

- [Filesys::POSIX::IO](https://metacpan.org/pod/Filesys::POSIX::IO)

    Imported by Filesys::POSIX by default.  Provides standard file manipulation
    routines as found in a POSIX filesystem.

- [Filesys::POSIX::Mount](https://metacpan.org/pod/Filesys::POSIX::Mount)

    Imported by Filesys::POSIX by default.  Provides a frontend to the VFS mount
    point management implementation found in [Filesys::POSIX::VFS](https://metacpan.org/pod/Filesys::POSIX::VFS).

- [Filesys::POSIX::VFS](https://metacpan.org/pod/Filesys::POSIX::VFS)

    Used by Filesys::POSIX, this module provides an implementation of a filesystem
    mount table and VFS inode resolution routines.

# AUTHOR

Written by Xan Tronix <xan@cpan.org>

# CONTRIBUTORS

- Rikus Goodell <rikus.goodell@cpanel.net>
- Brian Carlson <brian.carlson@cpanel.net>

# COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
