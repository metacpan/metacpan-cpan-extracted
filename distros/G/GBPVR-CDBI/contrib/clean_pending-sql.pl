#!perl

use strict;
use warnings;

use GBPVR::CDBI::RecordingSchedule;

my $dbh = GBPVR::CDBI::RecordingSchedule->db_Main;

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

my $ct = $dbh->do( $cullPendingSQL );
printf "%d rows deleted -- removed from pending list.\n", $ct;

$ct = $dbh->do( $lowQualitySQL );
printf "%d rows updated -- set to low quality.\n", $ct;

$dbh->dbi_commit;

