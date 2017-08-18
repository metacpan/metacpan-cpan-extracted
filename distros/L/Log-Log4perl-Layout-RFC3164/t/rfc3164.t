#!perl -Tw


# See https://www.snip2code.com/Snippet/1423169/Regex-for-SYSLOG-format-RFC3164-and-RFC5424

use strict;
use warnings;
use Test::Most tests => 4;
use Test::NoWarnings;
use Sys::Syslog qw(:standard :macros);

BEGIN {
	use_ok('Log::Log4perl::Layout::RFC3164');
}

RFC3164: {
	my $layout = new_ok('Log::Log4perl::Layout::RFC3164');

	if($ENV{'TEST_VERBOSE'}) {
		diag($layout->render('hello', LOG_KERN, LOG_DEBUG, 0));
	}
	like($layout->render('hello', LOG_KERN, LOG_DEBUG, 0), qr/([A-Z][a-z][a-z]\s{1,2}\d{1,2}\s\d{2}[:]\d{2}[:]\d{2})\s([\w][\w\d\.@-]*)\s(.*)$/, 'check valid rfc3124');
}
