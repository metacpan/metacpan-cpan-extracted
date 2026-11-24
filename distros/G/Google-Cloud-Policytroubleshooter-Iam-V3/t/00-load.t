#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Policytroubleshooter::Iam::V3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Policytroubleshooter::Iam::V3::PolicyTroubleshooterClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Policytroubleshooter::Iam::V3 $Google::Cloud::Policytroubleshooter::Iam::V3::VERSION, Perl $], $^X" );
