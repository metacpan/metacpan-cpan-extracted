#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IMAP::Query' ) || print "Bail out!\n";
}

diag( "Testing IMAP::Query $IMAP::Query::VERSION, Perl $], $^X" );
