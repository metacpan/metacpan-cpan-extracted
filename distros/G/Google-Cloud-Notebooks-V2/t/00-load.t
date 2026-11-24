#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Notebooks::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Notebooks::V2::NotebookServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Notebooks::V2 $Google::Cloud::Notebooks::V2::VERSION, Perl $], $^X" );
