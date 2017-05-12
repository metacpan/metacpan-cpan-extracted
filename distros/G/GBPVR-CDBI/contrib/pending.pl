#!perl

use strict;
use warnings;
use GBPVR::CDBI::RecordingSchedule;

my @rows = GBPVR::CDBI::RecordingSchedule->search( status => 0 );
@rows = sort { $a->manual_start_time cmp $b->manual_start_time } @rows;
foreach my $row (@rows){
  printf "%s-%s %2d %s - %s\n",
	$row->manual_start_time,
	$row->end_time,
	$row->manual_channel_oid->channel_number,
	$row->programme_oid ? $row->programme_oid->name : 'manual',
	$row->programme_oid ? $row->programme_oid->sub_title : 'manual',
  ;
}

