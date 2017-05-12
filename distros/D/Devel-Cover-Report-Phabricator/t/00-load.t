#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Devel::Cover::Report::Phabricator' ) || print "Bail out!\n";
}

diag( "Testing Devel::Cover::Report::Phabricator $Devel::Cover::Report::Phabricator::VERSION, Perl $], $^X" );
