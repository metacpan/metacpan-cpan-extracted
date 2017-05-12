#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lavoco::Web::App' ) || print "Bail out!\n";
}

diag( "Testing Lavoco::Web::App $Lavoco::Web::App::VERSION, Perl $], $^X" );
