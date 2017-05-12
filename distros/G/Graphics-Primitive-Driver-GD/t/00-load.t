#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Graphics::Primitive::Driver::GD' );
}

diag( "Testing Graphics::Primitive::Driver::GD $Graphics::Primitive::Driver::GD::VERSION, Perl $], $^X" );
