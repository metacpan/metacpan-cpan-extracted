#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Memphis;

exit main() unless caller;


sub main {
	my $data_pool = Memphis::DataPool->new();
	isa_ok($data_pool, 'Memphis::DataPool');
	return 0;
}
