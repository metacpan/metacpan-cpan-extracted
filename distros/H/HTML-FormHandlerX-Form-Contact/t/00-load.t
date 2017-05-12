#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::FormHandlerX::Form::Contact' ) || print "Bail out!\n";
}

diag( "Testing HTML::FormHandlerX::Form::Contact $HTML::FormHandlerX::Form::Contact::VERSION, Perl $], $^X" );
