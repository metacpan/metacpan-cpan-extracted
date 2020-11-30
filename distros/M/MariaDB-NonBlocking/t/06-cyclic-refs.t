#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
use Scalar::Util qw/weaken/;
use AnyEvent::XSPromises qw/collect/;
use MariaDB::NonBlocking::Promises;
use Data::Dumper;
AnyEvent::detect();

use lib 't', '.';
require 'lib.pl';

sub wait_for_promise ($) {
    my $p = shift;
    my $cv = AnyEvent->condvar;
    $p->then(
        sub { $cv->send; },
        sub { $cv->send; },
    );
    $p->catch(sub { $cv->send; });
    $cv->recv;
}

my $connect_args = {
    user     => $::test_user,
    password => $::test_password || '',
    ( $::testdb ? (database => $::testdb) : () ),
    host     => '127.0.0.1',
};

my $conn1 = MariaDB::NonBlocking::Promises->new;
my $conn2 = MariaDB::NonBlocking::Promises->new;
my @connect_promises = map $_->connect($connect_args), $conn1, $conn2;

wait_for_promise collect(@connect_promises);

{
    my $p1 = $conn1->run_query("select sleep(1)")->then(
        sub { $conn2->disconnect; },
        sub { fail("sleep(1) failed") },
    );
    my $p2 = $conn2->run_query("select sleep(3)")->then(sub {
        fail("sleep(3) unexpectedly succeeded");
    }, sub {
        my $error = $_[0];
        pass("sleep(3) died when its connection was disconnected");
        like($error, qr/DISCONNECTED/);
    });
    wait_for_promise collect($p1, $p2);
}

my $conn_3_holder = {};
$conn_3_holder->{conn_3} = MariaDB::NonBlocking::Promises->new;
wait_for_promise $conn_3_holder->{conn_3}->connect($connect_args);

{
    my $p3 = $conn1->run_query("select sleep(1)")->then(
        sub { $conn_3_holder = {}; },
        sub { fail("sleep(1) failed") },
    );
    $p3->catch(sub { say "shit @_" });
    my $p4 = $conn_3_holder->{conn_3}->run_query("select sleep(3)")->then(sub {
        fail("sleep(3) unexpectedly succeeded");
    }, sub {
        my $error = $_[0];
        pass("sleep(3) died when its connection was destroyed");
        like($error, qr/Connection object released before pending query was finished/);
    });
    $p4->catch(sub { say "crap @_"});
    wait_for_promise collect($p3, $p4);
}


done_testing;
