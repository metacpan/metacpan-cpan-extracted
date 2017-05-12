use strict;
use warnings;
use Test::More;

BEGIN {
	unless ($::NO_PLAN) {
		plan(skip_all => '$a and $b warnings exemption') if $]>=5.019006;
		@::warn = ();
		$SIG{__WARN__} = sub {push @::warn, @_};
	}
}

use List::Pairwise ();

unless ($::NO_PLAN) {
	plan tests => 3;
	List::Pairwise::mapp {$a, $b} (1..10);
	ok("@::warn", 'warnings for $a and $b when not used in module but not imported');
	
	for (0, 1) {
		like($::warn[$_], qr/Name "main::([ab])" used only once: possible typo at /, "warning $_");
	}
}
