#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Developers::Knowledge::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Developers::Knowledge::V1alpha::DeveloperKnowledgeClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Developers::Knowledge::V1alpha $Google::Cloud::Developers::Knowledge::V1alpha::VERSION, Perl $], $^X" );
