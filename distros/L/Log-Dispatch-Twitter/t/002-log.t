#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Log::Dispatch;
use Log::Dispatch::Twitter;

my @calls;
do {
    no warnings 'redefine';
    *Log::Dispatch::Twitter::_post_message = sub {
        push @calls, $_[1];
    };
};

my $logger = Log::Dispatch->new;

$logger->add(Log::Dispatch::Twitter->new(
    username  => "dummy",
    password  => "dummy",
    min_level => "debug",
    name      => "twitter",
));

is_deeply([splice @calls], [], "no updates yet");

$logger->info("Test!");
is_deeply([splice @calls], ["Test!"], "posting an update");

$logger->info("This is a test to make sure messages get truncated at one-hundred forty characters. It's the Twitter limit; not much I can do about it. Should I warn if you pass a too-long message? I don't think that your logging software should log messages though. :/ Oh, I'm well over 140. Nice chatting with you.");
is_deeply([splice @calls], ["This is a test to make sure messages get truncated at one-hundred forty characters. It's the Twitter limit; not much I can do about it. Should I warn if you pass a too-long message? I don't think that your logging software should log messages though. :/ Oh, I'm well over 140. Nice chatting with you."], "long messages are NOT truncated at 140 characters");

