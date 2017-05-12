#!/usr/bin/env perl

use strict;
use warnings;
use Modern::Perl "2012";

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../samples";

use MediaCloud::JobManager;
use MediaCloud::JobManager::Admin;
use NinetyNineBottlesOfBeer;
use Addition;
use AdditionAlwaysFails;
use Data::Dumper;

sub main()
{
    my @job_ids;

    for ( my $x = 1 ; $x < 100 ; ++$x )
    {
        my $job_id = Addition->add_to_queue( { a => 3, b => 5 }, $MediaCloud::JobManager::Job::MJM_JOB_PRIORITY_LOW );
        say STDERR "Job ID: $job_id";
        push( @job_ids, $job_id );
    }

    say STDERR "Waiting for jobs to complete...";
    sleep( 3 );

    for ( my $x = 1 ; $x < 10 ; ++$x )
    {
        my $result = Addition->run_remotely( { a => 3, b => 5 }, $MediaCloud::JobManager::Job::MJM_JOB_PRIORITY_LOW );
        say STDERR "Job result: " . $result;
    }

    # Job doesn't publish results so just add it
    NinetyNineBottlesOfBeer->add_to_queue( { how_many_bottles => 4 } );
}

main();
