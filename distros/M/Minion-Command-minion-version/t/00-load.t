#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Minion::Command::minion::version' ) || print "Bail out!\n";
}

diag( "Testing Minion::Command::minion::version $Minion::Command::minion::version::VERSION, Perl $], $^X" );
