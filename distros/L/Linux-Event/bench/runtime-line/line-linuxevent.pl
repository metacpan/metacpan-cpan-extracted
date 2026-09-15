#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../blib/lib", "$Bin/../../blib/arch", "$Bin/../../lib";

use Linux::Event::Loop;
use Linux::Event::Framer;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;

my $host = shift // '127.0.0.1';
my $port = shift // 0;

{
    package Linux::Event::Bench::RuntimeLineStream;
    use v5.36;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";

    sub stream_tuning ($class) {
        return read_size => 65_536;
    }
}

{
    package Linux::Event::Bench::RuntimeLineListener;
    use v5.36;
    use parent 'Linux::Event::IO::Sock::Listener';

    sub on_error ($listener, $error) {
        die "listener error: $error\n";
    }
}

my $loop = Linux::Event::Loop->new;
my $on_message = sub ($stream, $message) {
    $stream->send($message);
};
my $on_error = sub ($stream, $error) {
    warn "stream error: $error\n";
    $stream->close if !$stream->is_closed;
};

my $listener = Linux::Event::Bench::RuntimeLineListener->new(
    loop => $loop,
    host => $host,
    port => 0 + $port,
    backlog => 8192,
    stream => {
        class      => 'Linux::Event::Bench::RuntimeLineStream',
        on_message => $on_message,
        on_error   => $on_error,
    },
);

$| = 1;
print "READY ", $listener->port, "\n";
$loop->run;
