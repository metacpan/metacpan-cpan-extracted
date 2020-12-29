#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'LocalConf::Parser' ) || print "Bail out!\n";
}

diag( "Testing LocalConf::Parser $LocalConf::Parser::VERSION, Perl $], $^X" );
