#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Decision::Depends');
}

diag( "Testing Decision::Depends $Decision::Depends::VERSION, Perl $], $^X" );
