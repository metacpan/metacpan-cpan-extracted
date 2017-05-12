#!perl -T

use Test::More tests => 2;

BEGIN {
  use_ok('Math::Rational::Approx::ContFrac');
  use_ok('Math::Rational::Approx::MaxD');
}

diag( "Testing Math::Rational::Approx::ContFrac $Math::Rational::Approx::ContFrac::VERSION, Perl $], $^X" );
diag( "Testing Math::Rational::Approx::MaxD $Math::Rational::Approx::MaxD::VERSION, Perl $], $^X" );
