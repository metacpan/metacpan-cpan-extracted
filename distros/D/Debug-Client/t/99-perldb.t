#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More tests => 1;

BEGIN {
  require "./t/lib/Debugger.pm";
  t::lib::Debugger->import;
}

if (rc_file) {
	diag('');
	diag('***************************************');
	diag('** YOU SEEM TO HAVE A ".perldb" FILE **');
	diag('** IN YOUR HOME DIRECTORY. IF YOU    **');
	diag('** SEE TEST FAILURES, PLEASE MOVE IT **');
	diag('** SOMEWHERE ELSE, TRY AGAIN AND     **');
	diag('** RESTORE IT AFTER INSTALLATION.    **');
	diag('***************************************');
}

ok 1;
