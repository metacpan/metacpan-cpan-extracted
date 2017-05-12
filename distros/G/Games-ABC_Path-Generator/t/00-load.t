#!perl

use Test::More tests => 3;

BEGIN {
    use_ok( 'Games::ABC_Path::Generator' ) || print "Bail out!\n";
    use_ok( 'Games::ABC_Path::MicrosoftRand' ) || print "Bail out!\n";
    use_ok( 'Games::ABC_Path::Generator::App' ) || print "Bail out!\n";
}

diag( "Testing Games::ABC_Path::Generator $Games::ABC_Path::Generator::VERSION, Perl $], $^X" );
