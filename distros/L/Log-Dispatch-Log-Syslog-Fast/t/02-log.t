use strict;
use warnings;

use IO::Select;
use IO::Socket::INET;
use Log::Dispatch;
use Test::More;

# set up a fake syslogd
my $port = 0;
if ($IO::Socket::INET::VERSION < 1.31) {
    $port = int(rand 1<<16) - int(rand 1<<15);
    diag "Using port $port for IO::Socket::INET v$IO::Socket::INET::VERSION";
}

my $localhost = '127.0.0.1';
my $listener = IO::Socket::INET->new(
    Proto       => 'tcp',
    Type        => SOCK_STREAM,
    LocalHost   => $localhost,
    LocalPort   => $port,
    Listen      => 1,
    Reuse       => 1,
) or BAIL_OUT $!;

$port = $listener->sockport;
ok $listener, "listening on $port";

my $log = Log::Dispatch->new(
    outputs => [
        [
            'Log::Syslog::Fast',
            min_level => 'info',
            name      => 'foo',
            transport => 'tcp',
            host      => $listener->sockhost,
            port      => $listener->sockport,
        ]
    ]
);
ok $log, "created logger";

my $receiver = $listener->accept;
$receiver->blocking(0);

sub get_data {
    return unless ok(IO::Select->new($receiver)->can_read(1), "didn't time out waiting for log line");
    $receiver->recv(my $buf, 1024);
    return $buf;
}

{
    my $msg = "Fatal error.";
    $log->error($msg);

    if (my $buf = get_data) {
        like $buf, qr/^<11>/, "priority value is correct" or note $buf;
        like $buf, qr/foo\[$$\]/, "program name/pid is correct" or note $buf;
        like $buf, qr/\Q$msg\E$/, "log message is correct" or note $buf;
    }
}

{
    my $msg = "Warning!";
    $log->warn($msg);

    if (my $buf = get_data) {
        like $buf, qr/^<12>/, "priority value is correct" or note $buf;
        like $buf, qr/foo\[$$\]/, "program name/pid is correct" or note $buf;
        like $buf, qr/\Q$msg\E$/, "log message is correct" or note $buf;
    }
}

done_testing;
