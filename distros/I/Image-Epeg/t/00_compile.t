use strict;
use warnings;
use Test::More tests => 1;
use_ok 'Image::Epeg';

diag "libjpeg version is : " . Image::Epeg::_epeg_libjpeg_version();
