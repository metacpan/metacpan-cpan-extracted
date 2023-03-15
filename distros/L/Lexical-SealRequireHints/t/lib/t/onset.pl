use warnings;
use strict;

BEGIN {
	my $v = $^H{"Lexical::SealRequireHints/test"};
	$main::onset_test = defined($v) ? $v : "undef";
}

1;
