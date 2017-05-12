use strict;
use warnings;

use Test::More tests => 1;
use Image::DecodeQR;

my $string = Image::DecodeQR::decode('t/test.png');
is($string, 'http://m.livedoor.com/');

