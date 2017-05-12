package RabbitMQ::TestWorker;

use strict;
use warnings;

use Moose::Role;
with 'MediaCloud::JobManager::Job' => { -excludes => [ 'configuration', 'lazy_queue' ], };

use Data::Dumper;

use MediaCloud::JobManager::Configuration;
use MediaCloud::JobManager::Broker::RabbitMQ;

sub configuration
{
    say STDERR "Using RabbitMQ as a test job broker";

    # Configure TestWorker with RabbitMQ broker
    my $configuration = MediaCloud::JobManager::Configuration->new();
    $configuration->broker( MediaCloud::JobManager::Broker::RabbitMQ->new() );
    return $configuration;
}

sub lazy_queue()
{
    return 1;
}

1;
