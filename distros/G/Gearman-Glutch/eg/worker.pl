#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use lib 'lib';

use Gearman::Glutch;
use Getopt::Long;
use Data::Dumper;

my $worker = Gearman::Glutch->new(
    port => 9999,
    max_workers => 5,
    max_reqs_per_child => 5,
    on_spawn_child => sub {
        warn "Spawned $_[0]";
    },
    on_complete => sub {
        warn "Complete job $$";
    },
);
$worker->register_function("echo", sub {
    my $job = shift;
    $$.":".$job->arg;
});
$worker->run();

