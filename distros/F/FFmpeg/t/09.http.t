use Test::More tests => 9;
print STDERR "\nNetwork inaccessibility will cause tests in $0 to fail\n";
BEGIN {
        use_ok('FFmpeg');
        use_ok('Data::Dumper');
      };

my $url = "http://genomics.ctrl.ucla.edu/~allenday/ffmpeg.download.mpg";


my($ff,$sg);

ok($ff = FFmpeg->new(input_url => $url)          , 'ff object created successfully');
ok($sg = $ff->create_streamgroup()               , 'sg object created successfully');
ok($sg->has_video()                              , 'sg has video');
like($sg->duration(), qr/^5/                     , 'sg duration okay');

ok($ff = FFmpeg->new(input_url => $url,
                     input_url_referrer => 'http://foo.bar.com',
                     input_url_max_size => 50000), 'ff object created successfully');
ok($sg = $ff->create_streamgroup()               , 'sg object created successfully');
ok($sg->has_video()                              , 'sg has video');

