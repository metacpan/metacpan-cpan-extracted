use Test::More tests => 22;
use FFmpeg;
use Data::Dumper;

my $fname = "eg/t1.mp3";

ok(my $ff = FFmpeg->new(input_file => $fname) , 'ff object created successfully');
ok($ff->isa('FFmpeg')                         , 'object correct type');
ok(my $sg = $ff->create_streamgroup           , 'streamgroup object created successfully');
ok($sg->isa('FFmpeg::StreamGroup')            , 'object correct type');

like($sg->duration, qr/^1/                    , 'streamgroup duration correct');
is(scalar($sg->streams), 1                    , 'stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Video')} $sg->streams), 0, 'video stream count correct');
is(scalar(grep {$_->isa('FFmpeg::Stream::Audio')} $sg->streams), 1, 'audio stream count correct');

ok($sg->has_audio                             , 'audio detected ok');
ok(!$sg->has_video                            , 'video detected ok');

is($sg->album, '                              ','streamgroup album ok');
is($sg->author, 'Le Chat                       ','streamgroup author ok');
is($sg->bit_rate, 128000                      , 'streamgroup bit_rate ok');
is($sg->comment, '                              ','streamgroup comment ok');
is($sg->copyright, ''                         , 'streamgroup copyright ok');
is($sg->data_offset, 0                        , 'streamgroup data_offset ok');
is($sg->file_size, 21090                      , 'streamgroup file_size ok');
is($sg->format->name, 'mp3'                   , 'streamgroup format ok');
is($sg->genre, 'Blues'                        , 'streamgroup genre ok');
is($sg->track, 0                              , 'streamgroup track ok');
is($sg->url, $fname                           , 'streamgroup url ok');
is($sg->year, 0                               , 'streamgroup year ok');

#warn Dumper($sg);
