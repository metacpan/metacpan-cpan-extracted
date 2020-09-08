#!perl -T
use 5.014;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Matrix::Banded' ) || print "Bail out!\n";
}

diag( "Testing Math::Matrix::Banded $Math::Matrix::Banded::VERSION, Perl $], $^X" );
