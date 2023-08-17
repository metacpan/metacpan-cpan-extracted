use warnings;
use strict;

use Test::More tests => 16;

use_ok "Image::Info", qw(image_info);

chdir 't' if -d 't';
my $i = image_info("../img/test.avif");
ok $i;
ok !exists($i->{error});
is $i->{file_media_type}, "image/avif";
is $i->{file_ext}, "avif";
is $i->{width}, 150;
is $i->{height}, 113;
is $i->{color_type}, "RGB";
ok !exists($i->{resolution});
is $i->{SamplesPerPixel}, 3;
is_deeply $i->{BitsPerSample}, [8,8,8];
ok !exists($i->{Comment});
ok !exists($i->{Interlace});
ok !exists($i->{Compression});
ok !exists($i->{Gamma});
ok !exists($i->{LastModificationTime});

1;
