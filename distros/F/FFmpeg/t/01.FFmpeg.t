use Test::More tests => 54;
BEGIN {
        use_ok('FFmpeg');
        use_ok('Data::Dumper');
      };

my $fname = "eg/t1.m2v";

ok(my $ff = FFmpeg->new(input_file => $fname) , 'ff object created successfully');
ok($ff->isa('FFmpeg')                                , 'object correct type');
is($ff->foo, 1234                                           , 'foo() call passed');

ok(my @file_formats = (sort {$a->name cmp $b->name} $ff->file_formats), 'file formats initialized');

#
# test file formats
#
ok(@file_formats = (sort {$a->name cmp $b->name} $ff->file_formats), 'file formats initialized');

#warn Dumper @file_formats;
#warn join "\n", map { $_ . ' = ' . $file_formats[$_]->name } 0..scalar(@file_formats)-1;

is(ref($file_formats[0]),'FFmpeg::FileFormat', 'file format objects created successfully');

is($file_formats[5]->name, 'ac3',             'ac3 format available');
is($file_formats[5]->can_read,  1,            'ac3 format readable');
is($file_formats[5]->can_write, 1,            'ac3 format writable');
is($file_formats[5]->description, 'raw ac3',  'ac3 description');
is($file_formats[5]->mime_type, 'audio/x-ac3','ac3 mime');

is($file_formats[10]->name, 'asf',                'asf_stream format available');
is($file_formats[10]->can_read,  1,               'asf_stream format readable');
is($file_formats[10]->can_write, 1,               'asf_stream format writable');
is($file_formats[10]->description, 'asf format',  'asf_stream description');
is($file_formats[10]->mime_type, 'video/x-ms-asf','asf_format mime');

is($file_formats[19]->name, 'dv',                    'dv format available');
is($file_formats[19]->can_read,  1,                  'dv format readable');
is($file_formats[19]->can_write, 1,                  'dv format writable');
is($file_formats[19]->description, 'DV video format','dv description');
is($file_formats[19]->mime_type, undef,              'dv mime');

is_deeply($ff->file_format('ac3'), $file_formats[5], 'file_format retrieval successful');
is_deeply($ff->file_format('asf'), $file_formats[10], 'file_format retrieval successful');

is_deeply($ff->file_format('dv'),  $file_formats[19],'file_format retrieval successful');

#
# test image formats
#
ok(my @image_formats = (sort {$a->name cmp $b->name} $ff->image_formats), 'image formats initialized');

#warn Dumper \@image_formats;
#warn join "\n", map { $_ . ' = ' . $image_formats[$_]->name } 0..scalar(@image_formats)-1;

is(ref($image_formats[0]),'FFmpeg::ImageFormat', 'image format objects created successfully');

is($image_formats[0]->name, 'gif',         'gif format available');
is($image_formats[0]->can_read,  1,        'gif format readable');
is($image_formats[0]->can_write, 1,        'gif format writable');

#gif is the only format now! -allenday 20050302
#is($image_formats[2]->name, 'yuv',         'yuv format available');
#is($image_formats[2]->can_read,  1,        'yuv format not readable');
#is($image_formats[2]->can_write, 1,        'yuv format writable');

is_deeply($ff->image_format('gif'), $image_formats[0], 'image_format retrieval successful');
#is_deeply($ff->image_format('yuv'), $image_formats[2], 'image_format retrieval successful');

#
# test codecs
#
ok(my @codecs = (sort {$a->name cmp $b->name} $ff->codecs), 'codecs initialized');

#warn Dumper(sort {$a->id <=> $b->id} @codecs);
#warn join "\n", map { $_ . ' = ' . $codecs[$_]->name } 0..scalar(@codecs)-1;

is(ref($codecs[0]),'FFmpeg::Codec', 'codec objects created successfully');

is($codecs[0]->name, '4xm',         '4xm codec available');
is($codecs[0]->can_read,  1,        '4xm codec readable');
is($codecs[0]->can_write, 0,        '4xm codec not writable');
is($codecs[0]->is_video, 1,         '4xm codec is video');
is($codecs[0]->is_audio, 0,         '4xm codec is not audio');
is($codecs[0]->id, 35,              '4xm codec id');

is($codecs[4]->name, 'ac3',         'ac3 codec available');
is($codecs[4]->can_read,  1,        'ac3 codec not readable');
is($codecs[4]->can_write, 1,        'ac3 codec writable');
is($codecs[4]->is_video, 0,         'ac3 codec is not video');
is($codecs[4]->id, 86020,           'ac3 codec id');

is($codecs[20]->name, 'adpcm_xa',   'adpcm_xa codec available');
is($codecs[20]->can_read,  1,       'adpcm_xa codec readable');
is($codecs[20]->can_write, 1,       'adpcm_xa codec writable');
is($codecs[20]->is_video, 0,        'adpcm_xa codec is video');
is($codecs[20]->is_audio, 1,        'adpcm_xa codec is not audio');
is($codecs[20]->id, 69640,          'adpcm_xa codec id');

is_deeply($ff->codec('4xm'),      $codecs[0], 'codec retrieval successful');
is_deeply($ff->codec('ac3'),      $codecs[4], 'codec retrieval successful');
is_deeply($ff->codec('adpcm_xa'), $codecs[20],'codec retrieval successful');

