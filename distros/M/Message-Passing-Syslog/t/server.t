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

ok scalar(@msgs);

delete $msgs[0]->{message_raw};
delete $msgs[0]->{datetime_raw};
my $time = delete $msgs[0]->{epochtime};
like $time, qr/^\d+$/;

is_deeply \@msgs, [
    {
        preamble        => '155',
        priority        => 'err',
        priority_int    => 3,
        facility        => 'local3',
        facility_int    => 152,
        host_raw        => '127.0.1.1',
        host            => '127.0.1.1',
        domain          => undef,
        program_raw     => 'progname',
        program_name    => 'progname',
        program_sub     => undef,
        program_pid     => undef,
        content         => 'foo',
        message         => 'progname: foo',
        received_from   => $host,
    }
];

done_testing;

