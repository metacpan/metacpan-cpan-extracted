use strict;
use warnings;

use Test::More;
use lib qw|lib/ t/lib/ t/brokers/|;

require 'broker-tests.inc.pl';

use IO::Socket::INET;

# Test workers
use RabbitMQ::ReverseStringWorker;
use RabbitMQ::FailsAlwaysWorker;
use RabbitMQ::FailsOnceWorker;
use RabbitMQ::FailsOnceWillRetryWorker;

sub _rabbitmq_is_started()
{
    my $socket = IO::Socket::INET->new(
        PeerAddr => 'localhost',
        PeerPort => 5672,
        Proto    => 'tcp',
        Type     => SOCK_STREAM
    );
    if ( $socket )
    {
        close( $socket );
        return 1;
    }
    else
    {
        return 0;
    }
}

sub main()
{
    unless ( _rabbitmq_is_started() )
    {
        plan skip_all => "'rabbitmq-server' is not started";
    }
    else
    {
        plan tests => 18;

        run_tests( 'RabbitMQ' );

        Test::NoWarnings::had_no_warnings();
    }
}

main();
