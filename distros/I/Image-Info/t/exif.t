#!/usr/bin/perl -w

use Test::More;
use strict;

# Some basic tests for Exif extraction. Highly incomplete.

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info dim);

my $i = image_info("../img/test.jpg") || die;

#use Data::Dumper; print Dumper($i), "\n";

is ($i->{DateTimeDigitized}, "1999:12:06 16:38:40", 'DateTimeDigitized');

is ($i->{Make}, "OLYMPUS OPTICAL CO.,LTD", 'Make');

# test parsing of MakerNote (especially that there are no trailing \x00):

# this is a "UNDEFINED" value with trailing zeros \x00:
is ($i->{'Olympus-CameraID'}, 'OLYMPUS DIGITAL CAMERA', 'Olympus-CameraID');

isnt ($i->{UserComment}, "ASCII", 'UserComment');
like ($i->{UserComment}, qr/^\s+\z/, 'UserComment');

is (dim($i), '320x240', 'dim()');
