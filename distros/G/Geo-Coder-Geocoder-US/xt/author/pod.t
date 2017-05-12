package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::More;
	Test::More->import();
    };
    if ($@) {
	print <<eod;
1..0 # skip Test::More required to test POD validity.
eod
	exit;
    }
    eval {
	require Test::Pod;
	Test::Pod->VERSION (1.00);
	Test::Pod->import();
    };
    if ($@) {
	print <<eod;
1..0 # skip Test::Pod 1.00 or higher required to test POD validity.
eod
	exit;
    }
}

all_pod_files_ok ();

1;
