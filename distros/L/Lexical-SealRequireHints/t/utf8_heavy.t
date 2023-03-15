use warnings;
use strict;

BEGIN {
	if("$]" < 5.006001) {
		require Test::More;
		Test::More::plan(skip_all =>
			"this Perl can't parse this test script");
	}
}

use Test::More tests => 6;

our @warnings;
BEGIN {
	$^W = 1;
	$SIG{__WARN__} = sub { push @warnings, $_[0] };
}

BEGIN {
	ok "\x{666}" =~ /\A\p{Digit}\z/;
	ok "\x{676}" !~ /\A\p{Digit}\z/;
}

BEGIN { use_ok "Lexical::SealRequireHints"; }

BEGIN {
	ok "\x{666}" !~ /\A\p{Alpha}\z/;
	ok "\x{676}" =~ /\A\p{Alpha}\z/;
}

is_deeply \@warnings, [];

1;
