#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::auto_cron' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::auto_cron::VERSION, Perl $], $^X" );
