#!/usr/bin/perl -w
use strict;

use Test::More tests => 3;

use lib 't/testlib';

BEGIN {
SKIP: {
	eval "use Typelibs";
	skip "Microsoft Outlook doesn't appear to be installed\n", 3	if($@);

	my $vers = Typelibs::ExistsTypeLib('Microsoft Outlook');
	skip "Microsoft Outlook doesn't appear to be installed\n", 3	unless($vers);

	use_ok( 'Mail::Outlook' );
	use_ok( 'Mail::Outlook::Folder' );
	use_ok( 'Mail::Outlook::Message' );
}
}
