use strict;
use warnings;
use blib;

use Test::More tests => 34;

BEGIN { use_ok('Mail::SRS'); }
BEGIN { use_ok('Mail::SRS::Guarded'); }
BEGIN { use_ok('Mail::SRS::Reversible'); }
BEGIN { use_ok('Mail::SRS::Shortcut'); }

local $SIG{__WARN__} = sub { };
# We can't test for the presence of the warnings, since it is
# mildly nondeterministic whether one will ever be emitted.

foreach my $subclass (qw(Guarded Reversible Shortcut)) {
	my $class = "Mail::SRS::$subclass";
	my $srs = $class->new(
			Secret		=> "foo",
			Separator	=> "+",
				);

	# These all have an uppercase char so that smashing case does
	# at least something.
	my @tests = qw(
		User@domain-with-dash.com
		User-with-dash@domain.com
		User+with+plus@domain.com
		User=with=equals@domain.com
		User%with!everything&everything=@domain.somewhere
			);
	my $alias0 = 'alias@host.com';
	my $alias1 = 'name@forwarder.com';
	my $alias2 = 'user@postal.com';

	# We smashed case in here, so we must test case insens.
	foreach (@tests) {
		my $srs0addr = $srs->forward($_, $alias0);
		$srs0addr = lc $srs0addr;
		my $srs0rev = $srs->reverse($srs0addr);
		is(lc $srs0rev, lc $_, 'Idempotent on ' . $_);

		my $srs1addr = $srs->forward($srs0addr, $alias1);
		$srs1addr = lc $srs1addr;
		my $srs1rev = $srs->reverse($srs1addr);
		if ($subclass eq 'Shortcut') {
			is(lc $srs1rev, lc $_, 'Shortcut S2 idempotent on ' . $_);
		}
		else {
			is(lc $srs1rev, lc $srs0addr, 'S2 idempotent on ' . $srs0addr);
		}
	}
}
