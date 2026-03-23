#!perl

use strict;
use warnings;

use Test::More tests => 2;

use IO::Pty;
use Fcntl;
require POSIX;

# Test that destroying an IO::Pty object closes the slave fd
# See https://github.com/toddr/IO-Tty/issues/14

{
    my $slave_fileno;
    {
        my $pty = IO::Pty->new;
        ok( defined $pty, "IO::Pty created" );
        $slave_fileno = $pty->slave->fileno;
    }
    # $pty is now out of scope and destroyed.
    # The slave fd should have been closed by DESTROY.
    my $flags = POSIX::fcntl( $slave_fileno, F_GETFD, 0 );
    ok( !defined $flags, "slave fd $slave_fileno closed after IO::Pty destruction" );
}
