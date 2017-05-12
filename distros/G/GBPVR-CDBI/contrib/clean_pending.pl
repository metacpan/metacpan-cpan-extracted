#!perl

use strict;
use warnings;

use GBPVR::CDBI::RecordingSchedule;

my $iter = GBPVR::CDBI::RecordingSchedule->retrieve_from_sql(qq{
	status = 0
	AND manual_start_time > now() + 3
});
printf "%d rows deleted -- removed from pending list.\n", $iter->count;
$iter->delete_all;
GBPVR::CDBI::RecordingSchedule->dbi_commit;

my @rows = GBPVR::CDBI::RecordingSchedule->retrieve_from_sql('quality_level <> 2');
$_->quality_level(2) for @rows;
printf "%d rows updated -- set to low quality.\n", scalar(@rows);
GBPVR::CDBI::RecordingSchedule->dbi_commit;

