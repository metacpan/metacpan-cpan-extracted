#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Handler::Output::Gearman;

my $logger = Log::Handler::Output::Gearman->new( servers => ['127.0.0.1'], worker => 'logger' );

for ( 1 .. 20 ) {
    $logger->log("Hi, I am the log message number ${_}!");
}
