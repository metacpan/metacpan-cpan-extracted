#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async::Loop;
use IO::AsyncX::EventFD;

my $loop = IO::Async::Loop->new;
$loop->add(my $eventfd = IO::AsyncX::EventFD->new(notify => sub {
	warn "Had event\n"
}));
$loop->loop_once(0.001);
warn "Notifying...\n";
$eventfd->notify;
$loop->loop_once(0.001);

