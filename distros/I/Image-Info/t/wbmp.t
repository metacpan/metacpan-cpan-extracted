use strict;
use FindBin;
use Test::More;

plan tests => 4;

use Image::Info 'dim';
use Image::Info::WBMP 'wbmp_image_info';

my $img_dir = "$FindBin::RealBin/../img";

my $info = wbmp_image_info "$img_dir/test.wbmp";
my($w,$h) = dim $info;
is $info->{file_media_type}, "image/vnd.wap.wbmp";
is $info->{file_ext}, "wbmp";
is $w, 8;
is $h, 8;
