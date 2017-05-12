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

use Test::More ( 'tests' => 5 );
use Test::NoWarnings;

my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

ok( $fs->umask == 022, 'Filesys::POSIX has a default umask value of 022' );

my $fd = $fs->open( 'foo', $O_CREAT | $O_WRONLY );
ok(
    $fs->fstat($fd)->perms == 0644,
    'Filesys::POSIX->open() creates inodes with 0644 permissions with a umask of 022'
);
$fs->close($fd);

$fs->umask(077);
ok(
    $fs->umask == 077,
    'Filesys::POSIX->umask() allows setting and reading umask value'
);

$fd = $fs->open( 'bar', $O_CREAT | $O_WRONLY );
ok(
    $fs->fstat($fd)->perms == 0600,
    'Filesys::POSIX->open() creates inodes with 0600 permissions with a umask of 077'
);
$fs->close($fd);
