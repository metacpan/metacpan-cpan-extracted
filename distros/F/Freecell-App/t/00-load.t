#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Freecell::App' ) || print "Bail out!\n";
    use_ok( 'Freecell::App::Tableau' ) || print "Bail out!\n";
}

diag( "Testing Freecell::App $Freecell::App::VERSION, Perl $], $^X" );
