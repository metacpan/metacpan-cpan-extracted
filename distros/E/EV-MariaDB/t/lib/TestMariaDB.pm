package TestMariaDB;
use strict;
use warnings;
use IO::Socket::INET;
use IO::Socket::UNIX;

our $host   = $ENV{TEST_MARIADB_HOST}   // '127.0.0.1';
our $port   = $ENV{TEST_MARIADB_PORT}   // 3306;
our $user   = $ENV{TEST_MARIADB_USER}   // 'root';
our $pass   = $ENV{TEST_MARIADB_PASS}   // '';
our $db     = $ENV{TEST_MARIADB_DB}     // 'test';
our $socket = $ENV{TEST_MARIADB_SOCKET};

sub server_available {
    if ($socket) {
        return IO::Socket::UNIX->new(Peer => $socket, Timeout => 2);
    }
    return IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 2,
    );
}

sub connect_args {
    return (
        host     => $host,
        port     => $port,
        user     => $user,
        password => $pass,
        database => $db,
        ($socket ? (unix_socket => $socket) : ()),
    );
}

1;
