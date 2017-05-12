#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture_merged';

use Test::More;

# -------------

my($program_name)		= 'bin/timeline.pl';
my($merged, @result)	= capture_merged{system($^X, $program_name, '-h')};

ok($merged =~ /validate_gedcom_file/, "$program_name displayed help correctly");

done_testing;
