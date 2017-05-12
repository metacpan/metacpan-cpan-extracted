#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Minion::Command::minion::jobx' ) || print "Bail out!\n";
}

diag( "Testing Minion::Command::minion::jobx $Minion::Command::minion::jobx::VERSION, Perl $], $^X" );
