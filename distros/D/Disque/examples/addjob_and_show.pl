#!/usr/bin/perl

use strict;
use warnings;
use Disque;

my $disque = Disque->new();

my $random = int(rand(9999));
my $job_id = $disque->add_job("test","$random", 0);
my @job_status = $disque->show($job_id);

foreach (@job_status) {
	print $_."\n";
}
