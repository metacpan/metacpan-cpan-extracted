#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MariaDB::NonBlocking' ) || print "Bail out!\n";
}

diag( "Testing MariaDB::NonBlocking $MariaDB::NonBlocking::VERSION, Perl $], $^X" );
