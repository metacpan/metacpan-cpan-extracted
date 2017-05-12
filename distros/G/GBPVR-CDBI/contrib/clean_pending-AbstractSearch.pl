#!perl

use strict;
use warnings;

use GBPVR::CDBI::RecordingSchedule;
use Class::DBI::AbstractSearch;
use Date::Calc qw/Today Add_Delta_Days/

my $iter = GBPVR::CDBI::RecordingSchedule->search_where(
	status => 0,
	manual_start_time => { '>', join("-",Add_Delta_Days(Today,3)) },
});
printf "%d rows deleted -- removed from pending list.\n", $iter->count;
$iter->delete_all;
GBPVR::CDBI::RecordingSchedule->dbi_commit;

my @rows = GBPVR::CDBI::RecordingSchedule->search_where( quality_level => { '!=', 2 } );
$_->quality_level(2) for @rows;
printf "%d rows updated -- set to low quality.\n", scalar(@rows);
GBPVR::CDBI::RecordingSchedule->dbi_commit;

