#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IO::Stty' );
  }

diag( "Testing IO::Stty $IO::Stty::VERSION, Perl $], $^X" );
