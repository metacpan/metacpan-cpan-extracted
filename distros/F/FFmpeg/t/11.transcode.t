BEGIN {
  use Test::More tests => 19;
  use strict;
  use_ok('FFmpeg');
  use_ok('Data::Dumper');
  use_ok('File::Spec::Functions');
}

my $fname = "eg/t2.mpg";

ok(-d catfile('eg','test') || mkdir(catfile('eg','test')) , 'mkdir eg/test');

ok(my $ff = FFmpeg->new(input_file => $fname)      , 'ff object created successfully');
ok($ff->isa('FFmpeg')                              , 'object correct type A');
ok(my $sg = $ff->create_streamgroup()              , 'streamgroup created successfully');
ok($sg->isa('FFmpeg::StreamGroup')                 , 'object correct type B');

ok $sg->transcode( file_format => $ff->file_format('avi'), output_file => catfile('eg','test','out.avi') );
ok $sg->transcode( file_format => $ff->file_format('flv'), output_file => catfile('eg','test','out.flv') );
ok $sg->transcode( file_format => $ff->file_format('flv'), output_file => catfile('eg','test','out.avi') ); #conflicting format/extension
ok $sg->transcode( file_format => $ff->file_format('flv'), output_file => catfile('eg','test','out.2.flv'), video_bitrate => 8000, audio_rate => 44100 );
ok $sg->transcode( file_format => $ff->file_format('mpeg'), output_file => catfile('eg','test','out.mpg') );
ok $sg->transcode( file_format => $ff->file_format('mpeg'), output_file => catfile('eg','test','out.h261.mpg'), video_codec => $ff->codec('h261') );
ok $sg->transcode( file_format => $ff->file_format('mpeg'), output_file => catfile('eg','test','out.h263.mpg'), video_codec => $ff->codec('h263'), video_geometry => '128x96' );
ok $sg->transcode( file_format => $ff->file_format('avi'), output_file => catfile('eg','test','out.avi'), audio_codec => $ff->codec('mp3') );
ok $sg->transcode( file_format => $ff->file_format('avi'), output_file => catfile('eg','test','out.avi'), audio_bitrate => 256, audio_codec => $ff->codec('ac3') );
ok $sg->transcode( file_format => $ff->file_format('avi'), output_file => catfile('eg','test','out.avi'), video_rate => 1/10 );
ok $sg->transcode( file_format => $ff->file_format('avi'), output_file => catfile('eg','test','out.avi'), video_geometry => '40x30' );

#TODO
# test audio-only
# test audio-only w/ frame parameters (should fail)

#$ff->verbose(1);
