#!perl

use strict;
use warnings;

use Win32::ODBC;

my $DriverType = "Microsoft Access Driver (*.mdb)";
my $DSN = "Win32 ODBC --MAOmaoMAOmaoMAO--";
my $Dir = "c:\\program files\\devnz\\gbpvr";
my $DBase = "gbpvr.mdb";


Win32::ODBC::ConfigDSN(ODBC_ADD_DSN, $DriverType,("DSN=$DSN", "Description=MAO Win32 ODBC Test DSN for Perl", "DBQ=$Dir\\$DBase", "DEFAULTDIR=$Dir", "UID=", "PWD=")) or die "ConfigDSN(): Could not add temporary DSN" . Win32::ODBC::Error();

my $db=new Win32::ODBC($DSN) or die "couldn't ODBC $DSN because ", Win32::ODBC::Error(), "\n";

my $cullPendingSQL = <<EOF;
  DELETE FROM recording_schedule
  WHERE status = 0
    AND  manual_start_time - now() > 3
EOF

my $lowQualitySQL = <<EOF;
  UPDATE recording_schedule
  SET quality_level = 2
  WHERE quality_level <> 2
EOF

$db->Sql( $cullPendingSQL );
printf "%d rows deleted -- removed from pending list.\n", $db->RowCount;

$db->Sql( $lowQualitySQL );
printf "%d rows updated -- set to low quality.\n", $db->RowCount;

$db->Close();

Win32::ODBC::ConfigDSN(ODBC_REMOVE_DSN, $DriverType, "DSN=$DSN") or die "ConfigDSN(): Could not remove temporary DSN because ", Win32::ODBC::Error();

