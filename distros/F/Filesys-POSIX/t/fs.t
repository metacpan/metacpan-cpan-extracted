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

throws_ok {
    Filesys::POSIX->new;
}
qr/^No root filesystem specified/, "Filesys::POSIX->new() requires a root filesystem";
