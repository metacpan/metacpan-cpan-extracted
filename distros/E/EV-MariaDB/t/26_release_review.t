use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use IO::Socket::INET;
use B 'svref_2object';
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

my $dir = tempdir(CLEANUP => 1);
my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1)
    or die $!;
my $closed_port = $listener->sockport;
close $listener;

sub failed_connect {
    $_[0]->connect('127.0.0.1', 'root', '', '', $closed_port);
}

{
    eval { EV::MariaDB->new(host => 'localhost', unix_socket => "$dir/missing.sock") };
    like $@, qr/connect|socket|file/i, 'synchronous handshake failure still croaks from new';
}

subtest 'handlers retain callback values' => sub {
    for my $method (qw(on_connect on_error)) {
        my $m = EV::MariaDB->new(on_error => undef);
        my $cb = sub {};
        my $original = $cb;
        $m->$method($cb);
        $cb = sub {};
        is($m->$method(), $original, "$method survives caller reassignment");
        undef $cb;
        is($m->$method(), $original, "$method survives caller release");
    }
};

subtest 'queued query retains callback value' => sub {
    my ($original_calls, $replacement_calls) = (0, 0);
    my $m = EV::MariaDB->new(on_error => undef);
    failed_connect($m);
    my $cb = sub { $original_calls++ };
    $m->query('SELECT 1', $cb);
    $cb = sub { $replacement_calls++ };
    $m->finish;
    is($original_calls, 1, 'original queued callback fires once');
    is($replacement_calls, 0, 'replacement callback is not called');
    is($m->pending_count, 0, 'query is removed from the queue');
};

subtest 'reconnect errors release handler temporaries' => sub {
    my $m = EV::MariaDB->new(on_error => undef);
    my ($cb, $calls, $first, $last);
    $calls = 0;
    $cb = sub {
        ++$calls;
        my $refs = svref_2object(\$cb)->REFCNT + svref_2object($cb)->REFCNT;
        $first = $refs if $calls == 1;
        $last = $refs;
        $calls < 50 ? $m->reset : EV::break;
    };
    $m->on_error($cb);
    failed_connect($m);
    my $timed_out = 0;
    my $guard = EV::timer(5, 0, sub { $timed_out = 1; EV::break });
    EV::run;
    ok(!$timed_out, 'reconnect loop completes');
    is($calls, 50, 'all error callbacks fire');
    is($last, $first, 'handler references stay bounded within EV::run');
    $m->on_error(undef);
    $m->finish;
    undef $cb;
};

subtest 'failed handshake is disconnected inside on_error' => sub {
    my $connected;
    my $m = EV::MariaDB->new(on_error => undef);
    $m->on_error(sub { $connected = $m->is_connected });
    failed_connect($m);
    EV::run;
    is($connected, 0, 'failed connection is reported as disconnected');
    $m->on_error(undef);
};

subtest 'test socket selects local transport by default' => sub {
    local $ENV{TEST_MARIADB_SOCKET} = "$dir/missing.sock";
    local $ENV{TEST_MARIADB_HOST};
    delete $ENV{TEST_MARIADB_HOST};
    open my $child, '-|', $^X, '-It/lib', '-MTestMariaDB', '-e',
        'print $TestMariaDB::host' or die "child: $!";
    my $host = do { local $/; <$child> };
    close $child or die "child failed: $?";
    is($host, 'localhost', 'socket-only test configuration connects through the socket');
};

done_testing;
