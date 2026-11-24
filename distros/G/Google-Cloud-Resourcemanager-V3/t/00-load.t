#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Google::Cloud::Resourcemanager::V3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Resourcemanager::V3::FoldersClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Resourcemanager::V3::OrganizationsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Resourcemanager::V3::ProjectsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Resourcemanager::V3::TagBindingsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Resourcemanager::V3::TagHoldsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Resourcemanager::V3::TagKeysClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Resourcemanager::V3::TagValuesClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Resourcemanager::V3 $Google::Cloud::Resourcemanager::V3::VERSION, Perl $], $^X" );
