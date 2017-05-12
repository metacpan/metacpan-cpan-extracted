#!perl -T

use Test::More;
use strict;
use warnings;

plan tests => 125;

use File::Spec;
use GBPVR::CDBI::RecordingSchedule;

my $db= File::Spec->rel2abs("t\\gbpvr.mdb");
ok($db, "found test db");
my $rc = GBPVR::CDBI->db_setup(file => $db);
ok($rc, "got db handle");

my @rows = GBPVR::CDBI::RecordingSchedule->retrieve_all();
is(scalar(@rows), 3, "got exactly 3 rows");

my @matches = (
  {
    oid => 1,
    programme_oid => undef,
    capture_source_oid => '1',
    filename => 'Battlestar Galactica',
    status => '4',
    recording_type => '5',
    recording_group => '37',
    manual_start_time => '2005-07-15 22:00:00',
    manual_end_time => '2005-07-15 23:00:00',
    manual_channel_oid => '1',
    quality_level => '2',
    pre_pad_minutes => '1',
    post_pad_minutes => '2',

    start_time => '22:00',
    end_time => '23:00',
    start_date => '2005-07-15',
    end_date => '2005-07-15',
    status_string => 'Number4',

    last_position => undef,
    archivetable => undef,
  },
  {
    oid => 2,
    programme_oid => 1,
    capture_source_oid => '1',
    filename => q/C:\Video\Battlestar Galactica\Battlestar Galactica_20060203_22002300.mpg/,
    status => '2',
    recording_type => '0',
    recording_group => '10',
    manual_start_time => '2006-02-03 22:00:00',
    manual_end_time => '2006-02-03 23:00:00',
    manual_channel_oid => '1',
    quality_level => '2',
    pre_pad_minutes => '1',
    post_pad_minutes => '2',

    start_time => '22:00',
    end_time => '23:00',
    start_date => '2006-02-03',
    end_date => '2006-02-03',
    status_string => 'Completed',

    last_position => '123.0',
    archivetable => undef,
  },
  {
    oid => 3,
    programme_oid => 2,
    capture_source_oid => '1',
    filename => 'Battlestar Galactica',
    status => '0',
    recording_type => '0',
    recording_group => '10',
    manual_start_time => '2006-03-03 22:00:00',
    manual_end_time => '2006-03-03 23:00:00',
    manual_channel_oid => '1',
    quality_level => '2',
    pre_pad_minutes => '1',
    post_pad_minutes => '2',

    start_time => '22:00',
    end_time => '23:00',
    start_date => '2006-03-03',
    end_date => '2006-03-03',
    status_string => 'Pending',

    last_position => undef,
    archivetable => undef,
  },
);
foreach my $i ( 0..$#matches ){
  my $match = $matches[$i];
  my $row = $rows[$i];
  is( ref($row), 'GBPVR::CDBI::RecordingSchedule', "item is an object");
  foreach my $k ( sort keys %$match ){
    my $v = $match->{$k};
    is( $row->$k, $v, "$k matches" );
  }

  my $fk;

  $fk = $row->capture_source_oid;
  is( ref($fk), 'GBPVR::CDBI::CaptureSource', "has_a capture_source_oid" );
  is( $fk->oid, $row->capture_source_oid, "capturesource oid matches" );
  is( $fk->name, 'Device1-Tuner', "capturesource name matches" );
  is( $fk->recording_source_class, 'GBPVR.Backend.Common.DirectRecordingSource', "capturesource recording_source_class matches" );
  is( $fk->epgsource_class, 'GBPVR.Backend.Common.Zap2itEpgReader', "capturesource epgsource_class matches" );
  is( $fk->channel_changer_class, 'GBPVR.Backend.Common.NullTunerController', "capturesource channel_changer_class matches" );

  $fk = $row->manual_channel_oid;
  is( ref($fk), 'GBPVR::CDBI::Channel', "has_a manual_channel_oid" );
  is( $fk->oid, $row->manual_channel_oid, "channel oid matches" );
  is( $fk->name, '73 SCIFI', "channel name matches" );
  is( $fk->channelID, '123', "channel channelID matches" );
  is( $fk->channel_number, '73', "channel channel_number matches" );
  is( $fk->favourite, '1', "channel favourite matches" );
  is( $fk->favorite, '1', "channel favorite matches" );
}

my $prog;

$prog = $rows[1]->programme_oid;
is( ref($prog), 'GBPVR::CDBI::Programme', "[1] has_a programme_oid" );
is( $prog->oid, $rows[1]->programme_oid, "[1] programme oid matches" );
is( $prog->oid, 1, "[1] programme oid matches" );
is( $prog->name, 'Battlestar Galactica', "[1] programme name matches" );
is( $prog->sub_title, 'Scar', "[1] programme sub_title matches" );
is( $prog->description, "Galactica's Viper pilots are called upon to protect a Colonial mining operation.", "[1] programme description matches" );
is( $prog->start_time, '2006-02-03 22:00:00', "[1] programme start_time matches" );
is( $prog->end_time, '2006-02-03 23:00:00', "[1] programme end_time matches" );
is( $prog->channel_oid, '1', "[1] programme channel_oid matches" );
is( $prog->unique_identifier, 'EP7107490031', "[1] programme unique_identifier matches" );

$prog = $rows[2]->programme_oid;
is( ref($prog), 'GBPVR::CDBI::Programme', "[2] has_a programme_oid" );
is( $prog->oid, $rows[2]->programme_oid, "[2] programme oid matches" );
is( $prog->oid, 2, "[2] programme oid matches" );
is( $prog->name, 'Battlestar Galactica', "[2] programme name matches" );
is( $prog->sub_title, 'Lay Down Your Burdens', "[2] programme sub_title matches" );
is( $prog->description, "The discovery of a habitable planet swings the election in Baltar's favor; Starbuck's rescue mission runs into trouble.", "[2] programme description matches" );
is( $prog->start_time, '2006-03-03 22:00:00', "[2] programme start_time matches" );
is( $prog->end_time, '2006-03-03 23:00:00', "[2] programme end_time matches" );
is( $prog->channel_oid, '1', "[2] programme channel_oid matches" );
is( $prog->unique_identifier, 'EP7107490035', "[2] programme unique_identifier matches" );

#eof#

