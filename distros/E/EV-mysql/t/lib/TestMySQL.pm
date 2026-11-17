package TestMySQL;
use strict;
use warnings;
use IO::Socket::INET;
use IO::Socket::UNIX;

our $socket = $ENV{TEST_MYSQL_SOCKET} // $ENV{TEST_MARIADB_SOCKET};
our $host   = $ENV{TEST_MYSQL_HOST}   // $ENV{TEST_MARIADB_HOST} // ($socket ? 'localhost' : '127.0.0.1');
our $port   = $ENV{TEST_MYSQL_PORT}   // $ENV{TEST_MARIADB_PORT} // 3306;
our $user   = $ENV{TEST_MYSQL_USER}   // $ENV{TEST_MARIADB_USER} // 'root';
our $pass   = $ENV{TEST_MYSQL_PASSWORD} // $ENV{TEST_MYSQL_PASS} // $ENV{TEST_MARIADB_PASSWORD} // $ENV{TEST_MARIADB_PASS} // '';
our $db     = $ENV{TEST_MYSQL_DB}     // $ENV{TEST_MARIADB_DB}   // 'test';

sub server_available {
    if ($socket) {
        my $s = IO::Socket::UNIX->new(Peer => $socket);
        return defined $s ? 1 : 0;
    }
    my $s = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 1,
    );
    return defined $s ? 1 : 0;
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
