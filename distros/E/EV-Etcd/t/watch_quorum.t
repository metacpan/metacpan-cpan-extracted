#!/usr/bin/env perl
# Peer isolation leaves the client connection open; the watch must still fail over.
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use IO::Select;
use POSIX ();
BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

sub in_path { my ($cmd) = @_; grep { -x "$_/$cmd" } split /:/, $ENV{PATH} || '' }
plan skip_all => 'etcd needed in PATH' unless in_path('etcd');

# Reserve ports together so two members cannot pick the same one.
my @reserved = map {
    IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1) or die $!;
} 1 .. 6;
my @client_ports = map { $_->sockport } @reserved[0 .. 2];
my @backend_ports = map { $_->sockport } @reserved[3 .. 5];
my $dir = tempdir(CLEANUP => 1);
my @children;
END {
    local $?;
    kill 'TERM', @children if @children;
    waitpid $_, 0 for @children;
}
sub write_all {
    my ($fh, $bytes) = @_;
    while (length $bytes) {
        my $n = syswrite($fh, $bytes);
        return unless $n;
        substr($bytes, 0, $n, '');
    }
    return 1;
}
my @listeners = map {
    IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 30, ReuseAddr => 1)
        or die "peer proxy listen: $!";
} 1 .. 3;
my @peer_ports = map { $_->sockport } @listeners;
my $proxy = fork;
defined $proxy or die $!;
unless ($proxy) {
    close $_ for @reserved;
    $SIG{PIPE} = 'IGNORE';
    alarm 90;
    my $read = IO::Select->new(@listeners);
    my %listening = map { fileno($listeners[$_]) => $_ } 0 .. $#listeners;
    my (%pairs, %by_fd);
    my ($partitioned, $isolated_id);
    my $close_pair = sub {
        my $p = shift;
        return if $p->{closed}++;
        for my $side (qw(down up)) {
            my $fd = fileno($p->{$side});
            $read->remove($p->{$side});
            delete $by_fd{$fd};
            close $p->{$side};
        }
        delete $pairs{$p->{id}};
    };
    $SIG{USR1} = sub {
        open my $fh, '<', "$dir/isolated-id" or die $!;
        chomp($isolated_id = <$fh> // die "missing isolated member ID");
        close $fh;
        $partitioned = 1;
        for my $p (values %pairs) {
            $close_pair->($p) if $p->{destination} == 0 || ($p->{source} // '') eq $isolated_id;
        }
    };
    $SIG{USR2} = sub {
        $partitioned = 0;
        $close_pair->($_) for values %pairs;
    };
    while (1) {
        for my $fh ($read->can_read(0.1)) {
            my $fd = fileno $fh;
            next unless defined $fd;
            if (exists $listening{$fd}) {
                my $destination = $listening{$fd};
                my $down = $fh->accept or next;
                if ($partitioned && $destination == 0) { close $down; next }
                my $up = IO::Socket::INET->new(
                    PeerAddr => '127.0.0.1', PeerPort => $backend_ports[$destination], Timeout => 0.3,
                );
                unless ($up) { close $down; next }
                my $p = { down => $down, up => $up, destination => $destination, header => '', id => fileno($down) };
                $pairs{$p->{id}} = $p;
                $by_fd{fileno($down)} = [$p, 'down'];
                $by_fd{fileno($up)} = [$p, 'up'];
                $read->add($down, $up);
                next;
            }
            my $entry = $by_fd{$fd} or next;
            my ($p, $side) = @$entry;
            my $n = sysread($fh, my $bytes, 65536);
            unless ($n) { $close_pair->($p); next }
            if ($side eq 'down' && defined $p->{header}) {
                $p->{header} .= $bytes;
                next unless $p->{header} =~ /\r\n\r\n/;
                $p->{source} = lc($1) if $p->{header} =~ /^X-Server-From:\s*(\w+)/mi;
                if ($partitioned && ($p->{source} // '') eq $isolated_id) {
                    $close_pair->($p);
                    next;
                }
                $bytes = $p->{header};
                $p->{header} = undef;
            }
            my $to = $side eq 'down' ? $p->{up} : $p->{down};
            $close_pair->($p) unless write_all($to, $bytes);
        }
    }
    POSIX::_exit(0);
}
push @children, $proxy;
close $_ for @listeners;
close $_ for @reserved;
my $cluster = join ',', map { "n$_=http://127.0.0.1:$peer_ports[$_]" } 0 .. 2;
my $cluster_token = "test-quorum-$$";
for my $i (0 .. 2) {
    my $pid = fork;
    defined $pid or die $!;
    unless ($pid) {
        open STDOUT, '>', "$dir/member-$i.log" or POSIX::_exit(127);
        open STDERR, '>&', STDOUT;
        exec 'etcd', '--name', "n$i", '--data-dir', "$dir/n$i",
            '--listen-client-urls', "http://127.0.0.1:$client_ports[$i]",
            '--advertise-client-urls', "http://127.0.0.1:$client_ports[$i]",
            '--listen-peer-urls', "http://127.0.0.1:$backend_ports[$i]",
            '--initial-advertise-peer-urls', "http://127.0.0.1:$peer_ports[$i]",
            '--initial-cluster', $cluster, '--initial-cluster-token', $cluster_token,
            '--heartbeat-interval', '100', '--election-timeout', '1000'
            or POSIX::_exit(127);
    }
    push @children, $pid;
}
for my $port (@client_ports) {
    my $ready;
    for (1 .. 60) {
        if (IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Timeout => 0.1)) {
            $ready = 1;
            last;
        }
        select undef, undef, undef, 0.1;
    }
    plan skip_all => "member $port did not start" unless $ready;
}
sub rpc {
    my ($client, $method, @args) = @_;
    my ($resp, $err, $done);
    $client->$method(@args, sub { ($resp, $err) = @_; $done = 1; EV::break });
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
    die "$method failed: " . ($err ? $err->{message} : 'timeout') unless $done && !$err;
    return $resp;
}
sub wait_for {
    my ($condition, $seconds) = @_;
    my $poll = EV::timer(0.02, 0.02, sub { EV::break if $condition->() });
    my $guard = EV::timer($seconds, 0, sub { EV::break });
    EV::run;
}
my @endpoints = map { "127.0.0.1:$_" } @client_ports;
{
    # Members listen before they have elected a leader
    my $probe = EV::Etcd->new(endpoints => [$endpoints[0]], timeout => 1);
    my $leader;
    for (1 .. 60) {
        $probe->status(sub { $leader = $_[0] && $_[0]{leader}; EV::break });
        my $guard = EV::timer(2, 0, sub { EV::break });
        EV::run;
        last if $leader;
        wait_for(sub { 0 }, 0.25);
    }
    plan skip_all => 'the test cluster elected no leader' unless $leader;
}
my $writer = EV::Etcd->new(endpoints => [$endpoints[1]], timeout => 4);
my $isolated = EV::Etcd->new(endpoints => [$endpoints[0]], timeout => 1);
my $client = EV::Etcd->new(endpoints => \@endpoints, timeout => 1, max_retries => 10);
my $key = "/test-watch-quorum-$$";
rpc($writer, 'put', $key, 'initial');
my @leases = map { rpc($writer, 'lease_grant', 60)->{id} } 1 .. 4;
rpc($writer, 'put', "$key/session", 'alive', { lease => $leases[1] });
my $held_lock = rpc($writer, 'lock', "$key/blocking/lock", $leases[0]);
my $held_election = rpc($writer, 'election_campaign', "$key/blocking/election", $leases[2], 'holder');
my %blocking_results;
$client->lock("$key/blocking/lock", $leases[1], sub { push @{$blocking_results{lock}}, [@_] });
$client->election_campaign("$key/blocking/election", $leases[3], 'waiter', sub {
    push @{$blocking_results{campaign}}, [@_];
});
my ($created, @values, @errors, $control_created, @control_values);
my $watch = $client->watch($key, sub {
    my ($resp, $err) = @_;
    if ($err) { push @errors, $err; return }
    $created++ if $resp->{created};
    push @values, map { $_->{kv}{value} } @{$resp->{events}};
});
my $control = $writer->watch($key, sub {
    my ($resp, $err) = @_;
    return if $err;
    $control_created++ if $resp->{created};
    push @control_values, map { $_->{kv}{value} } @{$resp->{events}};
});
# With no other endpoint, a watch on the isolated member waits out the partition
my $stranded_client = EV::Etcd->new(endpoints => [$endpoints[0]], max_retries => 1);
my ($stranded_created, @stranded_values, @stranded_errors);
my $stranded = $stranded_client->watch($key, sub {
    my ($resp, $err) = @_;
    if ($err) { push @stranded_errors, $err; return }
    $stranded_created++ if $resp->{created};
    push @stranded_values, map { $_->{kv}{value} } @{$resp->{events}};
});
wait_for(sub { $created && $control_created && $stranded_created }, 4);
ok($created && $control_created && $stranded_created, 'all watches are established before the partition');
my $registered;
for (1 .. 40) {
    my $keys = rpc($writer, 'get', "$key/blocking/", { prefix => 1 })->{kvs};
    if (@$keys == 4) { $registered = 1; last }
    wait_for(sub { 0 }, 0.1);
}
ok($registered, 'both contended calls reached the first member before the partition');
is(scalar keys %blocking_results, 0, 'healthy contended calls remain pending');
my $before = rpc($isolated, 'status');
open my $id_file, '>', "$dir/isolated-id" or die $!;
printf $id_file "%x\n", $before->{header}{member_id};
close $id_file or die "close isolated-id: $!";
kill 'USR1', $proxy;
wait_for(sub { 0 }, 4);
my $after = rpc($isolated, 'status');
is($after->{leader}, 0, 'the first member has lost its leader while gRPC still responds');
is($after->{header}{member_id}, $before->{header}{member_id}, 'the status response still comes from the isolated member');
rpc($writer, 'put', $key, 'after-partition');
wait_for(sub { @values || @errors }, 8);
ok(grep($_ eq 'after-partition', @control_values), 'the other two members retain quorum and deliver the event');
ok(grep($_ eq 'after-partition', @values), 'watch fails over from the partitioned member and delivers the event');
cmp_ok($created, '>=', 2, 'the watch was recreated on a healthy endpoint');
is(scalar @errors, 0, 'the watch reports no terminal error during quorum failover');
diag explain \@errors if @errors;
wait_for(sub { keys %blocking_results == 2 }, 3) unless keys %blocking_results == 2;
for my $name (qw(lock campaign)) {
    my $results = $blocking_results{$name} || [];
    is(scalar @$results, 1, "accepted $name reports quorum loss once");
    my $err = @$results ? $results->[0][1] : undef;
    is($err && $err->{status}, 'UNAVAILABLE', "$name reports the unavailable member");
    is($err && $err->{retryable}, 0, "$name cannot safely reuse its lease");
    like($err && $err->{message}, qr/etcdserver: no leader/, "$name retains the quorum-loss reason");
}
is(rpc($writer, 'get', "$key/session")->{kvs}[0]{value}, 'alive',
    'failure does not revoke a lease shared with other keys');
rpc($writer, 'lease_revoke', $_) for @leases[1, 3];
my @retry_leases = map { rpc($writer, 'lease_grant', 60)->{id} } 1 .. 2;
rpc($writer, 'unlock', $held_lock->{key});
rpc($writer, 'election_resign', $held_election->{leader});
my $retried_lock = rpc($client, 'lock', "$key/blocking/lock", $retry_leases[0]);
my $retried_election = rpc($client, 'election_campaign', "$key/blocking/election", $retry_leases[1], 'waiter');
ok($retried_lock->{key}, 'lock recovery acquires with a fresh lease on the healthy endpoint');
ok($retried_election->{leader}, 'campaign recovery wins with a fresh lease on the healthy endpoint');
my @owner_keys = ($retried_lock->{key}, $retried_election->{leader}{key});
my @owners = map { rpc($writer, 'get', $_)->{kvs} } @owner_keys;

kill 'USR2', $proxy;
my $healed;
for (1 .. 40) {
    if (rpc($isolated, 'status')->{leader}) { $healed = 1; last }
    wait_for(sub { 0 }, 0.1);
}
ok($healed, 'the isolated member rejoins the quorum');
wait_for(sub { grep($_ eq 'after-partition', @stranded_values) || @stranded_errors }, 8);
ok(grep($_ eq 'after-partition', @stranded_values), 'a single-endpoint watch catches up after quorum returns');
cmp_ok($stranded_created, '>=', 2, 'quorum loss ended and recreated that watch');
is(scalar @stranded_errors, 0, 'retries without a leader do not use up max_retries');
diag explain \@stranded_errors if @stranded_errors;
my $contender_lease = rpc($writer, 'lease_grant', 60)->{id};
my %contender_results;
$writer->lock("$key/blocking/lock", $contender_lease, sub { push @{$contender_results{lock}}, [@_] });
$writer->election_campaign("$key/blocking/election", $contender_lease, 'contender', sub {
    push @{$contender_results{campaign}}, [@_];
});
$registered = 0;
for (1 .. 40) {
    my $keys = rpc($writer, 'get', "$key/blocking/", { prefix => 1 })->{kvs};
    if (@$keys == 4) { $registered = 1; last }
    wait_for(sub { 0 }, 0.1);
}
ok($registered, 'competing acquisitions reached the healed cluster');
wait_for(sub { keys %contender_results }, 5);
is(scalar keys %contender_results, 0, 'other clients cannot acquire while the recovered owners hold their leases');
for my $i (0 .. 1) {
    is_deeply(rpc($writer, 'get', $owner_keys[$i])->{kvs}, $owners[$i],
        'delayed cleanup preserves the recovered ownership key');
    cmp_ok(rpc($writer, 'lease_time_to_live', $retry_leases[$i])->{ttl}, '>', 30,
        'the recovered ownership lease remains valid');
}
rpc($writer, 'unlock', $retried_lock->{key});
rpc($writer, 'election_resign', $retried_election->{leader});
wait_for(sub { keys %contender_results == 2 }, 4);
for my $name (qw(lock campaign)) {
    my $results = $contender_results{$name} || [];
    is(scalar @$results, 1, "competing $name acquires once after the owner releases");
    is(@$results ? $results->[0][1] : 'timeout', undef, "competing $name succeeds after recovery");
}
$watch->cancel(sub {});
$control->cancel(sub {});
$stranded->cancel(sub {});
rpc($writer, 'lease_revoke', $_) for (@leases[0, 2], @retry_leases, $contender_lease);
rpc($writer, 'delete', $key);
done_testing;
