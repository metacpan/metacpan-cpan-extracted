#!/usr/bin/env perl
use strict;
use warnings;
use Gearman::XS qw(:constants);
use Gearman::XS::Worker;

my $worker = Gearman::XS::Worker->new();
my $ret = $worker->add_server( '127.0.0.1', 4730 );
if ( $ret != GEARMAN_SUCCESS ) {
    printf( STDERR "%s\n", $worker->error() );
    exit(1);
}

$ret = $worker->add_function( "logger", 0, \&logger, {} );
if ( $ret != GEARMAN_SUCCESS ) {
    printf( STDERR "%s\n", $worker->error() );
}

while (1) {
    my $ret = $worker->work();
    if ( $ret != GEARMAN_SUCCESS ) {
        printf( STDERR "%s\n", $worker->error() );
    }
}

sub logger {
    my ($job) = @_;

    my $workload = $job->workload();

    printf( "Job=%s Function_Name=%s Workload=%s\n", $job->handle(), $job->function_name(), $job->workload() );

    return 1;
}
