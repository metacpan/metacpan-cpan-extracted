#!perl -wT

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
	use_ok('Mail::OpenDKIM');
}

GETRESULTSTR: {
	ok(Mail::OpenDKIM::dkim_getresultstr(DKIM_STAT_OK) eq 'Success');
	ok(Mail::OpenDKIM::dkim_getresultstr(DKIM_STAT_INVALID) eq 'Invalid parameter');
}
