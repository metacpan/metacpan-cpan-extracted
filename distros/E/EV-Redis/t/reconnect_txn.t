use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';
my $server = eval { Test::RedisServer->new }
    or plan skip_all => 'redis-server is required';
my %ci = $server->connect_info;
my $helper = EV::Redis->new(path => $ci{sock});

sub await {
    my ($done) = @_;
    return if $done->();
    my $expired;
    EV::now_update;
    my $guard = EV::timer 5, 0, sub { $expired = 1; EV::break };
    EV::run until $done->() || $expired;
    die "timed out\n" if $expired;
}

sub request {
    my ($client, @args) = @_;
    my ($done, $reply, $error);
    $client->command(@args, sub { ($reply, $error) = @_; $done = 1; EV::break });
    await(sub { $done });
    return ($reply, $error);
}

my ($info) = request($helper, 'INFO', 'server');
plan skip_all => 'CLIENT ID needs Redis 5+' if $info =~ /redis_version:([0-4])\./;

sub blocked {
    my ($id) = @_;
    for (1..100) {
        my ($list) = request($helper, 'CLIENT', 'LIST');
        return if grep { /^id=\Q$id\E\s/ && /\bcmd=blpop\b/ } split /\n/, $list;
    }
    die "client $id did not block\n";
}

sub client {
    EV::Redis->new(path => $ci{sock}, max_pending => 2,
        reconnect => 1, reconnect_delay => 10, resume_waiting_on_reconnect => 1,
        on_error => sub {}, @_);
}

subtest 'UNWATCH inside MULTI does not detach later fragments' => sub {
    request($helper, 'DEL', 'txn_unwatch_write');
    my $r = client();
    my ($id) = request($r, 'CLIENT', 'ID');
    $r->blpop('txn_unwatch_block', 0, sub {});
    $r->multi(sub {});
    $r->unwatch(sub {});
    my (@set, @exec);
    $r->set('txn_unwatch_write', 'orphan', sub { @set = @_; EV::break });
    $r->exec(sub { @exec = @_; EV::break });
    blocked($id);
    is((request($helper, 'CLIENT', 'KILL', 'ID', $id))[0], 1, 'connection killed');
    await(sub { @set && @exec });
    ok $set[1], 'SET fails with the lost transaction';
    ok $exec[1], 'EXEC fails with the lost transaction';
    unlike $exec[1] // '', qr/without MULTI/, 'EXEC was not replayed alone';
    is((request($helper, 'GET', 'txn_unwatch_write'))[0], undef, 'no orphan write');
    $r->disconnect;
};

subtest 'unsent backlog survives a lost setup transaction' => sub {
    request($helper, 'DEL', 'txn_unsent_write');
    my ($r, $generation, $id);
    $r = client(on_connect => sub {
        return if $generation++;
        $r->command('CLIENT', 'ID', sub { $id = $_[0]; EV::break });
        $r->blpop('txn_setup_block', 0, sub {});
        $r->multi(sub {});
    });
    my (@multi, @set, @exec);
    $r->multi(sub { @multi = @_; EV::break });
    $r->set('txn_unsent_write', 'whole', sub { @set = @_; EV::break });
    $r->exec(sub { @exec = @_; EV::break });
    await(sub { defined $id });
    blocked($id);
    is((request($helper, 'CLIENT', 'KILL', 'ID', $id))[0], 1, 'connection killed');
    await(sub { @exec });
    is_deeply \@multi, ['OK'], 'unsent MULTI replays';
    is_deeply \@set, ['QUEUED'], 'SET is queued in that transaction';
    is_deeply \@exec, [['OK']], 'EXEC completes the whole transaction';
    is((request($helper, 'GET', 'txn_unsent_write'))[0], 'whole', 'whole transaction applied');
    $r->disconnect;
};

subtest 'a refused WATCH preserves an earlier WATCH' => sub {
    request($helper, 'DEL', 'txn_watch_write');
    my $r = client(max_pending => 1);
    my ($id) = request($r, 'CLIENT', 'ID');
    is((request($r, 'WATCH', 'txn_watch_write'))[0], 'OK', 'first WATCH succeeds');
    like((request($r, 'WATCH'))[1], qr/wrong number/, 'second WATCH is refused');
    $r->blpop('txn_watch_block', 0, sub {});
    my @set;
    $r->set('txn_watch_write', 'orphan', sub { @set = @_; EV::break });
    blocked($id);
    is((request($helper, 'CLIENT', 'KILL', 'ID', $id))[0], 1, 'connection killed');
    await(sub { @set });
    ok $set[1], 'waiting write fails with the lost WATCH';
    is((request($helper, 'GET', 'txn_watch_write'))[0], undef, 'write did not replay unwatched');
    $r->disconnect;
};

subtest 'manual reconnect drops the old transaction state' => sub {
    request($helper, 'DEL', 'txn_manual_write');
    my $r = client(max_pending => 1);
    request($r, 'WATCH', 'txn_manual_write');
    $r->blpop('txn_manual_old_block', 0, sub {});
    $r->disconnect;
    $r->connect_unix($ci{sock});
    my ($id, @set);
    $r->command('CLIENT', 'ID', sub { $id = $_[0]; EV::break });
    $r->blpop('txn_manual_new_block', 0, sub {});
    $r->set('txn_manual_write', 'standalone', sub { @set = @_; EV::break });
    await(sub { defined $id });
    blocked($id);
    is((request($helper, 'CLIENT', 'KILL', 'ID', $id))[0], 1, 'new connection killed');
    await(sub { @set });
    is_deeply \@set, ['OK'], 'standalone write replays normally';
    is((request($helper, 'GET', 'txn_manual_write'))[0], 'standalone', 'old WATCH did not own the new write');
    $r->disconnect;
};

$helper->disconnect;
done_testing;
