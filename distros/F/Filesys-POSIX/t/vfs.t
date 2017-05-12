# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX      ();
use Filesys::POSIX::Mem ();
use Filesys::POSIX::Bits;

use Test::More ( 'tests' => 2 );
use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

$fs->mkdir('foo');

my $inode = $fs->stat('foo');

throws_errno_ok {
    $fs->{'vfs'}->statfs( $inode, 'exact' => 1 );
}
&Errno::ENXIO, "Filesys::POSIX::VFS->statfs() complains when a non mountpoint inode is specified";
