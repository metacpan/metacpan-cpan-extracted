#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
use MariaDB::NonBlocking::Event;
use Data::Dumper;

use lib 't', '.';
require 'lib.pl';

my $conn1 = MariaDB::NonBlocking::Event->init;

my $connect_args = {
    user     => $::test_user,
    host     => '127.0.0.1',
    password => $::test_password || '',
};
my $attr = {};

my $initial_socket_fd = $conn1->mysql_socket_fd;
is($initial_socket_fd, -1, "Pre-connect socket FD is -1");

my $cv = AnyEvent->condvar;
$conn1->connect(
    $connect_args,
    {
        success_cb => sub {
            $cv->send('Success!');

            my ($conn) = @_;
            my $socket_fd = $conn->mysql_socket_fd;
            cmp_ok($socket_fd, '>=', 1, "Got a socket FD after connecting");
        },
        failure_cb => sub { $cv->croak($_[0]) },
    },
);

my $output;
eval {
    $output = $cv->recv;
    is($output, "Success!", "Can connect using default params");
    1;
}
or do {
    my $error = $@ || '???';
    like($error, qr/Access denied/, "Could not connect -- wrong credentials given to Makefile.PL?");
};

my $connect_args_copy = { %$connect_args };
$connect_args_copy->{password} = $connect_args->{password} . '_xyzzy';

$cv = AnyEvent->condvar;
my $conn2 = MariaDB::NonBlocking::Event->init;
$conn2->connect(
    $connect_args_copy,
    {
        success_cb => sub { $cv->send('Success!') },
        failure_cb => sub { $cv->send('Failure! ' . $_[0]) },
    },
);
$output = $cv->recv;
like($output, qr/\AFailure!/, "Failed to connect when using the wrong password");

$cv = AnyEvent->condvar;
delete $connect_args_copy->{password};
my $conn3 = MariaDB::NonBlocking::Event->init;
$conn3->connect(
    $connect_args_copy,
    {
        success_cb => sub { $cv->send('Success!') },
        failure_cb => sub { $cv->send('Failure! ' . $_[0]) },
    },
);
$output = $cv->recv;
like($output, qr/\AFailure! No password/, "Failed to connect when missing a password");


done_testing;