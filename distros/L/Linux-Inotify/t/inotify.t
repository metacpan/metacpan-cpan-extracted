#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use File::Temp 'tempdir';
use Linux::Inotify;

my $dir = tempdir(CLEANUP => 1);
my $notifier = Linux::Inotify->new();
my $watch = $notifier->add_watch($dir, Linux::Inotify::ALL_EVENTS);
open TEST, ">$dir/test";
my @events = $notifier->read();
ok(@events == 2, 'count_1');
ok($events[0]->fullname() eq "$dir/test" &&
   $events[0]->{mask} == Linux::Inotify::CREATE &&
   $events[0]->{cookie} == 0,
   'type_create');
ok($events[1]->fullname() eq "$dir/test" &&
   $events[1]->{mask} == Linux::Inotify::OPEN &&
   $events[1]->{cookie} == 0,
   'type_open');
close TEST;
@events = $notifier->read();
ok(@events == 1, 'count_2');
ok($events[0]->fullname() eq "$dir/test" &&
   $events[0]->{mask} == Linux::Inotify::CLOSE_WRITE &&
   $events[0]->{cookie} == 0,
   'type_close_write');

