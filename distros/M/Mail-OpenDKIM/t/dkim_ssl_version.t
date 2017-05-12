#!perl -w

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
	use_ok('Mail::OpenDKIM');
}

SSL: {
	my $v = Mail::OpenDKIM::dkim_ssl_version();
	ok(defined($v));

	diag("Using SSL Version $v\n");
}
