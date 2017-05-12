#!perl -T

use Test::More tests => 1;

BEGIN { use_ok('Devel::Hook'); }

diag( "Testing Devel::Hook $Devel::Hook::VERSION, Perl $], $^X" );
