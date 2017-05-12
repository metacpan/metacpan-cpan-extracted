#!perl -T
use 5.006;
use strict;
use warnings;
use Capture::Tiny qw(capture);
use Test::More tests => 4;
use Log::Log4Cli;

is(
    log_fd(),
    \*STDERR,
    "STDERR is a file descriptor by default"
);

is(
    log_fd(\*STDOUT),
    \*STDOUT,
    "Set STDOUT as file descriptor"
);

my ($out, $err) = capture { log_fatal { "Text to STDOUT" } };
like($out, qr/] Text to STDOUT$/, "Text must be here" );
is($err, '', 'STDERR must remain clean');
