# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::Error qw(throw);

use Test::Simple ( 'tests' => 1 );
use Test::Filesys::POSIX::Error;

throws_errno_ok {
    throw &Errno::ENOENT;
}
&Errno::ENOENT, 'throw() does indeed throw errno stuff just fine';
