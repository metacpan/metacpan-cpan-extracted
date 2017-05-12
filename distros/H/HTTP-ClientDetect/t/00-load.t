#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'HTTP::ClientDetect' ) || print "Bail out!\n";
    use_ok( 'HTTP::ClientDetect::Language' ) || print "Bail out!\n";
    use_ok( 'HTTP::ClientDetect::Location' ) || print "Bail out!\n";
    use_ok( 'Interchange6::Plugin::Interchange5::Request' ) || print "Bail out!\n";
}

diag( "Testing HTTP::ClientDetect $HTTP::ClientDetect::VERSION, Perl $], $^X" );
