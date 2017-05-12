#!perl -T

use Test::More tests => 1;

use_ok( 'MVC::Neaf' ) || print "Bail out!\n";

diag( "Testing MVC::Neaf $MVC::Neaf::VERSION, Perl $], $^X" );
