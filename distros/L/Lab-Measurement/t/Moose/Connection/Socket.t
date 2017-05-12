#!perl

use warnings;
use strict;
use 5.010;
use Test::More tests => 5;

use Lab::Moose::Connection::Socket;
use IO::Socket::INET;

my $device = IO::Socket::INET->new(
    Type   => SOCK_STREAM,
    Reuse  => 1,
    Listen => 5
) or die "cannot open socket";

my $port = $device->sockport();
my $client;
my $pid = fork();

if ( not defined $pid ) {
    die "could not fork";
}

my $non_binary1 = "a" x 100000;
my $binary1     = "#6100000" . "a" x 100000;
my $binary2     = "#6100000" . "a\n" x 50000;
my $binary3     = "#6100000" . "\xff\x00" x 50000;
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
    is( $connection->Read(), $non_binary1 . "\n", "non binary long string" );
    is( $connection->Read(), $binary1 . "\n",     "block data ascii" );
    is(
        $connection->Read(), $binary2 . "\n",
        "block data ascii with newlines"
    );
    is( $connection->Read(), $binary3 . "\n", "block data non-ascii" );

}
else {
    # Child: device
    $client = $device->accept();
    device_read("*IDN?");
    device_write("dummy instrument");
    device_write($non_binary1);
    device_write($binary1);
    device_write($binary2);
    device_write($binary3);

}

sub device_write {
    my $str = shift;
    $client->syswrite( $str . "\n" );
}

sub device_read {
    my $expect = shift;
    my $str;

    # Use sysread instead of read, as it's non-blocking.
    $client->sysread( $str, 1000 );
    if ( $str ne ( $expect . "\n" ) ) {
        die "device expected '$expect', got '$str'\n";
    }
}

