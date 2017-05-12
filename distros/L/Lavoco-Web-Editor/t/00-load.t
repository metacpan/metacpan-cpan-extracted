#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lavoco::Web::Editor' ) || print "Bail out!\n";
}

diag( "Testing Lavoco::Web::Editor $Lavoco::Web::Editor::VERSION, Perl $], $^X" );
