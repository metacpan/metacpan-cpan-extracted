#!/usr/bin/perl

use strict;
use warnings;

use JSPL;

my $rt = JSPL->create_runtime();
my $cx = $rt->create_context();

$cx->eval(q!
    function main() {
	return [200, "Ok", ['Content-Type', 'text/html'],
	        function() {
		    return "Hello World"
		}]
    }
!);

my $result = $cx->call('main');
print $result->[3]->();
