use strict;
use warnings;
use Test::More;

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

is scalar(@msgs), 1, 'one syslog received';
like $msgs[0]->{epochtime}, qr/^\d+$/;
is $msgs[0]->{content}, 'foo', 'content ok';


done_testing;

