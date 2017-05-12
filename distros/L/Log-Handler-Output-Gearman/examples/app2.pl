#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Handler;
use Log::Handler::Output::Gearman;
use JSON::XS;

my $json    = JSON::XS->new();
my $logger  = Log::Handler->new();
my $gearman = Log::Handler::Output::Gearman->new(
    servers         => ['127.0.0.1'],
    worker          => 'logger',
);

my %handler_options = (
    maxlevel       => 'debug',
    minlevel       => 'critical',
    timeformat     => '%Y-%m-%d %H:%M:%S',
    message_layout => '%T [%L] [%P] %m',
    die_on_errors  => 0,
);

$logger->add( $gearman => \%handler_options );

for ( 1 .. 20 ) {
    $logger->log( message => "Hi, I am the log message number ${_}!" );
}

