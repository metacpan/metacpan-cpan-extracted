#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Devtools::Cloudbuild::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Cloudbuild::V2::RepositoryManagerClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Devtools::Cloudbuild::V2 $Google::Cloud::Devtools::Cloudbuild::V2::VERSION, Perl $], $^X" );
