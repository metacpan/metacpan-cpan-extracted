#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::FormHandlerX::Form::Login' ) || print "Bail out!\n";
}

diag( "Testing HTML::FormHandlerX::Form::Login $HTML::FormHandlerX::Form::Login::VERSION, Perl $], $^X" );
