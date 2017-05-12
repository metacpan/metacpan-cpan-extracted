#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IO::Async::Loop;
use IO::AsyncX::EventFD;

my $loop = IO::Async::Loop->new;
my $events = 0;
$loop->add(my $eventfd = new_ok('IO::AsyncX::EventFD' => [ notify => sub { ++$events } ]));
is($events, 0, 'no events after adding');
$loop->loop_once(0.001);
is($events, 0, 'no events yet');
note 'notifying';
is(exception {
	$eventfd->notify;
}, undef, 'no exception from ->notify');
is($events, 0, 'no events yet');
$loop->loop_once(0.001);
is($events, 1, 'have an event after loop iteration');
done_testing;

