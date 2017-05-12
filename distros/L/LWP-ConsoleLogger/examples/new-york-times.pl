#!/usr/bin/env perl

use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use WWW::Mechanize;

my $mech   = WWW::Mechanize->new;
my $logger = debug_ua($mech);
$mech->get('http://www.nytimes.com');
