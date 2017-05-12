# -*- perl -*-

# t/01_basic.t - basic tests

use Test::Most tests => 14+1;
use Test::NoWarnings;

use Mac::iPhoto::Exif;
use Image::ExifTool;

my $iphoto_exif = Mac::iPhoto::Exif->new(
    iphoto_album    => 't/AlbumData.xml',
    backup          => 1,
);

$iphoto_exif->run;

ok(-e 't/_IMG_01.JPG','Backup has been created');

my $exif = Image::ExifTool->new(
    Charset => 'UTF8',
);

my $info1 = $exif->ImageInfo('t/IMG_01.JPG');
my $info2 = $exif->ImageInfo('t/IMG_02.JPG');

is($info1->{PersonInImage},'Andreas Ackerl, Bertram Bummérl','Persons in image ok');
is($info1->{UserComment},'Comment 01','Comment ok');
is($info1->{GPSLatitude},'1 deg 21\' 22.32" N','Latitude ok');
is($info1->{GPSLongitude},'103 deg 49\' 41.17" E','Longitude ok');
is($info1->{Keywords},'Tag1, Tag2','Keywords ok');
is($info1->{Rating},undef,'Rating ok');

is($info2->{PersonInImage},'Andreas Ackerl','Persons in image ok');
is($info2->{UserComment},undef,'Comment ok');
is($info2->{GPSLatitude},'1 deg 21\' 23.20" N','Latitude ok');
is($info2->{GPSLongitude},'103 deg 14\' 3.24" E','Longitude ok');
is($info2->{Keywords},'Tag2','Keywords ok');
is($info2->{Rating},'3','Rating ok');

# Clean up after test
unlink('t/IMG_01.JPG');
unlink('t/IMG_02.JPG');
rename('t/_IMG_01.JPG','t/IMG_01.JPG');
rename('t/_IMG_02.JPG','t/IMG_02.JPG');

isa_ok($iphoto_exif,'Mac::iPhoto::Exif');

