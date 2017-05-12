#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 4;
use Test::Exception;
use Log::Dispatch::Channels;
use Log::Dispatch::ToString;

my $logger = Log::Dispatch::Channels->new;
for my $channel (1..3) {
    $logger->add_channel($channel);
    $logger->add(Log::Dispatch::ToString->new(name => $channel,
                                              min_level => 'debug'),
                 channels => $channel);
}

throws_ok { $logger->log_and_die(channels => 1,
                                 level => 'debug',
                                 message => 'log_and_die') }
          qr/^log_and_die/,
          "log_and_die dies with the proper message";
is($logger->output(1)->get_string, "log_and_die",
   "log_and_die logs the proper message");

throws_ok { $logger->log_and_croak(channels => 2,
                                   level => 'debug',
                                   message => 'log_and_croak') }
          qr/^log_and_croak/,
          "log_and_croak dies with the proper message";
is($logger->output(2)->get_string, "log_and_croak",
   "log_and_croak logs the proper message");
