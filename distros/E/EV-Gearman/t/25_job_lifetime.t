# Job -> client back-pointer lifetime. A stashed async job must keep
# the connection's control block allocated (as an inert tombstone) so
# that job methods after client destruction croak "client destroyed"
# instead of reading freed memory; and a forged job hashref must croak
# "stale job" instead of dereferencing a forged pointer.
#
# T-D1-1's pre-fix failure is a use-after-free that usually croaks
# "correctly" by luck (the stale bytes are not the magic word) — the
# deterministic pre-fix proof is the ASan demonstration referenced in
# the commit; this test locks the user-visible semantics.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $func = "lifetime_$$";

# T-D1-1: async worker stashes the job, the client object is destroyed
# from inside the callback, and a later job method must croak
# "client destroyed" — with the memory kept alive by the job's
# tombstone reference, not read from freed heap.
{
    my $w = EV::Gearman->new(host => $host, port => $port);
    my $c = EV::Gearman->new(host => $host, port => $port);
    my $job;
    $w->register_function($func => { async => 1 }, sub {
        $job = $_[0];
        undef $w;               # DESTROY with a job outstanding
        EV::break;
    });
    $w->work;
    $c->on_connect(sub { $c->submit_job_bg($func, "x") });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;

    ok $job, 'T-D1-1: job was dispatched and stashed';
    eval { $job->complete("late") };
    like $@, qr/client destroyed/, 'T-D1-1: job method croaks after client destroy';
    undef $job;                 # releases the tombstone reference
    pass 'T-D1-1: tombstone released without crash';
    undef $c;
}

# T-D1-2: forged job hashrefs. Fork-guarded: pre-fix the _client_ptr
# variant segfaults the child (proven); post-fix all variants croak
# cleanly. No gearmand involved.
{
    my @cases = (
        ['forged with _client_ptr', sub {
            my $j = bless { handle => 'H:1', _client_ptr => 12345 },
                          'EV::Gearman::Job';
            $j->complete('x');
        }],
        ['bare forged hash', sub {
            my $j = bless { handle => 'H:1' }, 'EV::Gearman::Job';
            $j->complete('x');
        }],
        ['blessed arrayref', sub {
            my $j = bless [], 'EV::Gearman::Job';
            $j->complete('x');
        }],
    );
    for my $case (@cases) {
        my ($name, $code) = @$case;
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {    # child
            close $rd;
            my $err = do {
                local $@;
                eval { $code->(); 1 } ? 'NOERROR' : $@;
            };
            print $wr ($err =~ /stale job|invalid job/ ? "OK" : "BAD:$err");
            close $wr;
            exit 0;
        }
        close $wr;
        local $/;
        my $out = <$rd> // '';
        close $rd;
        waitpid $pid, 0;
        my $status = $?;
        is $out, 'OK', "T-D1-2: $name croaks 'stale job'";
        is $status, 0, "T-D1-2: $name — child exited cleanly (no segfault)";
    }
}

# T-D1-3: millions-of-jobs constraint in miniature — jobs that are
# dropped after completion must leave job_refs at zero. Also asserts
# the counter actually rises while jobs are stashed (so the zero is
# meaningful).
{
    my $w = EV::Gearman->new(host => $host, port => $port);
    my $c = EV::Gearman->new(host => $host, port => $port);
    my $N = 50;
    my ($max_refs, $completed) = (0, 0);
    $w->register_function($func => { async => 1 }, sub {
        my ($job) = @_;
        my $r = $w->_job_refs;
        $max_refs = $r if $r > $max_refs;
        my $t; $t = EV::timer 0, 0, sub {
            $job->complete('r');
            $completed++;
            undef $t;       # releases the closure's $job
            EV::break if $completed == $N;
        };
    });
    $w->work;
    $c->on_connect(sub { $c->submit_job_bg($func, "w$_") for 1 .. $N });
    my $g = EV::timer 15, 0, sub { EV::break };
    EV::run;

    is $completed, $N, "T-D1-3: all $N async jobs completed";
    cmp_ok $max_refs, '>', 0, 'T-D1-3: job_refs rises while jobs are stashed';
    is $w->_job_refs, 0, 'T-D1-3: job_refs returns to zero after jobs drop';
    undef $c;
}

done_testing;
