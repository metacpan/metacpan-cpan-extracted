use strict;
use warnings;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";

use Test::More;

BEGIN {
    plan skip_all => "Broken currently";
    plan skip_all => 'Need Log::Message::Structured'
        unless do { local $@; eval { require Log::Message::Structured } };
}

use JSON qw/ decode_json /;
use TestStorage;
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
$log->warn(TestStorage->new(foo => "bar"));

is $test->message_count, 1;
my ($msg) = $test->messages;
my $data = decode_json(delete($msg->{message}));
is_deeply $msg, {level => 'warn', name => 'myapp_logstash'};
is $data->{__CLASS__}, 'TestStorage';

done_testing;

