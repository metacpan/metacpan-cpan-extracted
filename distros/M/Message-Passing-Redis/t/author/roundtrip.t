use strict;
use warnings;
use Test::More;

use AnyEvent;
use Message::Passing::Input::Redis;
use Message::Passing::Output::Redis;
use Message::Passing::Output::Test;

my $cv = AnyEvent->condvar;
my $input = Message::Passing::Input::Redis->new(
    hostname => "127.0.0.1",
    topics => "log_stash.test",
    output_to => Message::Passing::Output::Test->new(
        cb => sub { $cv->send }
    ),
);

my $output = Message::Passing::Output::Redis->new(
    topic => "log_stash.test",
    hostname => "127.0.0.1",
);

my $this_cv = AnyEvent->condvar;
my $timer; $timer = AnyEvent->timer(after => 2, cb => sub {
    undef $timer;
    $this_cv->send;
});
$this_cv->recv;
$output->consume('bar');
$cv->recv;

is $input->output_to->message_count, 1;
is_deeply([$input->output_to->messages], ['bar']);

my $other_output = Message::Passing::Output::Redis->new(
    topic => "log_stash.foo",
    hostname => "127.0.0.1",
);

$cv = AnyEvent->condvar;
my $other_input = Message::Passing::Input::Redis->new(
    ptopics => "log_stash.*",
    output_to => Message::Passing::Output::Test->new(
        cb => sub { $cv->send }
    ),
    hostname => "127.0.0.1",
);

$this_cv = AnyEvent->condvar;
$timer = AnyEvent->timer(after => 2, cb => sub {
    undef $timer;
    $this_cv->send;
});
$this_cv->recv;
$timer = AnyEvent->timer(after => 10, cb => sub {
    undef $timer;
    fail "Timed out";
    $cv->throw;
});
$output->consume('quux');
$other_output->consume('fnord');
$cv->recv;

is $input->output_to->message_count, 2;
is_deeply([$input->output_to->messages], ['bar', 'quux']);

is $other_input->output_to->message_count, 2;
is_deeply([$other_input->output_to->messages], ['quux', 'fnord']);

done_testing;

