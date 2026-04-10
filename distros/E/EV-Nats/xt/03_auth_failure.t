use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use EV;
use EV::Nats;

my $nats_bin = '/usr/sbin/nats-server';
$nats_bin = `which nats-server 2>/dev/null` unless -x $nats_bin;
chomp $nats_bin;
unless (-x $nats_bin) {
    plan skip_all => "nats-server not found";
}

plan tests => 4;

my $tmp = tempdir(CLEANUP => 1);
my $port = 24321;

my $conf = "$tmp/nats.conf";
open my $fh, '>', $conf or die "write: $!";
print $fh "listen: 127.0.0.1:$port\nauthorization { token: secret123 }\n";
close $fh;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    exec $nats_bin, '-c', $conf;
    _exit(1);
}

sleep 1;

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

# Test: wrong token
my $got_error = '';
my $bad;
$bad = EV::Nats->new(
    host  => '127.0.0.1',
    port  => $port,
    token => 'wrong_token',
    on_error => sub { $got_error = $_[0] },
    on_connect => sub { fail 'should not connect with wrong token' },
);

my $t1; $t1 = EV::timer 2, 0, sub {
    undef $t1;
    like $got_error, qr/authorization/i, 'wrong token: error contains authorization';
    ok !$bad->is_connected, 'wrong token: not connected';

    # Test: correct token
    my $good;
    $good = EV::Nats->new(
        host  => '127.0.0.1',
        port  => $port,
        token => 'secret123',
        on_error => sub { diag "unexpected: @_" },
        on_connect => sub {
            pass 'correct token: connected';
            ok $good->is_connected, 'correct token: is_connected';
            $good->disconnect;
            EV::break;
        },
    );
};

EV::run;

kill 'TERM', $pid;
waitpid $pid, 0;
