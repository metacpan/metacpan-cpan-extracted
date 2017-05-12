package RabbitMQ::FailsAlwaysWorker;

use strict;
use warnings;

use lib qw|lib/ t/lib/ t/lib/RabbitMQ/ t/brokers/|;

use Moose;
with 'RabbitMQ::TestWorker', 'FailsAlwaysWorker' => { -excludes => [ 'configuration', 'lazy_queue' ], };

no Moose;

__PACKAGE__;
