#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

$| = 1;

my $port = $ARGV[0] || 8080;
my $ctx  = EV::Websockets::Context->new();
my %rooms;

my $actual_port = $ctx->listen(
    port => $port,
    on_handshake => sub {
        my ($headers) = @_;
        my $auth = $headers->{Authorization} // $headers->{Cookie};
        return undef unless $auth;
        return {};
    },
    on_connect => sub {
        my ($c, $headers) = @_;
        my $path = $headers->{Path} // '/lobby';
        $path =~ s{^/}{};
        my $room = $path || 'lobby';

        my $auth = $headers->{Authorization} // $headers->{Cookie} // '';
        my $nick = $auth =~ /Bearer\s+(\S+)/ ? $1
                 : $auth =~ /nick=(\S+)/     ? $1
                 : $c->peer_address // 'anon';

        $c->stash->{room} = $room;
        $c->stash->{nick} = $nick;
        $rooms{$room}{"$c"} = $c;

        my $count = scalar keys %{$rooms{$room}};
        print "[$room] $nick joined ($count connected)\n";
        broadcast($room, "* $nick joined ($count in room)");
    },
    on_message => sub {
        my ($c, $data) = @_;
        my $room = $c->stash->{room};
        my $nick = $c->stash->{nick};
        print "[$room] <$nick> $data\n";
        broadcast($room, "<$nick> $data");
    },
    on_close => sub {
        my ($c) = @_;
        my $room = $c->stash->{room} // return;
        my $nick = $c->stash->{nick};
        delete $rooms{$room}{"$c"};
        my $count = scalar keys %{$rooms{$room}};
        delete $rooms{$room} unless $count;
        print "[$room] $nick left ($count remaining)\n";
        broadcast($room, "* $nick left ($count in room)") if $count;
    },
    on_error => sub {
        my ($c, $err) = @_;
        warn "Error: $err\n";
    },
);

sub broadcast {
    my ($room, $msg) = @_;
    $_->send($msg) for values %{$rooms{$room} // {}};
}

print "Chat server on ws://127.0.0.1:$actual_port\n";
print "Usage: wscat -H 'Authorization: Bearer nick' -c ws://127.0.0.1:$actual_port/lobby\n";
EV::run;
