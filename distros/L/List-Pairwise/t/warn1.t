use strict;
use warnings;
use Test::More;

BEGIN {
	unless ($::NO_PLAN) {
		@::warn = ();
		$SIG{__WARN__} = sub {push @::warn, @_};
	}
}

use List::Pairwise qw(pair);

unless ($::NO_PLAN) {
	plan tests => 1;
	pair (1..10);
	is("@::warn", '', 'no warnings for $a and $b when not used in module');
}