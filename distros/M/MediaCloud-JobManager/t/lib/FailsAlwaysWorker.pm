package FailsAlwaysWorker;

use strict;
use warnings;

use Moose::Role;
use lib qw|lib/ t/lib/ t/brokers/|;
with 'MediaCloud::JobManager::Job';

# Run job
sub run($;$)
{
    my ( $self, $args ) = @_;

    die "The FailsAlwaysWorker failed (naturally).";
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
