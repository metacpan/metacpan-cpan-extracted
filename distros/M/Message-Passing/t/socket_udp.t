use strict;
use warnings;
no warnings 'once';
use Test::More;

use AnyEvent;
use Message::Passing::Output::Test;
use Message::Passing::Input::Socket::UDP;
use Message::Passing::Output::Socket::UDP;

plan skip_all => "Need Net::Statsd for this test"
    unless eval { require Net::Statsd; 1; };

my $t = Message::Passing::Output::Test->new;
my $chain = Message::Passing::Input::Socket::UDP->new(
    hostname => "localhost",
    port => "52552",
    output_to => $t,
);

$Net::Statsd::PORT = 52552;

is $t->message_count, 0;

Net::Statsd::increment('site.logins');

my $cv = AnyEvent->condvar;
my $timer = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
$cv->recv;

is $t->message_count, 1;

my $out = Message::Passing::Output::Socket::UDP->new(
    hostname => "localhost",
    port => '52552',
);

$cv = AnyEvent->condvar;
$timer = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
$cv->recv;

$out->consume("foo:bar");

$cv = AnyEvent->condvar;
$timer = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
$cv->recv;

is $t->message_count, 2;

is_deeply [$t->messages],
     [
          'site.logins:1|c',
          'foo:bar'
        ];

done_testing;

