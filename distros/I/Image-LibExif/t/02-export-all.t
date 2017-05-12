#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Image::LibExif',':all') };
ok defined &image_exif, 'have image_exif';
ok !defined &import, 'have no import';
