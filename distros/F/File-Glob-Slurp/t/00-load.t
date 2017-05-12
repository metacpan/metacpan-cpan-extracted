#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Glob::Slurp' );
}

diag( "Testing File::Glob::Slurp $File::Glob::Slurp::VERSION, Perl $], $^X" );
