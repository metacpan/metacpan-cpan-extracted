#! /usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Global::MutexLock qw(mutex_create mutex_destory mutex_lock mutex_unlock);

my $mutex_id = $ARGV[0] // 0;
die "usage: ./03_sub_cron.pl LOCKID\n" if (!$mutex_id || $mutex_id !~ /^\d+$/);

my $i = 0;

mutex_unlock($mutex_id);

for(0..10000) {
    mutex_lock($mutex_id);
    print sprintf "%d: from sub cron\n", $i++;
    usleep 100000;
    mutex_unlock($mutex_id);
    usleep 100000;
}
