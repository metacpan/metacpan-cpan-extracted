use Test::More tests => 71;
use FFmpeg;
use Data::Dumper;

my $fname = "eg/t1.asf";

#if(0){######################################

ok(my $ff = FFmpeg->new(input_file => $fname) , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok(my $sg = $ff->create_streamgroup           , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^1/,                   , 'streamgroup duration correct');
is(scalar($sg->streams), 6                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 5, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 0, 'audio stream count correct');

TODO: {
  local $TODO = "WMA/MPEG codec matrix lookups not finished";
  ok($sg->has_audio                           , 'audio detected ok');
}

ok($sg->has_video                             , 'video detected ok');

is($sg->album, 'The Living Trees'             , 'streamgroup album ok');
is($sg->author, 'AIMS Multimedia'             , 'streamgroup author ok');
is($sg->bit_rate, 74342                       , 'streamgroup bit_rate ok');
is($sg->width, 320                            , 'streamgroup width ok');
is($sg->height, 240                           , 'streamgroup height ok');

ok(my $v0 = ($sg->streams)[1]                 , 'got stream 0');
is($v0->isa('FFmpeg::Stream::Video'), 1,      , 'stream 0 is audio');
is($v0->quality, 0,                           , 'stream 0 quality is 0');

is($sg->comment, 'The Living Trees'           , 'streamgroup comment ok');
is($sg->copyright, '(C) 2002 AIMS Multimedia' , 'streamgroup copyright ok');
is($sg->data_offset, 4381                     , 'streamgroup data_offset ok');
is($sg->file_size, 10157                      , 'streamgroup file_size ok');
is($sg->format->name, 'asf'                   , 'streamgroup format ok');
is($sg->genre, ''                             , 'streamgroup genre ok');
is($sg->track, 1                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');

#}

#warn Dumper($sg);

$fname = "eg/t2.asf";

ok($ff = FFmpeg->new(input_file => $fname)    , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok($sg = $ff->create_streamgroup              , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^6/,                   , 'streamgroup duration correct');
is(scalar($sg->streams), 6                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 5, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 0, 'audio stream count correct');

TODO: {
  local $TODO = "WMA/MPEG codec matrix lookups not finished";
  ok($sg->has_audio                           , 'audio detected ok');
}
ok($sg->has_video                             , 'video detected ok');

is($sg->album, 'The Living Trees'             , 'streamgroup album ok');
is($sg->author, 'AIMS Multimedia'             , 'streamgroup author ok');
is($sg->bit_rate, 357472                      , 'streamgroup bit_rate ok');
is($sg->comment, 'The Living Trees'           , 'streamgroup comment ok');
is($sg->copyright, '(C) 2002 AIMS Multimedia' , 'streamgroup copyright ok');
is($sg->data_offset, 4368                     , 'streamgroup data_offset ok');
is($sg->file_size, 292368                     , 'streamgroup file_size ok');
is($sg->format->name, 'asf'                   , 'streamgroup format ok');
is($sg->genre, ''                             , 'streamgroup genre ok');
is($sg->track, 1                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');

$fname = "eg/t3.asf";

#if(0){ #########################################################

ok($ff = FFmpeg->new(input_file => $fname)    , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok($sg = $ff->create_streamgroup              , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^4021/,                , 'streamgroup duration correct');
#ok($sg->duration->isa('Time::Piece')          , 'object correct type');
#is($sg->duration->hms, '02:18:36'             , 'streamgroup duration correct');
is(scalar($sg->streams), 2                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 1, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 1, 'audio stream count correct');

ok($sg->has_audio                             , 'audio detected ok');
ok($sg->has_video                             , 'video detected ok');

is($sg->album, ''                             , 'streamgroup album ok');
is($sg->author, 'UnKnôwn - Founder of [PC]'   , 'streamgroup author ok');
is($sg->bit_rate, 13                          , 'streamgroup bit_rate ok');
is($sg->comment, ''                           , 'streamgroup comment ok');
is($sg->copyright, '#100_____collectors - DalNet','streamgroup copyright ok');
is($sg->data_offset, 921                      , 'streamgroup data_offset ok');
is($sg->file_size, 14234                      , 'streamgroup file_size ok');
is($sg->format->name, 'asf'                   , 'streamgroup format ok');
is($sg->genre, ''                             , 'streamgroup genre ok');
is($sg->track, 0                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');

#}
