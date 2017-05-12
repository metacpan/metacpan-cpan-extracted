#!/usr/bin/env perl

use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use WWW::Mechanize;

my $mech  = WWW::Mechanize->new;
my $debug = debug_ua($mech);

$debug->dump_content(0);
$debug->dump_cookies(0);
$debug->dump_params(0);
$debug->dump_text(0);

$mech->get('http://www.nytimes.com');
