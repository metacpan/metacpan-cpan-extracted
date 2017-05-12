#!perl
use warnings;
use strict;

use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin/lib";

use ExportTest;
my ($before, $after);
BEGIN { $before = $ExportTest::DONE }
        $after  = $ExportTest::DONE;
ok !$before,    'before eof';
ok  $after,     'after eof';
