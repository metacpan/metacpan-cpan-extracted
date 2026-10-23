use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use File::Temp 'tempdir';
use IO::Socket::INET;
use Scalar::Util 'weaken';
use EV;
use EV::MariaDB;

my $have_server = TestMariaDB::server_available();
diag('no test server - server-dependent blocks will skip') unless $have_server;
my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1)
    or die $!;
my $closed_port = $listener->sockport;
close $listener;

# Synchronous setup errors croak before invoking connection handlers.
{
    my $m;
    my ($inside_new, $in_loop) = (0, 0);
    eval { $m = EV::MariaDB->new(
        host        => 'localhost',
        user        => 'root',
        password    => '',
        database    => 'test',
        unix_socket => '/nonexistent-path/does-not-exist.sock',
        on_connect  => sub { fail('unexpected on_connect for bad socket') },
        on_error    => sub { defined $m ? $in_loop++ : $inside_new++ },
    ) };
    like($@, qr/connect|socket/i, 'synchronous connect failure croaks from new');
    is($inside_new + $in_loop, 0, 'failed constructor does not invoke handlers');
}

# --- Fix 1: queries queued from cancel cbs must get error cbs, not silence --
# Connect fails; the queued query's cancel cb queues another query. The second
# entry used to be dropped by drain_queues_silent, so its cb never fired.
{
    my $dir = tempdir(CLEANUP => 1);

    my ($cb1, $cb2) = (0, 0);
    my $m = EV::MariaDB->new(
        host => '127.0.0.1', port => $closed_port,
        user => 'root', password => '', database => 'test',
        on_connect => sub { fail('unexpected on_connect to missing socket') },
        on_error   => sub {},
    );
    $m->query('select 1', sub {
        $cb1 = 1;
        $m->query('select 2', sub { $cb2 = 1 });
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    my $w = EV::timer(0, 0.05, sub { EV::break if $cb2 });
    EV::run;
    ok($cb1, 'cancelled query cb fired on connect failure');
    ok($cb2, 'query queued from cancel cb gets error cb (not silently dropped)');
    eval { $m->finish };
}

SKIP: {
    skip 'No MariaDB/MySQL server', 8 unless $have_server;

    # --- Fix 4: reset() must not reconnect if a cancel cb called finish() ---
    {
        my $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub { EV::break },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for reset-vs-finish test') unless $m->is_connected;

        my ($cancelled, $reconnects) = (0, 0);
        $m->on_connect(sub { $reconnects++ });
        # sleep(), not select 1: a query the server answers at once can finish
        # inside query() on a fast loopback, and then the cb is a success cb
        # that ran before reset(), so reset() rightly reconnects.
        $m->query('select sleep(5)', sub { $cancelled = 1; $m->finish; });
        ok(!$cancelled, 'query is still in flight when reset() is called');
        $m->reset;
        $t = EV::timer(4, 0, sub { EV::break });
        EV::run;
        ok($cancelled, 'pending query cancelled by reset()');
        is($reconnects, 0, 'reset() does not reconnect after cancel cb called finish()');
        ok(!$m->is_connected, 'stays disconnected after finish() in cancel cb');
    }

    # --- Fix 5: skip_pending must spare an embryonic CONNECTING handshake ----
    {
        my $m;
        my ($skipped, $connected, $saw_m) = (0, 0, 0);
        $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub { $connected = 1; $saw_m = defined $m; EV::break; },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break; },
        );
        $m->query('select 1', sub {
            my (undef, $err) = @_;
            $skipped = 1 if defined $err && $err eq 'skipped';
        });
        $m->skip_pending;
        my $t = EV::timer(5, 0, sub { EV::break });
        EV::run;
        ok($skipped, 'queued query cancelled with "skipped"');
        ok($connected && $m->is_connected, 'embryonic connection survives skip_pending');
        ok($saw_m, 'on_connect fires with $m assigned');
        $m->finish if $m->is_connected;
    }

    # --- Fix 3: DESTROY must stop watchers re-armed by callback reset() -----
    # A cancel cb that calls reset() re-arms libev watchers; DESTROY used to
    # free the object with them active (use-after-free: hangs/crashes once a
    # later connection reuses the fd and malloc block).
    {
        {
            my $m = EV::MariaDB->new(
                TestMariaDB::connect_args(),
                on_connect => sub {},
                on_error   => sub {},
            );
            my $w = $m; weaken($w);
            $m->query('select 1', sub { $w->reset if $w });
            undef $m;
        }
        my ($answer, $timed_out) = (undef, 0);
        my $m2;
        $m2 = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub {
                $m2->query('select 42 as answer', sub {
                    my ($rows, $err) = @_;
                    $answer = $rows->[0][0] if $rows;
                    EV::break;
                });
            },
            on_error => sub { diag("m2 failed: $_[0]"); EV::break; },
        );
        my $t = EV::timer(10, 0, sub { $timed_out = 1; EV::break; });
        EV::run;
        ok(!$timed_out, 'loop proceeds after DESTROY-with-reset (no hang)');
        is($answer, 42, 'new connection works after DESTROY-with-reset');
        $m2->finish if $m2->is_connected;
    }
}

done_testing;
