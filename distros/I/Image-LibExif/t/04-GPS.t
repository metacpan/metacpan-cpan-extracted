#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;
use Image::LibExif;

SKIP:
for my $file (<t/images/GPS.jpg>) {
	my $info = image_exif $file;
	ok $info, 'have exif' or skip 7;
	is $info->{GPSLatitude},     '54.00, 59.38, 0.00', 'GPSLatitude';
	is $info->{GPSLatitudeRef},  'N',                  'GPSLatitudeRef';
	is $info->{GPSLongitude},    '1.00, 54.85, 0.00',  'GPSLongitude';
	is $info->{GPSLongitudeRef}, 'W',                  'GPSLongitudeRef';
	is $info->{GPSMapDatum},     'WGS84',              'GPSMapDatum';
	is $info->{GPSTimeStamp},    '14:58:24.00',        'GPSTimeStamp';
	is $info->{GPSVersionID},    '2.0.0.0',            'GPSVersionID';
	#for (grep /^GPS/,sort keys %$info) {
	#	printf "is \$info->{%-*s '%-*s '%s';\n", 17,$_.'},',20,$info->{$_}."',", $_;
	#}
}
