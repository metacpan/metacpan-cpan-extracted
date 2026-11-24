#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Policytroubleshooter::Iam::V3beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Policytroubleshooter::Iam::V3beta::PolicyTroubleshooterClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Policytroubleshooter::Iam::V3beta $Google::Cloud::Policytroubleshooter::Iam::V3beta::VERSION, Perl $], $^X" );
