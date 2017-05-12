#!/usr/bin/perl

use strict;
use warnings;
use Disque;

my $disque = Disque->new(servers => ["localhost:7711", "localhost:7712"]);

# Send time job every second, just for demonstration purpose
while (1) {
    my $t = localtime(time);
    my $queue = "test";
    my $job_msg = "new job at $t";
    $disque->add_job($queue,$job_msg, 0);
    warn "Send job: '$job_msg' $!at queue: '$queue' $!\n";
    sleep(1);
}

$disque->quit();
