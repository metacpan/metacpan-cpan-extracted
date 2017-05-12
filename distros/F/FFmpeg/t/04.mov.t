use Test::More tests => 44;
use FFmpeg;
use Data::Dumper;

my $fname = "eg/t1.mov";

ok(my $ff = FFmpeg->new(input_file => $fname) , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok(my $sg = $ff->create_streamgroup           , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^5/                    , 'object correct type');
is(scalar($sg->streams), 2                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 1, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 1, 'audio stream count correct');

ok($sg->has_audio                             , 'audio detected ok');
ok($sg->has_video                             , 'video detected ok');

is($sg->album, ''                             , 'streamgroup album ok');
is($sg->author, ''                            , 'streamgroup author ok');
is($sg->bit_rate, 131832                      , 'streamgroup bit_rate ok');
is($sg->comment, ''                           , 'streamgroup comment ok');
is($sg->copyright, ''                         , 'streamgroup copyright ok');
is($sg->data_offset, 2005                     , 'streamgroup data_offset ok');
is($sg->file_size, 82395                      , 'streamgroup file_size ok');
is($sg->format->name, 'mov,mp4,m4a,3gp,3g2,mj2', 'streamgroup format ok');
is($sg->genre, ''                             , 'streamgroup genre ok');
is($sg->track, 0                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');

#warn Dumper($sg);

$fname = "eg/t2.mov";

ok($ff = FFmpeg->new(input_file => $fname)    , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok($sg = $ff->create_streamgroup              , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^5/                    , 'streamgroup duration correct');
is(scalar($sg->streams), 1                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 1, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 0, 'audio stream count correct');

ok(!$sg->has_audio                            , 'audio detected ok');
ok($sg->has_video                             , 'video detected ok');

is($sg->album, ''                             , 'streamgroup album ok');
is($sg->author, ''                            , 'streamgroup author ok');
is($sg->bit_rate, 372231                      , 'streamgroup bit_rate ok');
is($sg->comment, ''                           , 'streamgroup comment ok');
is($sg->copyright, ''                         , 'streamgroup copyright ok');
is($sg->data_offset, 1252                     , 'streamgroup data_offset ok');
is($sg->file_size, 257460                     , 'streamgroup file_size ok');
is($sg->format->name, 'mov,mp4,m4a,3gp,3g2,mj2', 'streamgroup format ok');
is($sg->genre, ''                             , 'streamgroup genre ok');
is($sg->track, 0                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');
