#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 1, todo => [] }

use Devel::PreProcessor qw( Includes StripPods );

open TEST, '>t/tout.pl';
select(TEST);
Devel::PreProcessor::parse_file('t/t1.pl');
select(STDOUT);

my $out = qx! perl t/tout.pl !;

ok( $out =~ /1 -  - 3/ );

