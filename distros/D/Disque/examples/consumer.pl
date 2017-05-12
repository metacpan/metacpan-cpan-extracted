#!/usr/bin/perl

use strict;
use warnings;
use Disque;

my $disque = Disque->new(servers => ["localhost:7711", "localhost:7712"]);

while (1) {
    my @jobs = $disque->get_job("test");
    my $queue = shift $jobs[0];
    my $job_id = shift $jobs[0];
    my $job = shift $jobs[0];

    warn "Received job: '$job' $!at queue: '$queue' $!\n";
    $disque->ack_job($job_id);
}

$disque->quit();
