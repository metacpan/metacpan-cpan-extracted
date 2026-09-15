#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Framer;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Loop;

{
    package LineConnection;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
}

my $port = shift // 9999;
die "usage: $0 [PORT]\n" if $port !~ /\A\d+\z/ || $port > 65_535;

my $loop = Linux::Event::Loop->new;
my $messages = 0;
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => $port,
    stream => {
        class => 'LineConnection',
        on_message => sub ($stream, $message) {
            $messages++;
            say "message $messages: $message";
            $stream->send($message);
        },
        on_error => sub ($stream, $error) {
            warn "connection error: $error\n";
        },
    },
);

say 'listening on 127.0.0.1:' . $listener->port;
$loop->run;
