#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Backupdr::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Backupdr::V1::BackupDRClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Backupdr::V1::BackupDrProtectionSummaryClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Backupdr::V1 $Google::Cloud::Backupdr::V1::VERSION, Perl $], $^X" );
