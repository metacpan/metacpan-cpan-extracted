#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Interchange::Search::Solr' ) || print "Bail out!\n";
}

diag( "Testing Interchange::Search::Solr $Interchange::Search::Solr::VERSION, Perl $], $^X" );
