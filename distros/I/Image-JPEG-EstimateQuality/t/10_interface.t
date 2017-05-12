use strict;
use warnings;
use Test::More;
use IO::File;

use Image::JPEG::EstimateQuality;

ok jpeg_quality('t/img/q080.jpg') > 0, "filename";

open my $fh, '<', 't/img/q070.jpg'  or die $!;
ok jpeg_quality($fh) > 0, "file handle";
close $fh;

my $iof = IO::File->new('t/img/q050.jpg', 'r');
ok jpeg_quality($iof) > 0, "IO::Handle-like";
$iof->close();

my $data = join "", map { chr hex $_ } split(/\s+/, <<'END_IMAGE');
ff d8 ff e0 00 10 4a 46 49 46 00 01 01 01 00 48
00 48 00 00 ff db 00 43 00 1b 12 14 17 14 11 1b
17 16 17 1e 1c 1b 20 28 42 2b 28 25 25 28 51 3a
3d 30 42 60 55 65 64 5f 55 5d 5b 6a 78 99 81 6a
71 90 73 5b 5d 85 b5 86 90 9e a3 ab ad ab 67 80
bc c9 ba a6 c7 99 a8 ab a4 ff db 00 43 01 1c 1e
1e 28 23 28 4e 2b 2b 4e a4 6e 5d 6e a4 a4 a4 a4
a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4
a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4
a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 a4 ff c0
00 11 08 00 10 00 10 03 01 21 00 02 11 01 03 11
01 ff c4 00 16 00 01 01 01 00 00 00 00 00 00 00
00 00 00 00 00 00 04 00 05 ff c4 00 1c 10 00 02
02 02 03 00 00 00 00 00 00 00 00 00 00 00 01 02
03 04 00 11 13 22 41 ff c4 00 16 01 01 01 01 00
00 00 00 00 00 00 00 00 00 00 00 00 05 03 04 ff
c4 00 19 11 00 02 03 01 00 00 00 00 00 00 00 00
00 00 00 00 01 03 00 04 12 05 ff da 00 0c 03 01
00 02 11 03 11 00 3f 00 78 09 5a 3e 38 c7 6f 4e
1a c4 eb 5d 0b 39 db 1c c7 cf 41 6b 34 61 f7 5a
5e dc 89 58 9d 6b a1 67 3b 63 99 44 bd 99 39 24
3d 7c 18 dd 35 04 ab 46 53 9c 82 d6 68 cf ff d9
END_IMAGE

ok jpeg_quality(\$data) > 0, "image data";

done_testing;
