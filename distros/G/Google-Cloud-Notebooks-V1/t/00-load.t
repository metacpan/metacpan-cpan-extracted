#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Notebooks::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Notebooks::V1::ManagedNotebookServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Notebooks::V1::NotebookServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Notebooks::V1 $Google::Cloud::Notebooks::V1::VERSION, Perl $], $^X" );
