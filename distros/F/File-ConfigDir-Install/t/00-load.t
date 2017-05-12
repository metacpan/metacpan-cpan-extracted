#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::ConfigDir::Install' ) || BAIL_OUT "Couldn't load File::ConfigDir::Install";
}

diag( "Testing File::ConfigDir::Install $File::ConfigDir::Install::VERSION, Perl $], $^X" );
