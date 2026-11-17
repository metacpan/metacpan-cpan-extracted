use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMySQL;
plan skip_all => 'No MySQL/MySQL server' unless TestMySQL::server_available();
plan tests => 19;
use EV;
use EV::mysql;

my $m;

sub with_mysql {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $m = EV::mysql->new(
        TestMySQL::connect_args(),
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
        %args,
    );
    my $timeout = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# Test 1-3: stmt large value via max_length buffer sizing
with_mysql(cb => sub {
    my $long_str = 'x' x 1000;
    $m->prepare("select ?", sub {
        my ($stmt, $err) = @_;
        die "prepare: $err" if $err;
        $m->execute($stmt, [$long_str], sub {
            my ($rows, $err2) = @_;
            ok(!$err2, 'max_length sizing: no error');
            is(scalar @$rows, 1, 'max_length sizing: 1 row');
            is($rows->[0][0], $long_str, 'max_length sizing: data matches');
            $m->close_stmt($stmt, sub { EV::break });
        });
    });
});

# Test 4-5: stmt with multiple columns of varying sizes
with_mysql(cb => sub {
    $m->prepare("select ?, ?, ?", sub {
        my ($stmt, $err) = @_;
        die "prepare: $err" if $err;
        my $big = 'y' x 2000;
        $m->execute($stmt, ['short', $big, 'also_short'], sub {
            my ($rows, $err2) = @_;
            ok(!$err2, 'multi-col truncation: no error');
            is_deeply($rows->[0], ['short', $big, 'also_short'],
                'multi-col truncation: all columns correct');
            $m->close_stmt($stmt, sub { EV::break });
        });
    });
});

# Test 6-8: reset() with queued operations
with_mysql(cb => sub {
    my @results;
    for my $i (1..3) {
        $m->q("select $i", sub {
            my ($rows, $err) = @_;
            push @results, $err ? "err:$err" : "ok:$rows->[0][0]";
        });
    }
    # reset cancels all pending, reconnects
    $m->reset;
    is(scalar @results, 3, 'reset with queue: all 3 callbacks fired');
    is(scalar(grep { /^err:/ } @results), 3, 'reset with queue: all got errors');

    # after reset, on_connect fires again — queue a verification query
    $m->on_connect(sub {
        $m->q("select 'after_reset'", sub {
            my ($rows, $err) = @_;
            is($rows->[0][0], 'after_reset', 'reset with queue: query after reconnect works');
            EV::break;
        });
    });
});

# Test 9: DESTROY during active async operation (deferred free)
{
    my $cb_fired = 0;
    {
        my $obj;
        $obj = EV::mysql->new(
            TestMySQL::connect_args(),
            on_connect => sub {
                $obj->q("select 1", sub {
                    $cb_fired = 1;
                });
                # let obj go out of scope while query is pending
                undef $obj;
            },
            on_error => sub {
                $cb_fired = 1;
            },
        );
        my $timeout = EV::timer(5, 0, sub { EV::break });
        EV::run;
    }
    # The query callback should have fired (either result or error from destroy)
    ok($cb_fired, 'DESTROY during active: callback fired');
}

# Test 10-11: deferred connect via connect()
{
    my $obj = EV::mysql->new(
        on_connect => sub { },
        on_error   => sub { diag("Error: $_[0]") },
    );
    ok(!$obj->is_connected, 'deferred connect: not connected initially');
    $obj->on_connect(sub {
        ok($obj->is_connected, 'deferred connect: connected after connect()');
        EV::break;
    });
    $obj->connect($TestMySQL::host, $TestMySQL::user, $TestMySQL::pass,
        $TestMySQL::db, $TestMySQL::port,
        ($TestMySQL::socket ? $TestMySQL::socket : undef));
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $obj->finish if $obj->is_connected;
}

# Test 12-13: init_command option
with_mysql(
    init_command => "set \@ev_mysql_init = 42",
    cb => sub {
        $m->q("select \@ev_mysql_init", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'init_command: no error');
            is($rows->[0][0], 42, 'init_command: variable set by init_command');
            EV::break;
        });
    },
);

# Test 14-15: charset option
with_mysql(
    charset => 'utf8mb4',
    cb => sub {
        ok($m->character_set_name =~ /utf8mb4/i, 'charset option: utf8mb4 set');
        $m->q("select '✓'", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'charset option: utf8mb4 query works');
            EV::break;
        });
    },
);

# Test 16: skip_pending with only queued (unsent) operations preserves connection
with_mysql(cb => sub {
    $m->q("select 1", sub { });
    $m->q("select 2", sub { });
    $m->skip_pending;
    $m->q("select 'survived'", sub {
        my ($rows, $err) = @_;
        is($rows->[0][0], 'survived', 'skip_pending then query: works');
        EV::break;
    });
});

# Test 17: prepare() queued from a callback while another query is queued succeeds in FIFO order
with_mysql(cb => sub {
    my @order;
    $m->q("select 1", sub {
        $m->q("select 2", sub {
            push @order, 'q2';
            $m->prepare("select ?", sub {
                my ($stmt, $err) = @_;
                push @order, (!$err && $stmt ? 'prep_ok' : 'prep_err');
                $m->close_stmt($stmt, sub {
                    is_deeply(\@order, ['q2', 'q3', 'prep_ok'],
                        'prepare queued while query pending: runs cleanly in FIFO order');
                    EV::break;
                }) if $stmt;
                EV::break unless $stmt;
            });
        });
        $m->q("select 3", sub {
            push @order, 'q3';
        });
    });
});

# Test 18: ping() queued from a callback while another query is queued succeeds in FIFO order
with_mysql(cb => sub {
    my @order;
    $m->q("select 1", sub {
        $m->q("select 2", sub {
            push @order, 'q2';
            $m->ping(sub {
                my ($ok, $err) = @_;
                push @order, ($ok && !$err ? 'ping_ok' : 'ping_err');
                is_deeply(\@order, ['q2', 'q3', 'ping_ok'],
                    'ping queued while query pending: runs cleanly in FIFO order');
                EV::break;
            });
        });
        $m->q("select 3", sub {
            push @order, 'q3';
        });
    });
});

# Test 19: skip_pending from callback cancels queued ops cleanly
with_mysql(cb => sub {
    my @results;
    $m->q("select 1", sub {
        $m->q("select 2", sub {
            push @results, 'q2';
            $m->skip_pending;  # Q3's cb fires synchronously here
            push @results, ($m->is_connected ? 'connected' : 'disconnected');
            is_deeply(\@results, ['q2', 'q3_err', 'connected'],
                'skip_pending from callback: cancels remaining queued ops');
            EV::break;
        });
        $m->q("select 3", sub {
            my ($rows, $err) = @_;
            push @results, $err ? 'q3_err' : 'q3_ok';
        });
    });
});
