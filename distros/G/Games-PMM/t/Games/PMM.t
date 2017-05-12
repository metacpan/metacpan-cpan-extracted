#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 2;

my $module = 'Games::PMM';
use_ok( $module ) or exit;
ok( $module->VERSION(), "$module should compile and have a version" );
