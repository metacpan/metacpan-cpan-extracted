#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require IO::Iron;

BEGIN {
	use_ok('IO::Iron') || print "Bail out!\n";
	can_ok('IO::Iron', 'ironcache');
	can_ok('IO::Iron', 'ironmq');
	can_ok('IO::Iron', 'ironworker');
}

diag('Testing IO::Iron '
   . ($IO::Iron::VERSION ? "($IO::Iron::VERSION)" : '(no version)')
   . ", Perl $], $^X");

done_testing();

