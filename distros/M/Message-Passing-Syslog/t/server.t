use strict;
use warnings;
use Test::More;

BEGIN {
    do { local $@; eval { require Net::Syslog } }
        || plan skip_all => "Net::Syslog needed for this test";
}

use Message::Passing::Input::Syslog;
use Message::Passing::Output::Callback;
use Net::Syslog;
use AnyEvent;

my $cv = AnyEvent->condvar;
my $host = '127.0.0.1';

my $syslog = Net::Syslog->new(
    SyslogHost => $host,
    SyslogPort => 5140,
    Name       => 'progname',
    Facility   => 'local3',
    Priority   => 'error',
    Pid        => 'undef',
    rfc3164    => 1,
);

my @msgs;
my $l = Message::Passing::Input::Syslog->new(
    output_to => Message::Passing::Output::Callback->new(
        cb => sub {
            push(@msgs, shift());
            $cv->send;
        },
    ),
);

my $idle; $idle = AnyEvent->idle(cb => sub {
    $syslog->send("foo");
    undef $idle;
});

$cv->recv;

is scalar(@msgs), 1, 'one syslog received';
like $msgs[0]->{epochtime}, qr/^\d+$/;
is $msgs[0]->{content}, 'foo', 'content ok';

done_testing;

