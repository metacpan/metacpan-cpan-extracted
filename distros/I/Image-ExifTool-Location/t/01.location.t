use Test::More tests => 205;

BEGIN {
    use_ok( 'Image::ExifTool' );
    use_ok( 'Image::ExifTool::Location' );
}

my $exif = Image::ExifTool->new();

my @lat = ( 54.12345, 4, 0.333, 0, -0.333, -4, -80  );
my @lon = ( -30.54321, -0.4, 0, 0.4, 30.51231       );

for my $lat (@lat) {
    for my $lon (@lon) {
        ok($exif->ExtractInfo('t/mac.jpg'), 'extract');
        ok(!$exif->HasLocation(), 'has no location');
        $exif->SetLocation($lat, $lon);
        my $dst_bin;
        $exif->WriteInfo('t/mac.jpg', \$dst_bin);
        $exif->ExtractInfo(\$dst_bin);
        ok($exif->HasLocation(), 'has location');
        my ($glat, $glon) = $exif->GetLocation();
        is($glat, $lat);
        is($glon, $lon);
    }
}

my @alt = ( 10000, 100, 0.1, 0, -0.1, -100, -10000 );

for my $alt (@alt) {
    ok($exif->ExtractInfo('t/mac.jpg'), 'extract');
    ok(!$exif->HasElevation(), 'has no elevation');
    $exif->SetElevation($alt);
    my $dst_bin;
    $exif->WriteInfo('t/mac.jpg', \$dst_bin);
    $exif->ExtractInfo(\$dst_bin);
    ok($exif->HasElevation(), 'has elevation');
    my $galt = $exif->GetElevation();
    is($galt, $alt);
}
