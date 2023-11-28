#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::suricata_include' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::suricata_include::VERSION, Perl $], $^X" );
