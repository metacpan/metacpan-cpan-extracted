#!perl

use strict;
use warnings;

use GBPVR::CDBI::RecordingSchedule;

use Data::ICal;
use Data::ICal::Entry::Event;

my $calendar = Data::ICal->new();

my @rows = GBPVR::CDBI::RecordingSchedule->search( status => 0 );
foreach my $row (@rows){
  my $start = sprintf "%04d%02d%02dT%02d%02d%02d", $row->parse_manual_time($row->manual_start_time);  # YYYYMMDDTHHMMSS
  my $end = sprintf "%04d%02d%02dT%02d%02d%02d", $row->parse_manual_time($row->manual_end_time);  # YYYYMMDDTHHMMSS
  my $channel = $row->manual_channel_oid;
  my $program = $row->programme_oid;
  my $vevent = Data::ICal::Entry::Event->new();
  $vevent->add_properties(
    summary => $program ? $program->name : 'manual',
    description => $program ? $program->sub_title . ' - ' . $program->description : 'manual',
    dtstart => $start,
    dtend => $end,
    location => $channel->channel_number . ' - ' . $channel->name,
    status => 'CONFIRMED',
  );
  $calendar->add_entry($vevent);
}

@rows = GBPVR::CDBI::RecordingSchedule->search( status => 4 );
foreach my $row (@rows){
  my $start = sprintf "%04d%02d%02dT%02d%02d%02d", $row->parse_manual_time($row->manual_start_time);  # YYYYMMDDTHHMMSS
  next if $start eq '20010101T000000';
  my $end = sprintf "%04d%02d%02dT%02d%02d%02d", $row->parse_manual_time($row->manual_end_time);  # YYYYMMDDTHHMMSS
  my $channel = $row->manual_channel_oid;
  my $vevent = Data::ICal::Entry::Event->new();
  $vevent->add_properties(
    summary => "*" . $row->filename,
    description => '',
    dtstart => $start,
    dtend => $end,
    location => $channel->channel_number . ' - ' . $channel->name,
    status => 'TENTATIVE',
    rrule => 'FREQ=WEEKLY;INTERVAL=1',
  );
  $calendar->add_entry($vevent);
}

print $calendar->as_string;;

#eof#

