#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Form::Toolkit' ) || print "Bail out!
";
}

diag( "Testing Form::Toolkit::Form $Form::Toolkit::VERSION, Perl $], $^X" );
