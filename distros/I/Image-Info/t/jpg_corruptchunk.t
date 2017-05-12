use strict;
use FindBin;
use Test::More;

plan tests => 3;

use Image::Info 'dim', 'image_info';

my $img_dir = "$FindBin::RealBin/../img";

my $info = image_info "$img_dir/test-corruptchunk.jpg";
is $info->{Warn}, "Corrupt JPEG data, 4 extraneous bytes before marker 0xdb", 'found warn entry'
    or do { require Data::Dumper; diag(Data::Dumper->new([$info],[qw()])->Indent(1)->Useqq(1)->Dump) };
my($w,$h) = dim $info;
is $w, 8, 'dimensions could still be read';
is $h, 8;
