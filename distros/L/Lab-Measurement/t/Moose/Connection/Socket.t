#!perl

use warnings;
use strict;
use 5.010;
use Test::More tests => 3;

use Lab::Moose::Connection::Socket;
use IO::Socket::INET;

my $device = IO::Socket::INET->new(
    Type      => SOCK_STREAM,
    ReuseAddr => 1,
    Listen    => 5
) or die "cannot open socket";

my $port = $device->sockport();
my $client;
my $pid = fork();

if ( not defined $pid ) {
    die "could not fork";
}

my $non_binary = "a" x 100000;
my $binary     = "#6100000" . "\xff\x00" x 50000;
if ($pid) {

    # Parent: client
    my $connection = Lab::Moose::Connection::Socket->new(
        host    => 'localhost',
        port    => $port,
        timeout => 1,
    );
    is(
        $connection->Query( command => "*IDN?" ), "dummy instrument\n",
        "simple query"
    );
    is(
        $connection->Query(
            command     => "long_non_binary",
            read_length => length($non_binary)
        ),
        $non_binary,
        "non binary long string"
    );
    is(
        $connection->Query(
            command     => "long_binary",
            read_length => length($binary)
        ),
        $binary,
        "block data non-ascii"
    );

}
else {
    # Child: device
    $client = $device->accept();
    device_read("*IDN?\n");
    device_write("dummy instrument\n");
    device_read("long_non_binary\n");
    device_write($non_binary);
    device_read("long_binary\n");
    device_write($binary);

}

sub device_write {
    my $str = shift;
    $client->syswrite($str);
}

sub device_read {
    my $expect = shift;
    my $str;

    # Use sysread instead of read, as it's non-blocking.
    $client->sysread( $str, 1000 );
    if ( $str ne $expect ) {
        die "device expected '$expect', got '$str'\n";
    }
}

