package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::More;
	Test::More->import();
    };
    if ($@) {
	print "1..0 # skip Test::More required to test pod coverage.\n";
	exit;
    }
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import();
    };
    if ($@) {
	print <<eod;
1..0 # skip Test::Pod::Coverage 1.00 or greater required.
eod
	exit;
    }
}

all_pod_coverage_ok ({
	also_private => [ qr{^[[:upper:]\d_]+$}, ],
	coverage_class => 'Pod::Coverage::CountParents'
    });

1;
