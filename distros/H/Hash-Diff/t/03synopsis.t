#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use Hash::Diff qw/diff/;


my %a = ( 
	'foo'    => 1,
    'bar'    => { a => 1, b => 1 },
);
my %b = ( 
	'foo'     => 2, 
	'bar'    => { a => 1 },
);

is_deeply(diff(\%a,\%b),{ foo => 1, bar => { b => 1} }, 'Example working');
