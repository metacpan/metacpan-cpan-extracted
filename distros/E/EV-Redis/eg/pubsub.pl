#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $sub = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Subscriber error: @_\n" },
);

my $pub = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Publisher error: @_\n" },
);

$sub->subscribe('events', sub {
    my ($msg, $err) = @_;
    return warn "Subscribe error: $err\n" if $err;

    if ($msg->[0] eq 'subscribe') {
        print "Subscribed to '$msg->[1]'\n";
        # publish some messages
        for my $i (1..3) {
            $pub->publish('events', "message $i");
        }
        # unsubscribe after a short delay
        my $w; $w = EV::timer 0.5, 0, sub {
            undef $w;
            $sub->unsubscribe('events');
        };
    }
    elsif ($msg->[0] eq 'message') {
        print "Received on '$msg->[1]': $msg->[2]\n";
    }
    elsif ($msg->[0] eq 'unsubscribe') {
        print "Unsubscribed from '$msg->[1]'\n";
        $sub->disconnect;
        $pub->disconnect;
    }
});

EV::run;
