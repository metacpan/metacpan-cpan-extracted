#!perl -T

use strict;

use Test::More tests => 2;

BEGIN {
	use_ok('Log::Dispatch::Email::DKIM') || BAIL_OUT('Log::Dispatch::Email::DKIM does not load');
}

require_ok('Log::Dispatch::Email::DKIM') || BAIL_OUT('Log::Dispatch::Email::DKIM does not require');

diag("Log::Dispatch::Email::DKIM $Log::Dispatch::Email::DKIM::VERSION, Perl $], $^X");
