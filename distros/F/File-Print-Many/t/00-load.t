#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('File::Print::Many') || print 'Bail out!';
}

require_ok('File::Print::Many') || print 'Bail out!';

diag("Testing File::Print::Many $File::Print::Many::VERSION, Perl $], $^X");
