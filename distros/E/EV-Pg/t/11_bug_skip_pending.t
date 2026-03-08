use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 5;

# Regression: skip_pending from inside a query callback must not
# double-fire the currently-delivering callback.
{
    my $pg;
    my $cb1_count = 0;
    my $cb2_count = 0;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->query("select 1", sub {
                my ($res, $err) = @_;
                $cb1_count++;
                $pg->skip_pending;

                $pg->query("select 2", sub {
                    my ($res2, $err2) = @_;
                    $cb2_count++;
                    EV::break;
                });
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is($cb1_count, 1, 'skip_pending: cb1 called exactly once');
    is($cb2_count, 1, 'skip_pending: cb2 called after re-query');
}

# Regression: finish from inside a query callback must not
# double-fire the currently-delivering callback.
{
    my $pg;
    my $cb_count = 0;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->query("select 1", sub {
                my ($res, $err) = @_;
                $cb_count++;
                $pg->finish;
                EV::break;
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is($cb_count, 1, 'finish in callback: cb called exactly once');
}

# Regression: reset from inside a query callback must not
# double-fire the currently-delivering callback.
{
    my $pg;
    my $cb1_count = 0;
    my $reconnected = 0;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            if ($reconnected) {
                EV::break;
                return;
            }
            $pg->query("select 1", sub {
                my ($res, $err) = @_;
                $cb1_count++;
                $reconnected = 1;
                $pg->reset;
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is($cb1_count, 1, 'reset in callback: cb called exactly once');
    ok($reconnected, 'reset in callback: reconnected');
}
