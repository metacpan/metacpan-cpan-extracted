#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use HTTP::Request;
use HTTP::Response;
use Time::HiRes;

BEGIN { use_ok('LWP::UserAgent::Throttled') }

# Create an instance of the throttled user agent
my $ua = new_ok('LWP::UserAgent::Throttled');

# Test throttle setting
$ua->throttle({ 'www.example.com' => 1 });
is($ua->throttle('www.example.com'), 1, 'Throttle time set correctly');
is($ua->throttle('www.nonexistent.com'), 0, 'Default throttle time for unconfigured host is 0');

# Test daisy-chaining throttle
$ua->throttle({ 'test.com' => 0.5 })->throttle({ 'www.example.com' => 2 });
is($ua->throttle('test.com'), 0.5, 'Daisy-chained throttle time set correctly');
is($ua->throttle('www.example.com'), 2, 'Throttle time for second host set correctly');

# Mock an HTTP request and test throttling
my $request1 = HTTP::Request->new(GET => 'http://www.example.com/page1.html');
my $request2 = HTTP::Request->new(GET => 'http://www.example.com/page2.html');

my $start_time = Time::HiRes::time();
$ua->send_request($request1);
my $mid_time = Time::HiRes::time();
$ua->send_request($request2);
my $end_time = Time::HiRes::time();

cmp_ok(($mid_time - $start_time), '<', 1, 'First request sent immediately');
cmp_ok(($end_time - $mid_time), '>=', 2, 'Second request throttled correctly');

# Test user agent assignment
my $custom_ua = new_ok('LWP::UserAgent');
$ua->ua($custom_ua);
is($ua->ua(), $custom_ua, 'Custom user agent set correctly');
