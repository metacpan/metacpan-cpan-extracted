use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 12;

# Test that objects are properly cleaned up
{
    {
        my $pg = EV::Pg->new(on_error => sub {});
        ok(defined $pg, 'object created');
    }
    # $pg goes out of scope - DESTROY should be called
    ok(1, 'object destroyed without crash');
}

# Test destruction with active connection
{
    my $done = 0;
    {
        my $pg = EV::Pg->new(
            conninfo   => $conninfo,
            on_connect => sub { $done = 1; EV::break },
            on_error   => sub { $done = 1; EV::break },
        );
        my $t = EV::timer(5, 0, sub { EV::break });
        EV::run;
    }
    ok($done, 'connected then destroyed without crash');
}

# Test destruction with pending query callback
{
    my $pg;
    my $destroyed = 0;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            $pg->query("select 1", sub {
                undef $pg;  # destroy inside callback
                $destroyed = 1;
                EV::break;
            });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($destroyed, 'destroyed inside query callback without crash');
}

# Test handler cleanup (set and unset)
{
    my $pg = EV::Pg->new(on_error => sub {});
    my $called = 0;
    $pg->on_connect(sub { $called++ });
    $pg->on_notify(sub { $called++ });
    $pg->on_notice(sub { $called++ });
    # Clear handlers
    $pg->on_connect(undef);
    $pg->on_notify(undef);
    $pg->on_notice(undef);
    ok(1, 'handler set/unset without leak');
}

# Test finish with pending callbacks
{
    my $pg;
    my $err_count = 0;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            $pg->query("select pg_sleep(10)", sub {
                my ($rows, $err) = @_;
                $err_count++ if $err;
            });
            $pg->finish;
            EV::break;
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($err_count == 1, 'finish cancels pending callbacks cleanly');
}

# LISTEN / NOTIFY round-trip with handler set/unset
{
    my $got = 0;
    my $pg;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_notify  => sub { $got++; EV::break },
        on_connect => sub {
            $pg->query("listen leak_chan", sub {
                $pg->query("notify leak_chan, 'payload'", sub {});
            });
        },
        on_error => sub { diag "err: $_[0]"; EV::break },
    );
    $pg->keep_alive(1);
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $pg->on_notify(undef);  # release handler before destroy
    ok($got >= 1, 'notify round-trip without leak');
}

# Notice receiver: reset role with a notice-emitting plpgsql block
{
    my $pg;
    my $notices = 0;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_notice  => sub { $notices++ },
        on_connect => sub {
            $pg->query("do \$\$ begin raise notice 'hi'; end \$\$", sub {
                EV::break;
            });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($notices >= 1, 'notice receiver fired without leak');
}

# COPY IN cycle
{
    my $pg;
    my $copied;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            $pg->query("create temp table leak_t (n int)", sub {
                $pg->query("copy leak_t from stdin", sub {
                    my ($d, $e) = @_;
                    if (defined $d && $d eq 'COPY_IN') {
                        $pg->put_copy_data("1\n");
                        $pg->put_copy_data("2\n");
                        $pg->put_copy_end;
                        return;
                    }
                    $copied = $d;
                    EV::break;
                });
            });
        },
        on_error => sub { diag "err: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is($copied, '2', 'COPY IN cycle without leak');
}

# COPY OUT cycle
{
    my $pg;
    my $finished = 0;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            $pg->query("copy (select generate_series(1,3)) to stdout", sub {
                my ($d, $e) = @_;
                if (defined $d && $d eq 'COPY_OUT') {
                    while (1) {
                        my $line = $pg->get_copy_data;
                        last if !defined $line || "$line" eq '-1';
                    }
                    return;
                }
                $finished = 1;
                EV::break;
            });
        },
        on_error => sub { diag "err: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($finished, 'COPY OUT cycle without leak');
}

# Regression: cancel_async cb that drops the only $pg ref while finish()
# is running through cleanup_connection.  Prior to the cleanup_connection
# depth-bump fix this was a use-after-free (8 invalid reads/writes under
# valgrind) because DESTROY would Safefree(self) at depth 0 while
# cleanup_connection was still executing.
SKIP: {
    skip 'requires libpq >= 17', 1 unless EV::Pg->lib_version >= 170000;
    my $pg = EV::Pg->new(conninfo => $conninfo,
                         on_connect => sub { EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    # release closures so $pg holds the only Perl-level ref
    $pg->on_connect(undef);
    $pg->on_error(undef);

    $pg->query("select pg_sleep(30)", sub {});
    $pg->cancel_async(sub { undef $pg });
    $pg->finish;  # used to UAF on the line after CLEANUP_CANCEL
    ok(!defined $pg, 'cancel-cb-drops-pg + finish: no UAF, $pg cleared');
}

# Pipeline cycle with prepared statement
{
    my $pg;
    my @results;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            $pg->prepare('leak_p', 'select $1::int', sub {
                $pg->enter_pipeline;
                $pg->query_prepared('leak_p', [1], sub { push @results, $_[0][0][0] });
                $pg->query_prepared('leak_p', [2], sub { push @results, $_[0][0][0] });
                $pg->pipeline_sync(sub {
                    $pg->exit_pipeline;
                    EV::break;
                });
            });
        },
        on_error => sub { diag "err: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is_deeply(\@results, ['1', '2'], 'pipeline + prepared without leak');
}
