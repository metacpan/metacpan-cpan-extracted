#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Emacs::Run' );
}

diag( "Testing Emacs::Run $Emacs::Run::VERSION, Perl $], $^X" );
