#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::FormHandler::Render::Hash' );
}

diag( "Testing HTML::FormHandler::Render::Hash $HTML::FormHandler::Render::Hash::VERSION, Perl $], $^X" );
