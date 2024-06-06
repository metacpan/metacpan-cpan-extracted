#!perl
use 5.016;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Extism' ) || print "Bail out!\n";
    use_ok( 'Extism::XS' ) || print "Bail out!\n";
    use_ok( 'Extism::Plugin' ) || print "Bail out!\n";
    use_ok( 'Extism::CurrentPlugin' ) || print "Bail out!\n";
    use_ok( 'Extism::Function' ) || print "Bail out!\n";
    use_ok( 'Extism::Plugin::CancelHandle' ) || print "Bail out!\n";
}

diag( "Testing Extism $Extism::VERSION, Perl $], $^X" );
