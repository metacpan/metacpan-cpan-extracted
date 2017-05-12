package FailsOnceWillRetryWorker;

use strict;
use warnings;

use Moose::Role;
use lib qw|lib/ t/lib/ t/brokers/|;
with 'MediaCloud::JobManager::Job';

use File::Slurp;

my $second_run;

# Run job
sub run($;$)
{
    my ( $self, $args ) = @_;

    my $result = 42;

    if ( $second_run )
    {
        say STDERR "It's not the first time I'm being run, so not failing today.";

        my $write_results_to = $args->{ write_results_to };

        if ( $write_results_to )
        {
            say STDERR "Will write results to '$write_results_to'";
            unless ( write_file( $write_results_to, $result ) )
            {
                die "Unable to write to file '$write_results_to'";
            }
        }

        return $result;
    }
    else
    {
        $second_run = 1;
        die "It's the first time I'm being run, so I'm failing.";
    }
}

sub retries()
{
    die "This placeholder shouldn't be called.";
}

sub configuration
{
    die "This placeholder shouldn't be called.";
}

sub lazy_queue
{
    die "This placeholder shouldn't be called.";
}

no Moose;    # gets rid of scaffolding

# Return package name instead of 1 or otherwise worker.pl won't know the name of the package it's loading
__PACKAGE__;
