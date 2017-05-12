#!perl -T

use Test::More tests => 1;

BEGIN {
   use_ok( 'Excel::Template::XLSX' ) || print "Bail out!\n";
}

diag( "Testing Excel::Template::XLSX $Excel::Template::XLSX::VERSION, Perl $], $^X" );
