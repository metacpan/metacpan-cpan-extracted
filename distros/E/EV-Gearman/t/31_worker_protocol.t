# Worker protocol flows against a fake server. Hermetic — no gearmand
# needed. Covers wire bytes and job-method paths the live suite only
# reaches incidentally: sync/async dispatch, explicit fail/exception,
# status with undef args, and work_stop.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use EV;
use EV::Gearman;

my $dir = tempdir(CLEANUP => 1);

# Fake binary server. $on_pkt->($conn, $cmd, $body) per client packet;
# $send->($conn, $cmd, $body) to reply. Records every client packet
# in @$pkts as [$cmd, $body].
sub binary_server {
    my ($path, $on_pkt) = @_;
    unlink $path;
    my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 16)
        or die "bind $path: $!";
    $srv->blocking(0);
    my $st = { srv => $srv, conns => [], pkts => [] };
    my $send = sub {
        my ($conn, $cmd, $body) = @_;
        $body = '' unless defined $body;
        syswrite $conn->{sock}, "\0RES" . pack('N N', $cmd, length $body)
            . $body;
    };
    $st->{send} = $send;
    $st->{accept} = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            my $conn = { sock => $c, rbuf => '' };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; return; }
                $conn->{rbuf} .= $chunk;
                while (length($conn->{rbuf}) >= 12) {
                    my (undef, $cmd, $len) =
                        unpack 'a4 N N', substr($conn->{rbuf}, 0, 12);
                    last if length($conn->{rbuf}) < 12 + $len;
                    my $body = substr($conn->{rbuf}, 12, $len);
                    substr($conn->{rbuf}, 0, 12 + $len) = '';
                    push @{$st->{pkts}}, [$cmd, $body];
                    $on_pkt->($conn, $cmd, $body) if $on_pkt;
                }
            };
            push @{$st->{conns}}, $conn;
        }
    };
    $st;
}

sub run_loop {
    my ($secs) = @_;
    my $t = EV::timer $secs, 0, sub { EV::break };
    EV::run;
}

# Client->server command codes.
my ($CAN_DO, $GRAB, $PRE_SLEEP) = (1, 9, 4);
# Server->client command codes.
my ($NO_JOB, $JOB_ASSIGN, $NOOP) = (10, 11, 6);
my ($WORK_COMPLETE, $WORK_FAIL, $WORK_EXCEPTION, $WORK_STATUS) =
    (13, 14, 25, 12);

# 1. Sync dispatch round-trip: CAN_DO, GRAB, JOB_ASSIGN, WORK_COMPLETE,
# then NO_JOB, PRE_SLEEP, idle.
{
    my $path = "$dir/w31a.sock";
    my ($workload_seen, $idle);
    my @errors;
    my $st;
    $st = binary_server($path, sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == $GRAB && @{$st->{pkts}} == 2) {
            $st->{send}->($conn, $JOB_ASSIGN, "H:1\0w31f\0hello");
        } elsif ($cmd == $GRAB) {
            $st->{send}->($conn, $NO_JOB, '');
        }
    });
    my $g = EV::Gearman->new(path => $path, on_error => sub {
        push @errors, $_[0];
    });
    $g->register_function('w31f', sub {
        $workload_seen = $_[0]->workload;
        return uc $_[0]->workload;
    });
    # Let the loop run a beat after idle so PRE_SLEEP flushes.
    $g->work(sub {
        $idle++;
        my $t; $t = EV::timer 0.2, 0, sub { undef $t; EV::break };
    });
    run_loop(5);
    my @cmds = map { $_->[0] } @{$st->{pkts}};
    is_deeply \@cmds, [$CAN_DO, $GRAB, $WORK_COMPLETE, $GRAB, $PRE_SLEEP],
        'sync dispatch: packet sequence';
    is $st->{pkts}[0][1], 'w31f', 'sync dispatch: CAN_DO body';
    is $workload_seen, 'hello', 'sync dispatch: workload delivered';
    is $st->{pkts}[2][1], "H:1\0HELLO", 'sync dispatch: WORK_COMPLETE body';
    is $idle, 1, 'sync dispatch: idle fired once';
    is_deeply \@errors, [], 'sync dispatch: no errors';
    undef $g;
}

# 2. Async job methods: accessors, status(undef, undef) without
# warnings, explicit complete/fail/exception bytes.
{
    my $path = "$dir/w31b.sock";
    my @errors;
    my ($func_seen, $data_seen, @warns);
    my $phase = 0;
    my $st;
    $st = binary_server($path, sub {
        my ($conn, $cmd, $body) = @_;
        return unless $cmd == $GRAB;
        $phase++;
        if ($phase <= 3) {
            $st->{send}->($conn, $JOB_ASSIGN, "H:$phase\0w31a\0pay$phase");
        } else {
            $st->{send}->($conn, $NO_JOB, '');
        }
    });
    my $g = EV::Gearman->new(path => $path, on_error => sub {
        push @errors, $_[0];
    });
    my $njobs = 0;
    $g->register_function('w31a' => { async => 1 }, sub {
        my ($job) = @_;
        $njobs++;
        ($func_seen, $data_seen) = ($job->function, $job->data);
        if ($njobs == 1) {
            {
                local $SIG{__WARN__} = sub { push @warns, @_ };
                $job->status(undef, undef);
            }
            $job->complete('done');
        } elsif ($njobs == 2) {
            $job->fail;
        } else {
            $job->exception('boom');
            my $t; $t = EV::timer 0.3, 0, sub { undef $t; EV::break };
        }
    });
    $g->work;
    run_loop(5);
    is $njobs, 3, 'async: three jobs dispatched';
    is $func_seen, 'w31a', 'async: $job->function';
    is $data_seen, 'pay3', 'async: $job->data';
    is_deeply \@warns, [], 'async: status(undef, undef) warns nothing';
    my %by_cmd = map { $_->[0] => $_->[1] } @{$st->{pkts}};
    is $by_cmd{$WORK_STATUS}, "H:1\0\0", 'async: WORK_STATUS empty nums';
    is $by_cmd{$WORK_COMPLETE}, "H:1\0done", 'async: WORK_COMPLETE body';
    is $by_cmd{$WORK_FAIL}, 'H:2', 'async: explicit fail body';
    is $by_cmd{$WORK_EXCEPTION}, "H:3\0boom", 'async: exception body';
    is_deeply \@errors, [], 'async: no errors';
    undef $g;
}

# 3. work_stop: a NOOP arriving after work_stop must not trigger a
# new GRAB.
{
    my $path = "$dir/w31c.sock";
    my @errors;
    my ($idle, $grabs);
    my $st;
    $st = binary_server($path, sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == $GRAB) {
            $grabs++;
            $st->{send}->($conn, $NO_JOB, '');
        }
    });
    my $g = EV::Gearman->new(path => $path, on_error => sub {
        push @errors, $_[0];
    });
    $g->register_function('w31s', sub { 'x' });
    $g->work(sub {
        $idle++;
        $g->work_stop;
        my $t; $t = EV::timer 0.1, 0, sub {
            undef $t;
            $st->{send}->($st->{conns}[0], $NOOP, '');
            my $t2; $t2 = EV::timer 0.3, 0, sub {
                undef $t2; EV::break;
            };
        };
    });
    run_loop(5);
    is $idle, 1, 'work_stop: idle fired once';
    is $grabs, 1, 'work_stop: NOOP after work_stop sends no GRAB';
    is_deeply \@errors, [], 'work_stop: no errors';
    undef $g;
}

for my $reopen (0, 1) {
    my $path = "$dir/sync-reconnect-$reopen.sock";
    my $assigned = 0;
    my $st;
    $st = binary_server($path, sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == $GRAB && !$assigned++) {
            $st->{send}->($conn, $JOB_ASSIGN, "H:old\0sync\0payload");
        } elsif ($cmd == 16) {
            $st->{send}->($conn, 17, $body);
        }
    });
    my $g = EV::Gearman->new(path => $path, on_error => sub {});
    $g->register_function('sync', sub {
        $g->disconnect;
        if ($reopen) {
            $g->connect_unix($path);
            $g->echo('barrier', sub { EV::break });
        } else {
            EV::break;
        }
        return 'done';
    });
    $g->work;
    run_loop(3);
    is $g->waiting_count, 0, "sync disconnect ($reopen): no orphaned completion queued";
    my @terminal = grep { $_->[0] == $WORK_COMPLETE || $_->[0] == $WORK_FAIL
                       || $_->[0] == $WORK_EXCEPTION } @{$st->{pkts}};
    is_deeply \@terminal, [], "sync disconnect ($reopen): no completion on another session";
    undef $g;
}

{
    my $path = "$dir/stale-job.sock";
    my $assigned = 0;
    my $st;
    $st = binary_server($path, sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == $GRAB) {
            $assigned++;
            $st->{send}->($conn, $JOB_ASSIGN, "H:$assigned\0async\0payload");
        } elsif ($cmd == 16) {
            $st->{send}->($conn, 17, $body);
        }
    });
    my $g = EV::Gearman->new(path => $path, on_error => sub {});
    my @jobs;
    $g->register_function('async' => { async => 1 }, sub {
        push @jobs, shift;
        EV::break;
    });
    $g->work_one;
    run_loop(3);
    is scalar(@jobs), 1, 'old async job retained';
    $g->disconnect;
    $g->connect_unix($path);
    $g->work_one;
    run_loop(3);
    is scalar(@jobs), 2, 'new async job assigned after reconnect';
    for my $method (qw(complete fail send_data warning exception status)) {
        eval { $jobs[0]->$method('late', 100) };
        like $@, qr/stale job/, "$method rejects a job from the previous connection";
    }
    eval { $jobs[1]->complete('fresh') };
    is $@, '', 'current job remains usable';
    $g->echo('barrier', sub { EV::break });
    run_loop(3);
    my @terminal = grep { $_->[0] == $WORK_COMPLETE } @{$st->{pkts}};
    is_deeply \@terminal, [[$WORK_COMPLETE, "H:2\0fresh"]],
        'only the current job sends a completion';
    @jobs = ();
    is $g->_job_refs, 0, 'both sessions release their job references';
    undef $g;
}

{
    my $path = "$dir/no-job-reconnect.sock";
    my $st;
    $st = binary_server($path, sub {
        my ($conn, $cmd, $body) = @_;
        return unless $cmd == $GRAB;
        if (@{$st->{conns}} == 1) {
            $st->{send}->($conn, $NO_JOB, '');
        } else {
            $st->{send}->($conn, $JOB_ASSIGN, "H:new\0worker\0payload");
        }
    });
    my $g = EV::Gearman->new(path => $path, on_error => sub {});
    $g->register_function('worker', sub {
        $g->work_stop;
        my $timer; $timer = EV::timer 0.1, 0, sub { undef $timer; EV::break };
        return 'done';
    });
    $g->work(sub {
        $g->grab_job(sub {
            $g->disconnect;
            $g->connect_unix($path);
            $g->work;
        });
    });
    run_loop(3);
    my @commands = map { $_->[0] } @{$st->{pkts}};
    is_deeply \@commands, [$CAN_DO, $GRAB, $PRE_SLEEP, $GRAB,
                          $CAN_DO, $GRAB, $WORK_COMPLETE],
        'old NO_JOB callback does not put the replacement worker to sleep';
    undef $g;
}

done_testing;
