#!/usr/bin/env perl
# A watch whose stream drops while it replays what it missed must still
# deliver every revision. Before 3.4.25/3.5.8 etcd answers a progress request
# at once, ahead of the rest of the replay; set EV_ETCD_TEST_OLD_ETCD to such
# an etcd binary. A newer one must pass too.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;
use IO::Select;
use File::Temp ();
use POSIX ();
use Time::HiRes ();

my $etcd_bin = $ENV{EV_ETCD_TEST_OLD_ETCD};
plan skip_all => 'set EV_ETCD_TEST_OLD_ETCD to an etcd binary before 3.4.25/3.5.8'
    unless $etcd_bin && -x $etcd_bin;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

sub free_port {
    my $s = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1)
        or die "listen: $!";
    return $s->sockport;
}

# etcd and the relay are forked before any gRPC state exists
my $dir = File::Temp->newdir;
my ($client_port, $peer_port) = (free_port(), free_port());
my $etcd_pid = fork // die "fork: $!";
if (!$etcd_pid) {
    open STDOUT, '>', "$dir/etcd.log";
    open STDERR, '>&', \*STDOUT;
    { exec $etcd_bin, '--data-dir', "$dir/data",
        '--listen-client-urls', "http://127.0.0.1:$client_port",
        '--advertise-client-urls', "http://127.0.0.1:$client_port",
        '--listen-peer-urls', "http://127.0.0.1:$peer_port",
        '--initial-advertise-peer-urls', "http://127.0.0.1:$peer_port",
        '--initial-cluster', "default=http://127.0.0.1:$peer_port" }
    POSIX::_exit(127);
}

my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1)
    or die "listen: $!";
my $relay_port = $listener->sockport;
my $relay_pid = fork // die "fork: $!";
if (!$relay_pid) {
    run_relay($listener, $client_port);
    POSIX::_exit(0);
}
close $listener;

END {
    local $?;
    for my $pid (grep { $_ } $relay_pid, $etcd_pid) {
        kill 'TERM', $pid;
        waitpid $pid, 0;
    }
}

for (1 .. 100) {
    last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$client_port", Timeout => 1);
    Time::HiRes::sleep(0.1);
}

my $direct = EV::Etcd->new(endpoints => ["127.0.0.1:$client_port"]);
my $relayed = EV::Etcd->new(endpoints => ["127.0.0.1:$relay_port"], max_retries => 50);

sub call {
    my ($client, $method, @args) = @_;
    my @r;
    my $t = EV::timer(30, 0, sub { @r = (undef, { message => 'timeout' }); EV::break });
    $client->$method(@args, sub { @r = @_; EV::break });
    EV::run;
    return @r;
}

my (undef, $status_err) = call($direct, 'status');
BAIL_OUT("etcd did not start: $status_err->{message}") if $status_err;

my $revisions = 10_000;
for my $iteration (1 .. 3) {
    my $prefix = "/xt-replay-$$-$iteration/";
    my (%seen, $created, $created_at);
    my $watch = $relayed->watch($prefix, { prefix => 1 }, sub {
        my ($resp, $err) = @_;
        return if $err;
        if ($resp->{created}) {
            $created++;
            $created_at = EV::now;
        }
        $seen{$_->{kv}{mod_revision}}++ for @{$resp->{events}};
    });
    { my $t = EV::timer(0.05, 0.05, sub { EV::break if $created }); EV::run }

    # Outage: refuse and drop the relayed connections while writing
    kill 'USR2', $relay_pid;
    Time::HiRes::sleep(0.05);
    kill 'USR1', $relay_pid;
    my ($sent, @written) = (0);
    my $writer = EV::timer(0, 0.01, sub {
        while ($sent - @written < 50 && $sent < $revisions) {
            $direct->put($prefix . ($sent++ % 97), 'v' x 200, sub {
                my ($resp, $err) = @_;
                BAIL_OUT("put failed: $err->{message}") if $err;
                push @written, $resp->{header}{revision};
                EV::break if @written == $revisions;
            });
        }
    });
    EV::run;
    undef $writer;

    # Reconnect; the relay holds etcd's replies for a moment after created,
    # so the client asks for progress before any replay arrives, and the
    # stream drops again before the replay can finish
    kill 'USR2', $relay_pid;
    my ($held, $dropped);
    my $driver = EV::timer(0.005, 0.005, sub {
        return unless $created > 1;
        kill 'HUP', $relay_pid unless $held++;
        if (!$dropped && EV::now - $created_at >= 0.4) {
            kill 'USR1', $relay_pid;
            $dropped = 1;
        }
        EV::break if $dropped && !grep { !$seen{$_} } @written;
    });
    my $limit = EV::timer(30, 0, sub { EV::break });
    EV::run;
    undef $driver;

    my @missing = grep { !$seen{$_} } @written;
    ok($dropped && !@missing, "iteration $iteration: every revision arrives though the replay was cut")
        or diag(@missing ? "missing revisions $missing[0]..$missing[-1]" : 'the stream was never dropped');
    $watch->cancel(sub {});
    call($direct, 'delete', $prefix, { prefix => 1 });
}

done_testing;

# TCP relay to etcd: SIGUSR1 drops every connection, SIGUSR2 toggles refusing
# new ones, SIGHUP holds etcd's side for 0.3 s
sub run_relay {
    my ($listener, $upstream) = @_;
    my ($drop, $refuse, $hold_until) = (0, 0, 0);
    local $SIG{USR1} = sub { $drop = 1 };
    local $SIG{USR2} = sub { $refuse = !$refuse };
    local $SIG{HUP} = sub { $hold_until = Time::HiRes::time() + 0.3 };
    local $SIG{TERM} = sub { POSIX::_exit(0) };
    local $SIG{PIPE} = 'IGNORE';
    my (%peer, %sock, %from_etcd);
    my $select = IO::Select->new($listener);
    while (1) {
        if ($drop) {
            $drop = 0;
            for my $s (values %sock) { $select->remove($s); close $s }
            %sock = %peer = %from_etcd = ();
        }
        my $holding = Time::HiRes::time() < $hold_until;
        for my $fh ($select->can_read(0.005)) {
            if ($fh == $listener) {
                my $down = $listener->accept or next;
                if ($refuse) { close $down; next }
                my $up = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$upstream") or do { close $down; next };
                $sock{fileno $_} = $_ for $down, $up;
                $peer{fileno $down} = $up;
                $peer{fileno $up} = $down;
                $from_etcd{fileno $up} = 1;
                $select->add($down, $up);
                next;
            }
            next if $holding && $from_etcd{fileno $fh};
            my $other = $peer{fileno $fh} or next;
            my $n = sysread $fh, my $buf, 65536;
            if (!$n) {
                for my $s ($fh, $other) {
                    $select->remove($s);
                    delete $_->{fileno $s} for \%sock, \%peer, \%from_etcd;
                    close $s;
                }
                next;
            }
            while (length $buf) {
                my $w = syswrite $other, $buf;
                last unless $w;
                substr($buf, 0, $w, '');
            }
        }
    }
}
