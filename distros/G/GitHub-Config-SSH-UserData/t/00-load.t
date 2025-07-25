#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'GitHub::Config::SSH::UserData' ) || print "Bail out!\n";
}

diag( "Testing GitHub::Config::SSH::UserData $GitHub::Config::SSH::UserData::VERSION, Perl $], $^X" );
