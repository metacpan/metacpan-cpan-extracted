#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use utf8;

use FindBin qw($Bin);

use Locale::Simple;

eval {
	ltd('test');
};

like($@,qr/please set a locale directory/,"Checking for proper error on not set l_dir with ltd");

eval {
	l('test');
};

like($@,qr/please set a locale directory/,"Checking for proper error on not set l_dir with l");

l_nolocales(1);
eval {
	ltd('test');
	l('test');
};

is($@,'',"Checking for proper preventing of error with l_nolocales");

done_testing;
