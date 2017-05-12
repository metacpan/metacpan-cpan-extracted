#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

say 'START';

sub re_hw {
	return sub {
		say 'hello';
		my @fonts = (
			[ Helvetica => 14 ],
			{ 'Luxi Sans' => 13 },
		);
		say @fonts;
		say 'world';
		}
}

my $hw = re_hw();
&$hw;

say 'END';

1;

__END__
