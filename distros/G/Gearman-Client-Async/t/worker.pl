#!/usr/bin/perl

use strict;
use Gearman::Worker;
use Getopt::Long;
my $opt_js;
GetOptions('s=s' => \$opt_js);

my $worker = Gearman::Worker->new;
$worker->job_servers(split(/,/, $opt_js));

$worker->register_function("sleep_for" => sub {
    my $job = shift;
    my $arg = $job->arg;

    my $steps = $arg * 4;

    my $res = rand();
    $job->set_status(0, $steps);
    for my $i (1..$steps) {
        select(undef, undef, undef, 0.25);
        $job->set_status($i, $steps);
    }
    return $res;
});

$worker->work while 1;

