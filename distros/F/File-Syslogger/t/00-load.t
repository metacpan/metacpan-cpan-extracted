#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::Syslogger' ) || print "Bail out!\n";
}

diag( "Testing File::Syslogger $File::Syslogger::VERSION, Perl $], $^X" );
