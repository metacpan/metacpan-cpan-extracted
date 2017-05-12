use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok('IO::EventMux');
}

diag("Testing IO::EventMux $IO::EventMux::VERSION, Perl $], $^X");
