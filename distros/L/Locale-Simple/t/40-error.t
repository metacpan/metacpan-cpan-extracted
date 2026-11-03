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

# Dry-run mode lifts the check for ltd as well, and leaving it brings the
# check back; python/test.py checks the same.
l_nolocales(0);
l_dry('unused.po',1);
eval { ltd('test') };
is($@,'',"dry-run mode lifts the l_dir check for ltd");

l_dry(undef);
eval { ltd('test') };
like($@,qr/please set a locale directory/,"leaving dry-run mode brings the check back for ltd");

# A locale directory named "0" counts as set, as in python/test.py.
{
	require Cwd;
	require File::Temp;
	my $cwd = Cwd::getcwd();
	chdir File::Temp::tempdir( CLEANUP => 1 ) or die $!;
	mkdir '0' or die $!;
	l_dir('0');
	my $got = eval { l('Hello') };
	chdir $cwd or die $!;
	is($got,'Hello','a locale directory named "0" counts as set');
}

done_testing;
