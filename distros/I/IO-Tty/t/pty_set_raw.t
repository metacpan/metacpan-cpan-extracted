#!perl

use strict;
use warnings;

use Test::More;
use IO::Pty;
use POSIX;

plan tests => 14;

my $master = IO::Pty->new;
ok( $master, "IO::Pty->new succeeded" );

my $slave = $master->slave;
ok( $slave, "got slave" );

ok( POSIX::isatty($slave), "slave is a tty" );

my $ret = $slave->set_raw();
ok( $ret, "set_raw() returned success" );

# verify termios flags match cfmakeraw expectations
my $ttyno = fileno($slave);
my $termios = POSIX::Termios->new;
ok( $termios->getattr($ttyno), "getattr after set_raw" );

# lflag: all processing flags should be off
my $lflag = $termios->getlflag();
is( $lflag & POSIX::ECHO(),   0, "ECHO is off after set_raw" );
is( $lflag & POSIX::ICANON(), 0, "ICANON is off after set_raw" );

# iflag: should be zeroed (no input processing)
my $iflag = $termios->getiflag();
is( $iflag, 0, "iflag is 0 after set_raw" );

# oflag: should be zeroed (no output processing)
my $oflag = $termios->getoflag();
is( $oflag, 0, "oflag is 0 after set_raw" );

# cflag: PARENB should be cleared, CS8 should be set
my $cflag = $termios->getcflag();
is( $cflag & POSIX::PARENB(), 0, "PARENB is off after set_raw" );
is( $cflag & POSIX::CSIZE(), POSIX::CS8(), "CSIZE is CS8 after set_raw" );

# cc: VMIN=1, VTIME=0 for blocking single-byte reads
is( $termios->getcc(POSIX::VMIN()),  1, "VMIN is 1 after set_raw" );
is( $termios->getcc(POSIX::VTIME()), 0, "VTIME is 0 after set_raw" );

# set_raw on master returns 1 silently when master is not a tty
SKIP: {
    skip "master is a tty on this system", 1 if POSIX::isatty($master);

    my $mret = $master->set_raw();
    is( $mret, 1, "set_raw on non-tty master returns 1" );
}
