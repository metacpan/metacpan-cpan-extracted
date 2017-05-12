#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Log::Log4perl;

# Test the appened in an end-to-end fashion
# by just setting up in the config and making
# sure the right stuff gets sent to RabbitMQ
# when we log.

my $conf = <<CONF;
    log4perl.category.cat1 = INFO, RabbitMQ

    log4perl.appender.RabbitMQ=Log::Log4perl::Appender::RabbitMQ

    # turn on testing mode, so that we won't really try to
    # connect to a RabbitMQ, but will use Test::Net::RabbitMQ instead
    log4perl.appender.RabbitMQ.TESTING=1

    log4perl.appender.RabbitMQ.declare_exchange=1
    log4perl.appender.RabbitMQ.exchange=myexchange
    log4perl.appender.RabbitMQ.routing_key=myqueue

    log4perl.appender.RabbitMQ.layout=PatternLayout
    log4perl.appender.RabbitMQ.layout.ConversionPattern=%p>%m%n
CONF

Log::Log4perl->init(\$conf);

# Get the appender Object
my $appender = Log::Log4perl->appenders->{RabbitMQ};#DEBUG#

isa_ok($appender, 'Log::Log4perl::Appender', 'RabbitMQ appender');

# Get the RabbitMQ object and open a second channel to
# consume the messages off of.
my $mq = $appender->{appender}->_connect_cached();
$mq->channel_open(2);
$mq->queue_declare(2, "myqueue");
$mq->queue_bind(2, "myqueue", "myexchange", "myqueue");
$mq->consume(2, "myqueue");

# Make sure the exchange got declared
ok($mq->_get_exchange("myexchange"), "declare_exchange respected");

# Do some logging, checking the queue after each
my $logger = Log::Log4perl->get_logger('cat1');

$logger->debug("debugging message 1 ");
ok(! defined $mq->recv(), "debug lvl ignored as per config");

$logger->info("info message 1 ");
is_deeply(
    $mq->recv(),
    {
        body         => "INFO>info message 1 \n",
        routing_key  => 'myqueue',
        exchange     => 'myexchange',
        delivery_tag => 1,
        consumer_tag => '',
        props        => {},
        redelivered  => 0,
    },
    "info message sent to Rabbit with proper format");

$logger->warn("warning message 1 ");
is_deeply(
    $mq->recv(),
    {
        body         => "WARN>warning message 1 \n",
        routing_key  => 'myqueue',
        exchange     => 'myexchange',
        delivery_tag => 2,
        consumer_tag => '',
        props        => {},
        redelivered  => 0,
    },
    "warn message sent to Rabbit with proper format");
