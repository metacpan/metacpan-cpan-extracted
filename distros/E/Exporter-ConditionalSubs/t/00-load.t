#!perl -T
use 5.008;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Exporter::ConditionalSubs' ) || print "Bail out!\n";
}

diag( "Testing Exporter::ConditionalSubs $Exporter::ConditionalSubs::VERSION, Perl $], $^X" );
