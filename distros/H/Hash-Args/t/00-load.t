#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok( 'Hash::Args' );
}

diag( "Hash::Args $Hash::Args::VERSION, Perl $], $^X" );

done_testing;

