#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Backupdr::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Backupdr::V1beta::BackupDRClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Backupdr::V1beta::BackupDrProtectionSummaryClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Backupdr::V1beta $Google::Cloud::Backupdr::V1beta::VERSION, Perl $], $^X" );
