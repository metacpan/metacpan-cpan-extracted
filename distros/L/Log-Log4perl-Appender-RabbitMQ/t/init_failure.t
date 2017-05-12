#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Output qw/stderr_like/;
use Log::Log4perl;

# Test that the right thing happens if the
# appender has a problem during initialization.

# Use Test::Net::RabbitMQ so we can replace the connect method
use Test::Net::RabbitMQ;
{
    # replace the connect method with one that dies to simulate an error.
    no warnings 'redefine';
    *Test::Net::RabbitMQ::connect = sub { die "DEATH!" };
}

my $conf = <<CONF;
    log4perl.category.cat1 = INFO, RabbitMQ

    log4perl.appender.RabbitMQ=Log::Log4perl::Appender::RabbitMQ

    # turn on testing mode, so that we won't really try to
    # connect to a RabbitMQ, but will use Test::Net::RabbitMQ instead
    log4perl.appender.RabbitMQ.TESTING=1

    log4perl.appender.RabbitMQ.layout=SimpleLayout
CONF

stderr_like { Log::Log4perl->init(\$conf) } qr/DEATH!/, "Exception in appender creation printed to STDERR";

pass("Exception in appender creation caught.");
