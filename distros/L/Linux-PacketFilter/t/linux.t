#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use Socket;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Text::Control;

use Linux::PacketFilter ();

sub _unix_socket_tests {
    socketpair my $a, my $b, AF_UNIX(), SOCK_DGRAM(), 0;

    # For any packet whose 2nd byte is 'e', return only the first 2 bytes;
    # otherwise return the whole thing.
    my $filter = Linux::PacketFilter->new(
        [ 'ld b abs', 1 ],
        [ 'jmp jeq k', ord('e'), 0, 1 ],
        [ 'ret k', 2 ],
        [ 'ret k', 0xffffffff ],
    );

    $filter->attach($b);

    send( $a, "Hello.\n", 0 );
    send( $a, "There.\n", 0 );

    recv( $b, my $buf1, 512, 0 );
    recv( $b, my $buf2, 512, 0 );

    is( $buf1, 'He', 'filtered as intended' );
    is( $buf2, "There.$/", 'ignored as intended' );

    #----------------------------------------------------------------------

    # This seems strange .. the filter takes numbers in host order but
    # applies them in network order. Also consider Netlink Connector
    # sockets, where the filter needs numbers in network order to apply
    # them to host-order numbers.
    my $filter2 = Linux::PacketFilter->new(
        [ 'ld h abs', 0 ],
        [ 'jmp jeq k', 256, 0, 1 ],
        [ 'ret k', 0xffffffff ],
        [ 'ret k', 3 ],
    );

    $filter2->attach($b);

    send( $a, pack('n a*', 123, 'shortened'), 0 );
    send( $a, pack('n a*', 256, 'full'), 0 );
    send( $a, pack('n a*', 257, 'shortened'), 0 );
    send( $a, pack('n a*', 65534, 'shortened'), 0 );

    my @vals = map { recv($b, my $b, 512, 0); $b } 1 .. 4;
    is_deeply(
        \@vals,
        [
            pack('n a*', 123, 's'),
            pack('n a*', 256, 'full'),
            pack('n a*', 257, 's'),
            pack('n a*', 65534, 's'),
        ],
        'UNIX socket: 16-bit host/network order',
    ) or diag explain [ map { Text::Control::to_hex($_) } @vals ];

    #----------------------------------------------------------------------

    {
        my $filter3 = Linux::PacketFilter->new(
            [ 'ld w abs', 0 ],
            [ 'jmp jeq k_N', 256, 0, 1 ],
            [ 'ret k', 0xffffffff ],
            [ 'ret k', 5 ],
        );

        $filter3->attach($b);

        send( $a, pack('L a*', 123, 'shortened'), 0 );
        send( $a, pack('L a*', 256, 'full'), 0 );
        send( $a, pack('L a*', 257, 'shortened'), 0 );
        send( $a, pack('L a*', 65534, 'shortened'), 0 );

        my @vals = map { recv($b, my $b, 512, 0); $b } 1 .. 4;
        is_deeply(
            \@vals,
            [
                pack('L a*', 123, 's'),
                pack('L a*', 256, 'full'),
                pack('L a*', 257, 's'),
                pack('L a*', 65534, 's'),
            ],
            'UNIX socket: 32-bit host/network order',
        ) or diag explain [ map { Text::Control::to_hex($_) } @vals ];
    }
}

sub _netlink_tests {
    my $AF_NETLINK = 16;

    my $NETLINK_ROUTE = 0;
    my $RTM_GETLINK = 18;
    socket my $rtnls, $AF_NETLINK, Socket::SOCK_RAW(), $NETLINK_ROUTE;

    # Note!!! For Netlink headers we have to give “k” in network order.
    my $filter = Linux::PacketFilter->new(
        [ 'ld h abs', 4 ],
        [ 'jmp jeq k_n', 2, 0, 1 ],
        [ 'ret k', 0xffffffff ],
        [ 'ret k', 3 ],
    );
    $filter->attach($rtnls);

    send( $rtnls,
        pack( 'L S S L L a*', 16, $RTM_GETLINK, 0x10c, 0, 0 ),
        0,
    );

    recv( $rtnls, my $rtnlbuf, 65536, 0 );
    cmp_ok( length($rtnlbuf), '>', 3, 'Netlink headers match with byte order conversion.' );

    $filter = Linux::PacketFilter->new(
        [ 'ld h abs', 4 ],
        [ 'jmp jeq k', 2, 0, 1 ],
        [ 'ret k', 0xffffffff ],
        [ 'ret k', 3 ],
    );
    $filter->attach($rtnls);

    send( $rtnls,
        pack( 'L S S L L a*', 16, $RTM_GETLINK, 0x10c, 0, 0 ),
        0,
    );

    recv( $rtnls, my $rtnlbuf2, 65536, 0 );
    is( length($rtnlbuf2), 3, 'Netlink headers do not match without byte order conversion.' );
    #----------------------------------------------------------------------

    my $NETLINK_USERSOCK = 2;
    socket my $s, $AF_NETLINK, Socket::SOCK_RAW(), $NETLINK_USERSOCK;

    my $nl_addr = pack 'S x[S] L L', $AF_NETLINK, 0, 0;
    bind( $s, $nl_addr );

    my $filter2 = Linux::PacketFilter->new(
        [ 'ld h abs', 0 ],
        [ 'jmp jeq k', 256, 0, 1 ],
        [ 'ret k', 0xffffffff ],
        [ 'ret k', 3 ],
    );

    $filter2->attach($s);

    send( $s, pack('n a*', 123, 'shortened'), 0, getsockname($s) );
    send( $s, pack('n a*', 256, 'full'), 0, getsockname($s) );
    send( $s, pack('n a*', 257, 'shortened'), 0, getsockname($s) );
    send( $s, pack('n a*', 65534, 'shortened'), 0, getsockname($s) );

    my @vals = map { recv($s, my $b, 512, 0); $b } 1 .. 4;
    is_deeply(
        \@vals,
        [
            pack('n a*', 123, 's'),
            pack('n a*', 256, 'full'),
            pack('n a*', 257, 's'),
            pack('n a*', 65534, 's'),
        ],
        'Netlink socket: 16-bit host/network order',
    ) or diag explain [ map { Text::Control::to_hex($_) } @vals ];
}

SKIP: {
    skip 'This test only runs in Linux.' if $^O ne 'linux';

    _unix_socket_tests();

    _netlink_tests();
}

done_testing();
