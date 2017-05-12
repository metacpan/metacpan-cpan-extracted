# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::VFS::Inode;

use strict;
use warnings;

sub new {
    my ( $class, $mountpoint, $root ) = @_;

    return bless { %$root, 'parent' => $mountpoint->{'parent'} }, ref $root;
}

1;
