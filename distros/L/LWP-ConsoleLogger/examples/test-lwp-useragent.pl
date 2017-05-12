#!/usr/bin/env perl;

use strict;
use warnings;
use feature qw( say );

use Test::LWP::UserAgent;
use LWP::ConsoleLogger::Easy qw( debug_ua );

my $ua = Test::LWP::UserAgent->new( network_fallback => 1 );
debug_ua($ua);
$ua->get('https://metacpan.org');
