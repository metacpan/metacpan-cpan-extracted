#!/usr/bin/env perl

use strict;
use warnings;

use Log::Dispatch;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use WWW::Mechanize;

my $mech  = WWW::Mechanize->new;
my $debug = debug_ua($mech);
$debug->pretty(0);

my $log_dispatch = Log::Dispatch->new(
    outputs => [
        [ 'File',   min_level => 'debug', filename => 'log_file.txt' ],
        [ 'Screen', min_level => 'debug' ],
    ],
);

$debug->logger($log_dispatch);

$mech->get('http://www.nytimes.com');
