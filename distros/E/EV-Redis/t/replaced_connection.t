use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use IO::Socket::UNIX;
use File::Temp qw(tempdir);

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

# a listening socket that answers only when told to
my $dir = tempdir(CLEANUP => 1);
my $hung_path = "$dir/hung.sock";
my $hung = IO::Socket::UNIX->new(Local => $hung_path, Listen => 5) or die $!;

sub run_until {
    my ($done, $secs) = @_;
    my $expired;
    EV::now_update;
    my $g = EV::timer $secs, 0, sub { $expired = 1; EV::break };
    my $c = EV::prepare sub { EV::break if $done->() };
    EV::run until $done->() || $expired;
}

# replies owed by a connection disconnect() replaced hold no max_pending slot
{
    my @log;
    my $r = EV::Redis->new(path => $hung_path, max_pending => 1,
        on_error => sub { push @log, "error: $_[0]" });
    $r->get('never', sub { push @log, 'old: ' . ($_[1] // $_[0] // 'nil') });
    run_until(sub { 0 }, 0.2);

    is $r->pending_count, 1, 'one reply outstanding on the hung connection';
    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    is $r->pending_count, 1, 'pending_count still counts the owed reply';
    $r->ping(sub { push @log, 'new: ' . ($_[1] // $_[0]) });
    is $r->waiting_count, 0, 'the new connection sends at once';
    run_until(sub { grep { /^new/ } @log }, 5);
    is_deeply \@log, ['new: PONG'], 'a command on the new connection is answered';

    # the hung server answers at last
    my $peer = $hung->accept;
    sysread $peer, my $req, 4096;
    syswrite $peer, "\$-1\r\n";
    run_until(sub { grep { /^old/ } @log }, 5);
    is_deeply \@log, ['new: PONG', 'old: nil'], 'the owed reply arrives';
    is $r->pending_count, 0, 'nothing outstanding';

    my @order;
    $r->echo($_, sub { push @order, $_[0] }) for qw(a b);
    is $r->waiting_count, 1, 'max_pending holds again on the new connection';
    run_until(sub { @order == 2 }, 5);
    is_deeply \@order, [qw(a b)], 'both sent in order';
    $r->disconnect;
}

# a reply still owed when the object goes fails with the others
{
    my @log;
    my $r = EV::Redis->new(path => $hung_path, max_pending => 1,
        on_error => sub { push @log, "error: $_[0]" });
    $r->get('never', sub { push @log, 'old: ' . ($_[1] // 'reply') });
    run_until(sub { 0 }, 0.2);
    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    $r->ping(sub { push @log, 'new: ' . ($_[1] // $_[0]) });
    run_until(sub { grep { /^new/ } @log }, 5);
    undef $r;
    is_deeply \@log, ['new: PONG', 'old: disconnected'],
        'destroying the object fails the owed reply';
}

# a retired connection must not cancel commands kept for a failed replacement
{
    my $path = "$dir/retired.sock";
    my $server = IO::Socket::UNIX->new(Local => $path, Listen => 5) or die $!;
    my (@old, @new, @errors, $disconnects);
    $disconnects = 0;
    my $r = EV::Redis->new(path => $path, reconnect => 1,
        reconnect_delay => 2000, resume_waiting_on_reconnect => 1,
        on_error => sub { push @errors, $_[0] },
        on_disconnect => sub { $disconnects++ });
    $r->get('never', sub { push @old, [@_] });
    run_until(sub { 0 }, 0.1);
    my $peer = $server->accept or die $!;
    sysread $peer, my $req, 4096;

    $r->disconnect;
    $r->connect_unix("$dir/missing.sock");
    $r->ping(sub { push @new, [@_] });
    is $r->waiting_count, 1, 'replacement failure leaves a command waiting for reconnect';
    syswrite $peer, "\$-1\r\n";
    run_until(sub { @old }, 5);

    is_deeply \@old, [[undef]], 'the retired connection still delivers its owed reply';
    is $r->waiting_count, 1, 'its disconnect preserves the replacement waiting queue';
    is scalar @new, 0, 'the waiting command has not been cancelled';
    is $disconnects, 0, 'the retired disconnect runs no current connection handler';
    is scalar @errors, 1, 'only the replacement connect failure reports an error';

    $r->connect_unix($connect_info{sock});
    run_until(sub { @new }, 5);
    is_deeply \@new, [['PONG']], 'the preserved command runs on the next connection';
    $r->disconnect;
}

# a retired connection must not restart reconnect after an explicit disconnect
{
    my $path = "$dir/retired_error.sock";
    my $server = IO::Socket::UNIX->new(Local => $path, Listen => 5) or die $!;
    my ($old_error, $ping, $connects, $disconnects, @errors);
    ($connects, $disconnects) = (0, 0);
    my $r = EV::Redis->new(path => $path, reconnect => 1, reconnect_delay => 50,
        on_connect => sub { $connects++ },
        on_disconnect => sub { $disconnects++ },
        on_error => sub { push @errors, $_[0] });
    $r->get('never', sub { $old_error = $_[1] });
    run_until(sub { 0 }, 0.1);
    my $peer = $server->accept or die $!;
    sysread $peer, my $req, 4096;

    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    $r->ping(sub { $ping = $_[0] });
    run_until(sub { defined $ping }, 5);
    is $ping, 'PONG', 'the replacement connection is established';
    $r->disconnect;
    is $r->is_connected, 0, 'explicit disconnect closes the replacement';
    close $peer;
    run_until(sub { defined $old_error }, 5);
    run_until(sub { 0 }, 0.2);

    ok defined $old_error, 'the retired connection reports its failure to its command';
    is $r->is_connected, 0, 'the retired failure cannot reconnect after explicit disconnect';
    is $connects, 2, 'there were only the two requested connections';
    is $disconnects, 1, 'only the replacement disconnect runs the handler';
    is scalar @errors, 0, 'the retired failure runs no current error handler';
    $r->reconnect(0);
    $r->disconnect;
}

done_testing;
