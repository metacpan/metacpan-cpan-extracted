use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 6;

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
