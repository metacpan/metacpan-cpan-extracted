package DMTraceProviderFork;

use strict;
use warnings;

use base 'DMTraceProviderNextMem';

our $forked = 0;

sub forked {
	$forked = 1;
}

1;
