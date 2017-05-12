# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::FdTable ();

use Test::More ( 'tests' => 3 );
use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

package Dummy::Inode;

sub new {
    bless {}, shift;
}

sub open {
    my ( $self, $flags ) = @_;

    return $flags ? 'OK' : undef;
}

package main;

my $fds = Filesys::POSIX::FdTable->new;

lives_ok {
    $fds->open( Dummy::Inode->new, 1 );
}
'Filesys::POSIX::FdTable->open() returns a file handle opened by inode object';

throws_errno_ok {
    $fds->open( Dummy::Inode->new, 0 );
}
&Errno::ENODEV, "Filesys::POSIX::FdTable->open() dies when \$inode->open() fails";
