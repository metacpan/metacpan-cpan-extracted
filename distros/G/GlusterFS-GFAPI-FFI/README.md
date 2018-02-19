# libgfapi-perl [![Build Status](https://travis-ci.org/potatogim/libgfapi-perl.svg?branch=master)](https://travis-ci.org/potatogim/libgfapi-perl)

GlusterFS libgfapi binding for Perl 5

The libgfapi-perl provides declarations and linkage for the Gluster gfapi C library with FFI for many Perl mongers.

To use it, you can use test code that exists under 't/' directory for reference.

## SYNOPSIS

```perl
# make GlusterFS Volume instance
my $fs = GlusterFS::GFAPI::FFI::glfs_new('libgfapi-perl');

# set server information for a volume
if (GlusterFS::GFAPI::FFI::glfs_set_volfile_server($fs, 'tcp', 'node1', 24007))
{
    die "Failed to set volfile server: $!";
}

# initialize connection for a GlusterFS Volume
if (GlusterFS::GFAPI::FFI::glfs_init($fs))
{
    die "Failed to init connection: $!";
}

# get a Volume-ID
my $len = 16;
my $id  = "\0" x $len;

if (GlusterFS::GFAPI::FFI::glfs_get_volumeid($fs, $id, $len) < 0)
{
    die "Failed to get volume-id: $!";
}

printf "Volume-ID: %s\n", join('-', unpack('H8 H4 H4 H4 H12', $id));

# get stat for a volume
my $stat = GlusterFS::GFAPI::FFI::Statvfs->new();

if (GlusterFS::GFAPI::FFI::glfs_statvfs($fs, '/', $stat))
{
    die "Failed to get statvfs: $!";
}

printf "- f_bsize   : %d\n",   $stat->f_bsize;
printf "- f_frsize  : %d\n",   $stat->f_frsize;
printf "- f_blocks  : %d\n",   $stat->f_blocks;
printf "- f bfree   : %d\n",   $stat->f_bfree;
printf "- f_bavail  : %d\n",   $stat->f_bavail;
printf "- f_files   : %d\n",   $stat->f_files;
printf "- f_ffree   : %d\n",   $stat->f_ffree;
printf "- f_favail  : %d\n",   $stat->f_favail;
printf "- f_fsid    : %d\n",   $stat->f_fsid;
printf "- f_flag    : 0x%o\n", $stat->f_flag;
printf "- f_namemax : %d\n",   $stat->f_namemax;

# create a file and take file-descriptor
my $fd = GlusterFS::GFAPI::FFI::glfs_creat($fs, "/potato", O_RDWR, 0644);

# get stat for a file
$stat = GlusterFS::GFAPI::FFI::Stat->new();

if (GlusterFS::GFAPI::FFI::glfs_stat($fs, "/potato", $stat))
{
    die "Failed to stat: $!";
}

printf "- ino     : %d\n",   $stat->st_ino;
printf "- mode    : 0x%o\n", $stat->st_mode;
printf "- size    : %d\n",   $stat->st_size;
printf "- blksize : %d\n",   $stat->st_blksize;
printf "- uid     : %d\n",   $stat->st_uid;
printf "- gid     : %d\n",   $stat->st_gid;
printf "- atime   : %d\n",   $stat->st_atime;
printf "- mtime   : %d\n",   $stat->st_mtime;
printf "- ctime   : %d\n",   $stat->st_ctime;

# write data to a file
my $buffer = 'this is a lipsum';

if (GlusterFS::GFAPI::FFI::glfs_write($fd, $buffer, length($buffer), 0) == -1)
{
    die "Failed to write: $!";
}

# seek a file offset
if (GlusterFS::GFAPI::FFI::glfs_lseek($fd, 0, 0))
{
    die "Failed to seek: $!";
}

# read data from a file
$buffer = "\0" x 256;

if (GlusterFS::GFAPI::FFI::glfs_read($fd, $buffer, 256, 0) == -1)
{
    die "Failed to read: $!";
}

printf "read: %s\n", $buffer;

# close a file
if (GlusterFS::GFAPI::FFI::glfs_close($fd))
{
    die "Failed to close: $!";
}

# destroy a connection
if (GlusterFS::GFAPI::FFI::glfs_fini($fs))
{
    die "Failed to terminate: $!"
}
```

## REQUIREMENTS

It uses gfapi C library so you should install that before using.

Please follow steps;

```sh
# RHEL/CentOS
sudo yum install glusterfs-api

# Debian/Ubuntu
sudo apt-get install glusterfs-common
```

## LIMITATIONS

### Asynchronous I/O

libgfapi-perl does not support some asynchronous I/O functions that using closure(callback) yet.

* ```glfs_read_async()```
* ```glfs_write_async()```
* ```glfs_readv_async()```
* ```glfs_writev_async()```
* ```glfs_pread_async()```
* ```glfs_pwrite_async()```
* ```glfs_preadv_async()```
* ```glfs_pwritev_async()```
* ```glfs_ftruncate_async()```
* ```glfs_fsync_async()```
* ```glfs_fdatasync_async()```
* ```glfs_discard_async()```
* ```glfs_zerofill_async()```

## SEE ALSO

- [overload](https://metacpan.org/pod/overload)



- [Fcntl](https://metacpan.org/pod/Fcntl)



- [POSIX](https://metacpan.org/pod/POSIX)



- [Carp](https://metacpan.org/pod/Carp)



- [Tiny::Try](https://metacpan.org/pod/Tiny::Try)



- [File::Spec](https://metacpan.org/pod/File::Spec)



- [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)



- [Moo](https://metacpan.org/pod/Moo)



- [Generator::Object](https://metacpan.org/pod/Generator::Object)



- [FFI::Platypus](https://metacpan.org/pod/FFI:Platypus)

    Write Perl bindings to non-Perl libraries without C or XS

- [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib)

    Check that a library is available for FFI

## AUTHOR

Author: Ji-Hyeon Gim ([@potatogim](https://github.com/potatogim))

Contributors

- Tae-Hwa Lee ([@alghost](https://github.com/alghost))

## COPYRIGHT AND LICENSE

This software is copyright 2017-2018 by Ji-Hyeon Gim.

This is free software; you can redistribute it and/or modify it under the same terms as the GPLv2/LGPLv3.

