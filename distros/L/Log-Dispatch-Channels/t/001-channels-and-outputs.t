#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;
use Log::Dispatch::Channels;
use Log::Dispatch::Null;

my $logger = Log::Dispatch::Channels->new;
for my $channel (1..3) {
    $logger->add_channel($channel);
    $logger->add(Log::Dispatch::Null->new(name => $channel,
                                          min_level => 'debug'),
                 channels => $channel);
}

$logger->add(Log::Dispatch::Null->new(name => 'all',
                                      min_level => 'debug'));
$logger->add(Log::Dispatch::Null->new(name => 'one_and_two',
                                      min_level => 'debug'),
             channels => [qw/1 2/]);

for my $channel (1..3) {
    isa_ok($logger->channel($channel), 'Log::Dispatch');
    isa_ok($logger->output($channel),  'Log::Dispatch::Null');
}

isa_ok($logger->channel('1')->output('all'), 'Log::Dispatch::Null');
my $all_output = $logger->output('all');
for my $channel (1..3) {
    is($all_output, $logger->channel($channel)->output('all'),
       "output 'all' is shared with channel $channel");
}

is($logger->channel('3')->output('one_and_two'), undef,
   "output 'one_and_two' isn't added to channel '3'");

$logger->remove('one_and_two');
is($logger->channel('1')->output('one_and_two'), undef,
   "output 'one_and_two' is gone from channel '1'");
is($logger->channel('2')->output('one_and_two'), undef,
   "output 'one_and_two' is gone from channel '2'");
is($logger->output('one_and_two'), undef,
   "output 'one_and_two' is gone after we remove it");
$logger->remove_channel('1');
is($logger->channel('1'), undef,
   "channel '1' is gone after we remove it");
