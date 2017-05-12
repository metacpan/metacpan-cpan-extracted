#!perl -T

use Test::More tests => 1;

BEGIN { chdir 't' if -d 't' }

use lib '../lib';

use_ok('LJ::GetCookieSession');

diag(
	"Testing LJ::GetCookieSession $LJ::GetCookieSession::VERSION, Perl $], $^X"
);
