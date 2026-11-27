#!/usr/bin/env perl
# Event sourcing - JetStream as append-only event log with replay
# Requires: nats-server -js
use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use JSON::PP ();

my $mode = shift || 'both'; # 'produce', 'replay', or 'both'

my @events = (
    { type => 'user.created',  data => { id => 1, name => 'Alice' } },
    { type => 'user.created',  data => { id => 2, name => 'Bob' } },
    { type => 'order.placed',  data => { id => 101, user_id => 1, amount => 42.50 } },
    { type => 'user.updated',  data => { id => 1, name => 'Alice Smith' } },
    { type => 'order.placed',  data => { id => 102, user_id => 2, amount => 18.00 } },
    { type => 'order.shipped', data => { id => 101, tracking => 'TRK123' } },
);

my ($nats, $js);
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        $js = EV::Nats::JetStream->new(nats => $nats);
        $js->stream_create({
            name      => 'EVENTS',
            subjects  => ['events.>'],
            retention => 'limits',
            max_age   => 3600_000_000_000, # 1 hour in nanoseconds
        }, sub {
            my ($info, $err) = @_;
            warn "stream: $err\n" if $err && $err !~ /already/;
            return produce() if $mode eq 'produce';
            return replay()  if $mode eq 'replay';
            produce(\&replay);
        });
    },
);

sub produce {
    my ($then) = @_;
    my $left = @events;
    for my $event (@events) {
        $js->js_publish("events.$event->{type}",
            JSON::PP::encode_json({ %$event, timestamp => time }), sub {
                my ($ack, $err) = @_;
                print $err ? "publish failed: $err\n"
                           : "published: seq=$ack->{seq} $event->{type}\n";
                return if --$left;
                return $then->() if $then;
                $nats->disconnect;
                EV::break;
            });
    }
}

# An ephemeral pull consumer delivers the whole stored log from the start.
sub replay {
    print "\n--- replaying event log ---\n";
    $js->consumer_create('EVENTS', {
        deliver_policy     => 'all',
        ack_policy         => 'none',
        inactive_threshold => 30_000_000_000,
    }, sub {
        my ($info, $err) = @_;
        die "consumer: $err\n" if $err;
        fetch_all($info->{name}, {});
    });
}

sub fetch_all {
    my ($consumer, $state) = @_;
    $js->fetch('EVENTS', $consumer, { batch => 100, no_wait => 1 }, sub {
        my ($msgs, $err) = @_;
        die "fetch: $err\n" if $err;
        apply($state, JSON::PP::decode_json($_->{payload})) for @$msgs;
        return fetch_all($consumer, $state) if @$msgs == 100;
        report($state);
        $nats->disconnect;
        EV::break;
    });
}

sub apply {
    my ($state, $event) = @_;
    my ($type, $d) = @$event{qw(type data)};
    if ($type eq 'user.created') {
        $state->{users}{ $d->{id} } = $d;
        print "  +user: $d->{name}\n";
    } elsif ($type eq 'user.updated') {
        $state->{users}{ $d->{id} } = { %{ $state->{users}{ $d->{id} } || {} }, %$d };
        print "  ~user: $d->{name}\n";
    } elsif ($type eq 'order.placed') {
        $state->{orders}{ $d->{id} } = $d;
        print "  +order: #$d->{id} \$$d->{amount}\n";
    } elsif ($type eq 'order.shipped') {
        $state->{orders}{ $d->{id} }{tracking} = $d->{tracking};
        print "  ~order: #$d->{id} shipped\n";
    }
}

sub report {
    my ($state) = @_;
    my ($users, $orders) = ($state->{users} || {}, $state->{orders} || {});
    print "\n--- aggregate state ---\nusers:\n";
    printf "  %d: %s\n", $_, $users->{$_}{name} for sort { $a <=> $b } keys %$users;
    print "orders:\n";
    for my $oid (sort { $a <=> $b } keys %$orders) {
        my $o = $orders->{$oid};
        printf "  %d: \$%.2f user=%d %s\n", $oid, $o->{amount}, $o->{user_id},
            $o->{tracking} ? "(shipped: $o->{tracking})" : "(pending)";
    }
}

EV::run;
