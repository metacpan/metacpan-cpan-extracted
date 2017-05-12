use strict;
use warnings;

use Test::More;

use Log::Dispatch;
use Log::Dispatch::Message::Passing;
use Message::Passing::Output::Test;

my $log = Log::Dispatch->new;

my $test = Message::Passing::Output::Test->new;

$log->add(Log::Dispatch::Message::Passing->new(
    name      => 'myapp_logstash',
    min_level => 'debug',
    output     => $test,
));

$log->warn("foo");

is $test->message_count, 1;
is_deeply [$test->messages], [{level => 'warning', name => 'myapp_logstash', message => 'foo'}];

done_testing;

