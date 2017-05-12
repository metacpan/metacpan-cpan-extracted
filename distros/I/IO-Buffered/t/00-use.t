use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
	use_ok( 'IO::Buffered' );
	use_ok( 'IO::Buffered::Split' );
	use_ok( 'IO::Buffered::Regexp' );
	use_ok( 'IO::Buffered::Last' );
	use_ok( 'IO::Buffered::FixedSize' );
	use_ok( 'IO::Buffered::Size' );
	use_ok( 'IO::Buffered::HTTP' );
}

diag("Testing IO::Buffered $IO::Buffered::VERSION, Perl $], $^X");
