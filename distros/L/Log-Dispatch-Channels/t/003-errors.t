#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 3;
use Log::Dispatch::Channels;
use Log::Dispatch::Null;

my $logger = Log::Dispatch::Channels->new;
for my $channel (1..3) {
    $logger->add_channel($channel);
    $logger->add(Log::Dispatch::Null->new(name => $channel,
                                          min_level => 'debug'),
                 channels => $channel);
}
my $warnings = '';
$SIG{__WARN__} = sub { $warnings .= $_[0] };
$logger->add_channel(1);
like($warnings, qr/^Channel 1 already exists!/,
     "correct warning when replacing a channel");
$warnings = '';
$logger->add(Log::Dispatch::Null->new(name => 1, min_level => 'debug'));
like($warnings, qr/^Output 1 already exists!/,
     "correct warning when replacing an output");

$warnings = '';
$logger->log(channels => 4, message => 'test', level => 'debug');
like($warnings, qr/^Channel 4 doesn't exist/,
     "correct warning when forwarding to a nonexistant channel");
