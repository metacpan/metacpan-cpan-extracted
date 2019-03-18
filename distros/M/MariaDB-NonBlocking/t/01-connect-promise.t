#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
use AnyEvent::XSPromises qw/collect/;
use MariaDB::NonBlocking::Promises;
use Data::Dumper;

AnyEvent::detect();

use lib 't', '.';
require 'lib.pl';

my $connect_args = {
    user     => $::test_user,
    host     => '127.0.0.1',
    password => $::test_password || '',
};
my $attr = {};

my $conn1 = MariaDB::NonBlocking::Promises->new;

my $initial_socket_fd = $conn1->mysql_socket_fd;
is($initial_socket_fd, -1, "Pre-connect socket FD is -1");

my $p1 = $conn1->connect($connect_args)->then(sub {
    # resolve handler
    my ($conn) = @_;
    my $socket_fd = $conn->mysql_socket_fd;
    cmp_ok($socket_fd, '>=', 1, "Got a socket FD after connecting");
})->catch(sub {
    my $error = $_[0] || '???';
    like($error, qr/Access denied/, "Could not connect -- wrong credentials given to Makefile.PL?");
    return;
});

my $connect_args_copy = { %$connect_args };
$connect_args_copy->{password} = $connect_args->{password} . '_xyzzy';

my $conn2 = MariaDB::NonBlocking::Promises->new;
my $p2 = $conn2->connect($connect_args_copy)->then(
    sub { fail("should never get here, wrong password connect worked?") },
    sub { pass("Failed to connect when using a wrong password") },
);

my $connect_args_copy2 = { %$connect_args };
delete $connect_args_copy2->{password};
my $conn3 = MariaDB::NonBlocking::Promises->new;
my $p3 = $conn3->connect($connect_args_copy2)->then(
    sub { fail("should never get here, no password connect worked?") },
    sub { like($_[0], qr/\ANo password/, "Failed to connect when missing a password") },
);

my $cv = AnyEvent->condvar;
collect($p1, $p2, $p3)->then(
    sub { $cv->send },
    sub { $cv->croak($_[0]) }
);
eval { $cv->recv(); };

done_testing;
