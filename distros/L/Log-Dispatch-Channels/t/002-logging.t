#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 9;
use Log::Dispatch::Channels;
use Log::Dispatch::ToString;

my $logger = Log::Dispatch::Channels->new;
for my $channel (1..3) {
    $logger->add_channel($channel);
    $logger->add(Log::Dispatch::ToString->new(name => $channel,
                                              min_level => 'debug'),
                 channels => $channel);
}

$logger->add(Log::Dispatch::ToString->new(name => 'all',
                                          min_level => 'debug'));
$logger->add(Log::Dispatch::ToString->new(name => 'error',
                                          min_level => 'error'));
$logger->add(Log::Dispatch::ToString->new(name => 'one_and_two',
                                          min_level => 'info'),
             channels => [qw/1 2/]);

my @messages = (
    "only channel 1\n",
    "it's an error\n",
    "debugging 3\n",
    "channels 1 and 3\n",
    "everywhere\n",
    "2 specific\n",
);
my %should_get = (
    1           => [qw/0 3 4/],
    2           => [qw/1 4 5/],
    3           => [qw/2 3 4/],
    all         => [qw/0 1 2 3 3 4 4 4/],
    error       => [qw/1 2/],
    one_and_two => [qw/1 3/],
);

$logger->log(channels => 1,         message => $messages[0], level => 'debug');
$logger->log(channels => 2,         message => $messages[1], level => 'error');
$logger->log(channels => 3,         message => $messages[2], level => 'error');
$logger->log(channels => [qw/1 3/], message => $messages[3], level => 'info');
$logger->log(                       message => $messages[4], level => 'debug');
$logger->log_to(name => 2,          message => $messages[5], level => 'debug');

for my $output (keys %should_get) {
    my $log = join '', map { $messages[$_] } @{ $should_get{$output} };
    is($logger->output($output)->get_string, $log,
       "output $output received the correct logging calls");
}

ok($logger->would_log('error'),
   "a logger would log messages at 'error'");
$logger->remove('all');
$logger->remove(2);
$logger->remove(3);
ok(!$logger->would_log('debug', channels => [qw/2 3/]),
   "there is no logger left in channel 2 or 3 for debug level messages");
ok(!$logger->would_log('debug', channels => 2),
   "no logger is left on channel 2 to log debug level messages");
