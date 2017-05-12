use strict;
use warnings;
use blib;

use Test::More tests => 44;

BEGIN { use_ok('Mail::SRS'); }
BEGIN { use_ok('Mail::SRS::Guarded'); }
BEGIN { use_ok('Mail::SRS::Reversible'); }
BEGIN { use_ok('Mail::SRS::Shortcut'); }

foreach my $subclass (qw(Guarded Reversible Shortcut)) {
	my $class = "Mail::SRS::$subclass";
	my $srs0 = $class->new(
			Secret		=> "foo",
			Separator	=> "+",
				);
	my $srs1 = $class->new(
			Secret		=> "foo",
			Separator	=> "-",
				);
	my $srs2 = $class->new(
			Secret		=> "foo",
			Separator	=> "=",
				);

	my @tests = qw(
		user@domain-with-dash.com
		user-with-dash@domain.com
		user+with+plus@domain.com
		user=with=equals@domain.com
		user%with!everything&everything=@domain.somewhere
			);
	my $alias0 = 'alias@host.com';
	my $alias1 = 'name@forwarder.com';
	my $alias2 = 'user@postal.com';

	foreach (@tests) {
		my $srs0addr = $srs0->forward($_, $alias0);
		my $srs0rev = $srs0->reverse($srs0addr);
		is($srs0rev, $_, 'Idempotent on ' . $_);

		my $srs1addr = $srs1->forward($srs0addr, $alias1);
		my $srs1rev = $srs1->reverse($srs1addr);
		if ($subclass eq 'Shortcut') {
			is($srs1rev, $_, 'Shortcut S2 idempotent on ' . $_);
		}
		else {
			is($srs1rev, $srs0addr, 'S2 idempotent on ' . $srs0addr);
		}

		my $srs2addr = $srs2->forward($srs1addr, $alias2);
		my $srs2rev = $srs2->reverse($srs2addr);
		if ($subclass eq 'Guarded') {
			is($srs2rev, $srs0addr, 'Guarded S3 idempotent on ' . $srs1addr);
		}
		elsif ($subclass eq 'Reversible') {
			is($srs2rev, $srs1addr, 'Reversible S3 idempotent on ' . $srs1addr);
		}
	}
}
