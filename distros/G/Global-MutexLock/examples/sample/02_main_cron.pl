#! /usr/bin/env perl
use strict;
use warnings;
use Global::MutexLock qw(mutex_create mutex_destory mutex_lock mutex_unlock);

my $mutex_id = $ARGV[0] // 0;
die "usage: ./02_main_cron.pl LOCKID\n" if (!$mutex_id || $mutex_id !~ /^\d+$/);

my $i = 0;

mutex_unlock($mutex_id);

for(0..100) {
    mutex_lock($mutex_id);
    print sprintf "%d: from main cron\n", $i++;
    sleep 1;
    mutex_unlock($mutex_id);
    sleep 1;
}
