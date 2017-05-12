use Test::More tests => 4;
BEGIN { use_ok('Mediainfo') };

SKIP: {
    eval {system("mediainfo") == 65280 or die "mediainfo not installed"};

    skip "mediainfo not installed" , 3 if $@;

    use Mediainfo;
    my $file = "t/media/foo.mpg";
    my $foo_info = new Mediainfo("filename" => $file);
    is( $foo_info->{filename},     "t/media/foo.mpg", "filename");
    is( $foo_info->{container},    "mpeg-ps",         "container");
    is( $foo_info->{video_codec},  "mpeg-1v",         "video_codec");
}


