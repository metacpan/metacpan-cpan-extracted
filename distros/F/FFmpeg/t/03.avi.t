use Test::More tests => 56;
use FFmpeg;
use Data::Dumper;

my $fname = "eg/t1.avi";

ok($ff = FFmpeg->new(input_file => $fname)    , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok($sg = $ff->create_streamgroup              , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^29/,                   , 'object correct type'); #used to use header value.  now uses some combo of filesize and bitrate, it seems.  FIXME steal some code from Video::Info and use the data_offset attribute to get the intended length from a file frag.
is(scalar($sg->streams), 2                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 1, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 1, 'audio stream count correct');

ok($sg->has_audio                             , 'audio detected ok');
ok($sg->has_video                             , 'video detected ok');

ok(my $v0 = ($sg->streams)[0]                 , 'got stream 0');
is($v0->isa('FFmpeg::Stream::Video'), 1,      , 'stream 0 is video');
is($v0->width, 240,                           , 'stream 0 width ok');
is($v0->height, 180,                          , 'stream 0 height ok');
is($v0->quality, 0,                           , 'stream 0 quality is 0');
like($v0->duration, qr/^0/,                   , 'stream 0 duration is 35usec');
is(int($v0->video_rate), 12                   , 'stream 0 frame rate ok');

ok(my $v1 = ($sg->streams)[1]                 , 'got stream 1');
is($v1->isa('FFmpeg::Stream::Audio'), 1,                          , 'stream 1 is audio');
is($v1->sample_rate, 22050,                   , 'stream 1 sample rate is 22050');
is($v1->bit_rate, 89240,                      , 'stream 1 bit rate is 89240');
is($v1->channels, 1,                          , 'stream 1 channels is 1');

is($sg->album, ''                             , 'streamgroup album ok');
is($sg->author, ''                            , 'streamgroup author ok');
is($sg->bit_rate, 51884                       , 'streamgroup bit_rate ok');
is($sg->comment, ''                           , 'streamgroup comment ok');
is($sg->copyright, ''                         , 'streamgroup copyright ok');
is($sg->data_offset, 2048                     , 'streamgroup data_offset ok');
is($sg->file_size, 188443                     , 'streamgroup file_size ok');
is($sg->format->name, 'avi'                   , 'streamgroup format ok');
is($sg->genre, ''                             , 'streamgroup genre ok');
is($sg->track, 0                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');

#warn Dumper($sg);

$fname = "eg/t2.avi";

ok(my $ff = FFmpeg->new(input_file => $fname) , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok(my $sg = $ff->create_streamgroup           , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^1231/                 , 'streamgroup duration correct');
is(scalar($sg->streams), 2                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 1, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 1, 'audio stream count correct');

ok($sg->has_audio                             , 'audio detected ok');
ok($sg->has_video                             , 'video detected ok');

is($sg->album, ''                             , 'streamgroup album ok');
is($sg->author, ''                            , 'streamgroup author ok');
is($sg->bit_rate, 168                         , 'streamgroup bit_rate ok');
is($sg->comment, ''                           , 'streamgroup comment ok');
is($sg->copyright, ''                         , 'streamgroup copyright ok');
is($sg->data_offset, 2060                     , 'streamgroup data_offset ok');
is($sg->file_size, 25986                      , 'streamgroup file_size ok');
is($sg->format->name, 'avi'                   , 'streamgroup format ok');
is($sg->genre, ''                             , 'streamgroup genre ok');
is($sg->track, 0                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');

