use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use Time::HiRes qw(time sleep);

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

# 'close' accepts and drops each connection at once, like a proxy whose
# backend is down; 'answer' replies to a PING and then drops it; 'idle' drops
# each one after 50 ms, like a server's idle timeout
sub fake_server {
    my ($mode) = @_;
    my $l = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1,
    ) or die "listen: $!";
    my %conns;
    my $accept = EV::io $l, EV::READ, sub {
        my $c = $l->accept or return;
        if ($mode eq 'close') { close $c; return }
        if ($mode eq 'idle') {
            my $id = fileno $c;
            $conns{$id} = [$c, EV::timer 0.05, 0, sub { delete $conns{$id}; close $c }];
            return;
        }
        my $id = fileno $c;
        $conns{$id} = [$c, EV::io $c, EV::READ, sub {
            my $buf;
            if (sysread($c, $buf, 65536) && $buf =~ /ping\r\n/i) { syswrite $c, "+PONG\r\n" }
            delete $conns{$id};
            close $c;
        }];
    };
    return { port => $l->sockport, keep => [$l, $accept, \%conns] };
}

# runs for $wait seconds, or until more than $enough connects
sub run_attempts {
    my ($port, $wait, $idle, $enough) = @_;
    my ($connects, @errors) = (0);
    my $r;
    $r = EV::Redis->new(
        on_error   => sub { push @errors, $_[0] },
        on_connect => sub { $connects++; $r->ping(sub {}) unless $idle },
    );
    $r->reconnect(1, 20, 3);
    $r->connect('127.0.0.1', $port);
    EV::now_update;
    my $guard = EV::timer $wait, 0, sub { EV::break };
    my $check = EV::prepare sub { EV::break if defined $enough && $connects > $enough };
    EV::run;
    $r->reconnect(0);
    $r->disconnect;
    return ($connects, @errors);
}

{
    my $port = do {
        my $s = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0);
        my $p = $s->sockport; close $s; $p
    };
    my ($connects, @errors) = run_attempts($port, 1);
    is $errors[-1], 'reconnect error: max attempts reached', 'refused: gives up after max attempts';
}

# an established connection starts the count again, however it ends
for my $case (['close', 0, 'closed at once'], ['answer', 0, 'that answered'],
              ['idle', 1, 'closed while idle']) {
    my ($mode, $idle, $what) = @$case;
    my $srv = fake_server($mode);
    my ($connects, @errors) = run_attempts($srv->{port}, 5, $idle, 4);
    cmp_ok $connects, '>', 4, "connections $what reset the count";
    ok !grep({ /max attempts/ } @errors), '... and the retries go on';
}

# slow failure handlers must not consume the reconnect delay, whether the
# failure was detected inside connect() or later in the event loop
{
    my $dir = tempdir(CLEANUP => 1);
    my $listener = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    ) or die "listen: $!";
    my $port = $listener->sockport;
    close $listener;

    for my $mode (qw(synchronous asynchronous)) {
        my ($handler_end, $retry_delay, $errors);
        $errors = 0;
        my $r = EV::Redis->new(reconnect => 1, reconnect_delay => 300,
            max_reconnect_attempts => 1, on_error => sub {
                if (++$errors == 1) {
                    sleep 0.6;
                    $handler_end = time;
                } elsif ($errors == 2) {
                    $retry_delay = time - $handler_end;
                    EV::break;
                }
            });
        EV::now_update;
        if ($mode eq 'synchronous') { $r->connect_unix("$dir/missing.sock") }
        else { $r->connect('127.0.0.1', $port) }
        EV::now_update;
        my $guard = EV::timer 3, 0, sub { EV::break };
        EV::run;
        ok defined $retry_delay, "$mode failure: a reconnect was attempted";
        cmp_ok $retry_delay // 0, '>=', 0.25,
            "$mode failure: reconnect waits its delay after the slow handler";
        $r->disconnect;
    }
}

done_testing;
