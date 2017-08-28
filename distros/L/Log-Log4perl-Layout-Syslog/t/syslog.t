#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 4;
use Test::NoWarnings;

BEGIN {
	use_ok('Log::Log4perl::Layout::Syslog');
}

SYSLOG: {
	my $layout = new_ok('Log::Log4perl::Layout::Syslog');
	like($layout->render("'su root' failed for lonvick on /dev/pts/8", 4, 'CRIT', 0), qr/user: .+/, 'check valid syslog string');
}
