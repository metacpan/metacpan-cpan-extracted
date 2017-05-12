#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 1 }

use Mac::Components;

SKIP: {
#	skip "Mac::Components", 1;

# try to open components, get info from them

	my $count = 0;
	for (my $comp = 0; $comp = FindNextComponent($comp, $ARGV[0]); ) {
		++$count;
	}
	is($count, CountComponents(), 'count components');
}

__END__
