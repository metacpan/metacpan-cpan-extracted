#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use JSON;
use DateTime::Format::RFC3339;
use DateTime;

my $formatter = DateTime::Format::RFC3339->new;
my $json      = JSON->new->convert_blessed(1)->utf8(0);
my $dt        = DateTime->now();

use_ok('DateTimeX::TO_JSON', formatter => $formatter);

my $expected  = $formatter->format_datetime($dt);
my $out       = $json->encode([$dt]); 

is($out, $json->encode([$expected]), 'DateTime can be serialised with class');

done_testing();
