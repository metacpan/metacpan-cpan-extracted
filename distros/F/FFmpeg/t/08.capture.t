BEGIN {
  use Test::More tests => 82;
  use strict;
  use_ok('FFmpeg');
  use_ok('Data::Dumper');
  use_ok('File::Spec::Functions');
}

my $fname = "eg/t1.m2v";

ok(-d catfile('eg','test') || mkdir(catfile('eg','test')) , 'mkdir eg/test');

ok(my $ff = FFmpeg->new(input_file => $fname)      , 'ff object created successfully');
ok($ff->isa('FFmpeg')                              , 'object correct type A');
ok(my $sg = $ff->create_streamgroup                , 'streamgroup created successfully');
ok($sg->isa('FFmpeg::StreamGroup')                 , 'object correct type B');

ok(my $frame = $sg->capture_frame(offset => '00:00:00'), 'captured frame');

ok(!$frame->Write(filename=>catfile('eg','test','t0.ppm')), 'wrote frame 0 to file');
ok(-f catfile('eg','test','t0.ppm')                , 'frame file exists');

#CAPTURE ALL 30 frames at 1s offset, full rate
ok($iterator = $sg->capture_frames(duration => '00:00:01')  , 'frame iterator');
isa_ok($iterator,'Image::Magick::Iterator'         , 'frame iterator okay');
my $i = 0;
while(my $frame = $iterator->next){
  $i++;
  my $j = sprintf("A%03d.ppm",$i);
  ok(!$frame->Write(filename=>catfile('eg','test',$j)), "wrote frame $i to file");
  ok(-f catfile('eg','test',$j)                       , "frame file $i exists");
}

#CAPTURE ALL 30 frames at 1s offset, one frame every 0.5s
ok($iterator = $sg->capture_frames(duration => '00:00:01', video_rate => 0.5)  , 'frame iterator');
isa_ok($iterator,'Image::Magick::Iterator'         , 'frame iterator okay');
$i = 0;
while(my $frame = $iterator->next){
  $i++;
  my $j = sprintf("B%03d.ppm",$i);
  ok(!$frame->Write(filename=>catfile('eg','test',$j)), "wrote frame $i to file");
  ok(-f catfile('eg','test',$j)                       , "frame file $i exists");
  #warn $i,"\t",$frame;
}

#CAPTURE ALL 30 frames at 1s offset, one frame every 0.5s, resized to 160x120
ok($iterator = $sg->capture_frames(duration => '00:00:01',
                                   video_rate => 0.5,
                                   video_geometry => '160x120'),
   'frame iterator');
isa_ok($iterator,'Image::Magick::Iterator'         , 'frame iterator okay');
$i = 0;
while(my $frame = $iterator->next){
  $i++;
  my $j = sprintf("C%03d.ppm",$i);
  ok(!$frame->Write(filename=>catfile('eg','test',$j)), "wrote frame $i to file");
  ok(-f catfile('eg','test',$j)                       , "frame file $i exists");
  #warn $i,"\t",$frame;
}

#have to sprintf to round it -- there are extra ppm header bytes which
#make the ratio slightly less than 4.
ok( sprintf("%.0f", ((-s catfile('eg','test','B001.ppm')) / (-s catfile('eg','test','C001.ppm'))) ) == '4','320x240 -> 160x120 resize seems to be working');
