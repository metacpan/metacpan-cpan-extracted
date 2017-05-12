use strict;
use warnings;
use Test::More;

BEGIN {
    do { local $@; eval { require Net::Syslog } }
        || plan skip_all => "Net::Syslog needed for this test";
}

use Sys::Hostname::Long qw/ hostname_long /;
use Message::Passing::Output::Syslog;
use Message::Passing::Input::Syslog;
use Message::Passing::Output::Callback;
use AnyEvent;

my $cv = AnyEvent->condvar;
my $host = '127.0.0.1';

my $syslog = Message::Passing::Output::Syslog->new(
    hostname => $host,
    port     => '5140',
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
    $syslog->consume("foo");
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
        preamble        => '171',
        priority        => 'err',
        priority_int    => 3,
        facility        => 'local5',
        facility_int    => 168,
        host_raw        => "client.t[$$]:",
        host            => 'client',
        domain          => "t[$$]:",
        program_raw     => undef,
        program_name    => undef,
        program_sub     => undef,
        program_pid     => undef,
        content         => 'foo',
        message         => 'foo',
        received_from   => $host,
    }
];

done_testing;

