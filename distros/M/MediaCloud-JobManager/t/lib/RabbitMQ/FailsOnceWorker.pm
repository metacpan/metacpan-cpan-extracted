package RabbitMQ::FailsOnceWorker;

use strict;
use warnings;

use lib qw|lib/ t/lib/ t/lib/RabbitMQ/ t/brokers/|;

use Moose;
with 'RabbitMQ::TestWorker', 'FailsOnceWorker' => { -excludes => [ 'configuration', 'lazy_queue' ], };

no Moose;

__PACKAGE__;
