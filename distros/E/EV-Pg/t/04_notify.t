use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 6;

my @notifications;

with_pg(
    on_notify => sub {
        my ($channel, $payload, $pid) = @_;
        push @notifications, { channel => $channel, payload => $payload, pid => $pid };
    },
    cb => sub {
        my ($pg) = @_;

        $pg->query("listen test_channel", sub {
            my ($res, $err) = @_;
            ok(!$err, 'LISTEN succeeded');

            # Send notification via same connection.
            # The notification arrives in the same read as the NOTIFY response,
            # and drain_notifies runs before process_results, so it's already
            # in @notifications when this callback fires.
            $pg->query("notify test_channel, 'hello_payload'", sub {
                my ($res2, $err2) = @_;
                ok(!$err2, 'NOTIFY succeeded');

                ok(scalar @notifications >= 1, 'received notification');
                is($notifications[0]{channel}, 'test_channel', 'correct channel');
                EV::break;
            });
        });
    },
);

# DESTROY from on_notify callback (exercises drain_notifies magic check)
{
    my $notify_fired = 0;
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_notify => sub {
            $notify_fired++;
            undef $pg;  # triggers DESTROY
            EV::break;
        },
        on_connect => sub {
            $pg->query("listen destroy_chan", sub {
                my (undef, $err) = @_;
                die $err if $err;
                $pg->query("notify destroy_chan", sub {});
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($notify_fired, 'on_notify fired before DESTROY');
    ok(!defined $pg, 'DESTROY from on_notify did not crash');
}
