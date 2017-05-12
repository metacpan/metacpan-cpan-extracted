#!/usr/bin/env perl;

use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use Test::WWW::Mechanize;

my $ua = Test::WWW::Mechanize->new;
debug_ua($ua);
$ua->get('https://metacpan.org');
