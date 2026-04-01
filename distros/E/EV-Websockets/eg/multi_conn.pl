#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# A script managing multiple concurrent connections
# Usage: perl eg/multi_conn.pl [url1] [url2] ...

my @urls = @ARGV ? @ARGV : (
    'wss://ws.postman-echo.com/raw',
    'wss://ws.postman-echo.com/raw',
);

my $ctx = EV::Websockets::Context->new();
my %conns;
my $active_count = 0;

for my $i (0..$#urls) {
    my $url = $urls[$i];
    my $name = "Conn-$i";
    
    print "Starting $name to $url...
";
    $active_count++;
    
    $conns{$name} = $ctx->connect(
        url => $url,
        on_connect => sub {
            my ($c) = @_;
            print "[$name] Connected.
";
            $c->send("Message from $name");
        },
        on_message => sub {
            my ($c, $data) = @_;
            print "[$name] Received: $data
";
            $c->close(1000, "Done");
        },
        on_close => sub {
            print "[$name] Closed.
";
            $active_count--;
            EV::break if $active_count <= 0;
        },
        on_error => sub {
            my ($c, $err) = @_;
            warn "[$name] Error: $err
";
            $active_count--;
            EV::break if $active_count <= 0;
        },
    );
}

print "All connections initiated. Waiting for events...
";
EV::run;
print "All connections finished.
";
