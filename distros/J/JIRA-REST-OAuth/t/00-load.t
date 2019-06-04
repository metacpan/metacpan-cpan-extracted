#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JIRA::REST::OAuth' ) || print "Bail out!\n";
}

diag( "Testing JIRA::REST::OAuth $JIRA::REST::OAuth::VERSION, Perl $], $^X" );
