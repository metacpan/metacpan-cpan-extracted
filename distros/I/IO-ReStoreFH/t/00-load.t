#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('IO::ReStoreFH');
}

diag( "Testing IO::ReStoreFH $IO::ReStoreFH::VERSION, Perl $], $^X" );
