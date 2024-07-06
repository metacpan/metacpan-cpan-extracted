#!/usr/bin/perl -w

use strict;
use warnings;
use Test::Most;
use Test::Needs 'Test::Synopsis';

if($ENV{AUTHOR_TESTING}) {
	Test::Synopsis->import();
	all_synopsis_ok();
} else {
	plan(skip_all => 'Author tests not required for installation');
}
