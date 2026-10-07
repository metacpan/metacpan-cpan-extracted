use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use POSIX ();

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

sub run_for {
    my ($secs) = @_;
    EV::now_update;
    my $g = EV::timer $secs, 0, sub { EV::break };
    EV::run;
}

# what a child does with an inherited object must not reach the parent's socket
for my $mode (qw(run disconnect command reconnect)) {
    my @parent;
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {},
        ('reconnect' eq $mode ? (reconnect => 1, reconnect_delay => 50) : ()));
    $r->del('fork_list');
    $r->blpop('fork_list', 1, sub { push @parent, 'blpop:' . ($_[1] // 'nil') });
    run_for(0.2);

    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (0 == $pid) {
        close $rd;
        my @child;
        $r->on_error(sub { push @child, "error:$_[0]" });
        $r->disconnect if 'disconnect' eq $mode;
        if ('command' eq $mode || 'reconnect' eq $mode) {
            $r->ping(sub { push @child, 'ping1:' . ($_[1] // $_[0]) });
        }
        run_for(1.5);
        if ('reconnect' eq $mode) {
            $r->ping(sub { push @child, 'ping2:' . ($_[1] // $_[0]) });
            run_for(1);
        }
        print {$wr} map { "$_\n" } @child;
        close $wr;
        POSIX::_exit(0);
    }
    close $wr;
    run_for(1.5);
    my $pong;
    $r->ping(sub { $pong = $_[0] });
    run_for(0.5);
    waitpid $pid, 0;
    my @child = <$rd>;
    chomp @child;

    is_deeply \@parent, ['blpop:nil'], "$mode: the parent gets its own reply";
    is $pong, 'PONG', "$mode: and its next one";
    if ('command' eq $mode || 'reconnect' eq $mode) {
        is $child[0], 'ping1:connection inherited from the parent process',
            "$mode: a command in the child fails";
    }
    if ('reconnect' eq $mode) {
        is $child[-1], 'ping2:PONG', 'reconnect: the child connects on its own';
    }
    $r->disconnect;
}

# forked while connecting: the child neither waits for that connect nor reports it
{
    require Socket;
    socket(my $l, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or die;
    bind($l, Socket::sockaddr_in(0, Socket::inet_aton('127.0.0.1'))) or die;
    listen($l, 0) or die;
    my ($port) = Socket::sockaddr_in(getsockname($l));
    my @fill = map {
        socket(my $s, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or die;
        my $fl = fcntl($s, POSIX::F_GETFL(), 0);
        fcntl($s, POSIX::F_SETFL(), $fl | POSIX::O_NONBLOCK());
        connect($s, Socket::sockaddr_in($port, Socket::inet_aton('127.0.0.1')));
        $s;
    } 1 .. 3;
    run_for(0.1);

    for my $case (['a dropped SYN', $port], ['a done connect', $connect_info{sock}]) {
        my ($what, $to) = @$case;
        my @parent;
        my $r = EV::Redis->new(($to =~ /^\d+$/ ? (host => '127.0.0.1', port => $to) : (path => $to)),
            connect_timeout => 300,
            on_error => sub { push @parent, "error:$_[0]" }, on_connect => sub { push @parent, 'connect' });
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (0 == $pid) {
            close $rd;
            my @child;
            $r->on_connect(sub { push @child, 'connect' });
            $r->on_error(sub { push @child, "error:$_[0]" });
            run_for(1);
            print {$wr} map { "$_\n" } @child;
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        run_for(1);
        waitpid $pid, 0;
        my @child = <$rd>;
        chomp @child;
        is_deeply \@child, ['error:connection inherited from the parent process'],
            "forked while connecting, $what: the child's copy fails at once";
        $r->disconnect if $r->is_connected;
    }
}

done_testing;
