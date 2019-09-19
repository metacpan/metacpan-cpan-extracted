#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::MzQuantML;

chdir $FindBin::Bin;

require_ok ("MS::Reader::MzQuantML");

# check that compressed and uncompressed FHs return identical results
my $fn = 'corpus/test.mzq.gz';

ok (my $p = MS::Reader::MzQuantML->new($fn), "created parser object");

done_testing();
