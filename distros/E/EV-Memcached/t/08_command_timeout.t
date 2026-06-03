use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

# command_timeout had no coverage (neither accessor nor behaviour).
plan tests => 4;

# --- accessor get/set ---
{
    my $mc = EV::Memcached->new(host => '127.0.0.1', port => 1,
                                on_error => sub { });
    is($mc->command_timeout, 0, 'command_timeout default is 0');
    $mc->command_timeout(250);
    is($mc->command_timeout, 250, 'command_timeout set to 250');
}

# --- behaviour: a command to a non-responding server times out ---
# A listening socket whose connections are never accept()ed still completes
# the TCP handshake via the kernel backlog, so connect(2) succeeds and
# on_connect fires; but nothing is ever read or answered, so the in-flight
# command must hit command_timeout. On timeout the pending callback receives
# the disconnect error and on_error receives "command timeout".
SKIP: {
    my $bh = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1,
    ) or skip "cannot create black-hole listener: $!", 2;
    my $bport = $bh->sockport;

    my ($on_err, $cmd_err);
    my $mc = EV::Memcached->new(
        host => '127.0.0.1', port => $bport, command_timeout => 300,
    );
    $mc->on_error(sub { $on_err = $_[0]; EV::break });
    $mc->on_connect(sub {
        $mc->get('somekey', sub { (undef, $cmd_err) = @_ });
    });

    my $safety = EV::timer 3, 0, sub { EV::break };
    EV::run;

    like($on_err, qr/command timeout/i,
        'on_error reports "command timeout" when the server never responds');
    ok(defined $cmd_err,
        'pending command callback receives an error on command timeout');
}
