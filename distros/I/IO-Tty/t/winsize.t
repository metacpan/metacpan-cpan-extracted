#!perl

use strict;
use warnings;

use Test::More;
use IO::Pty;
require POSIX;

# pack_winsize / unpack_winsize are XS functions, always available
# set_winsize / get_winsize require the slave to be a tty

plan tests => 14;

# Test pack_winsize / unpack_winsize round-trip
{
    my $packed = IO::Tty::pack_winsize( 24, 80, 0, 0 );
    ok( defined $packed, "pack_winsize returns a value" );
    ok( length($packed) > 0, "pack_winsize returns non-empty data" );

    my @dims = IO::Tty::unpack_winsize($packed);
    is( scalar @dims, 4, "unpack_winsize returns 4 values" );
    is( $dims[0], 24, "row round-trips correctly" );
    is( $dims[1], 80, "col round-trips correctly" );
    is( $dims[2], 0,  "xpixel round-trips correctly" );
    is( $dims[3], 0,  "ypixel round-trips correctly" );
}

# Test with non-zero pixel values
{
    my $packed = IO::Tty::pack_winsize( 50, 132, 800, 600 );
    my @dims = IO::Tty::unpack_winsize($packed);
    is( $dims[0], 50,  "row=50 round-trips" );
    is( $dims[1], 132, "col=132 round-trips" );
}

# Test unpack_winsize rejects wrong-sized input
{
    eval { IO::Tty::unpack_winsize("too short") };
    like( $@, qr/Bad arg length/, "unpack_winsize croaks on wrong-sized input" );

    eval { IO::Tty::unpack_winsize("") };
    like( $@, qr/Bad arg length/, "unpack_winsize croaks on empty input" );
}

# Test pack_winsize with default pixel values (xpixel/ypixel default to 0)
{
    my $packed_explicit = IO::Tty::pack_winsize( 24, 80, 0, 0 );
    my $packed_default  = IO::Tty::pack_winsize( 24, 80 );
    is( $packed_explicit, $packed_default,
        "pack_winsize defaults xpixel/ypixel to 0" );
}

# Test set_winsize / get_winsize on slave
{
    my $pty = IO::Pty->new;
    my $slave = $pty->slave;

    SKIP: {
        skip "slave is not a tty on this system", 2
            unless POSIX::isatty($slave);

        $slave->set_winsize( 40, 100, 0, 0 );
        my @ws = $slave->get_winsize();
        is( $ws[0], 40,  "set_winsize/get_winsize row round-trip on slave" );
        is( $ws[1], 100, "set_winsize/get_winsize col round-trip on slave" );
    }
}
