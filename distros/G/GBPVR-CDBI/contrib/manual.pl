#!perl

use strict;
use warnings;

use GBPVR::CDBI::CaptureSource;
use GBPVR::CDBI::Channel;
use POSIX qw/strftime/;

my $ch_num = $ARGV[0] or die "need channel";
my $start_time = $ARGV[1] or die "need HH:MM start";
my $end_time = $ARGV[2] or die "need HH:MM end";

my ($cs) = GBPVR::CDBI::CaptureSource->retrieve_all;
my ($ch) = GBPVR::CDBI::Channel->search( channel_number => $ch_num );

my @start = localtime();
my @end = @start;
@start[2,1] = split /:/, $start_time;
@end[2,1] = split /:/, $end_time;
my $dtFmt = '%m/%d/%Y %I:%M:%S %p';
my $start = strftime( $dtFmt, @start );
my $end = strftime( $dtFmt, @end );

my $row = GBPVR::CDBI::RecordingSchedule->create({
  programme_oid => undef,
  capture_source_oid => $cs->oid,
  filename => "manual$$.mpg",
  status => 0,
  recording_type =>  0,
  recording_group => 0,
  manual_start_time =>  $start,  # 5/18/2005 11:20:00 PM
  manual_end_time => $end,
  manual_channel_oid => $ch->oid,
  quality_level => 2,
  pre_pad_minutes => 1,
  post_pad_minutes => 2,
});

$row->dbi_commit;

#eof#
