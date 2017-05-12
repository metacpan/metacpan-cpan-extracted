use strict;
use warnings;
use Test::More tests => 1;
use Image::JpegCheck;

{
    local $@;
    eval { is_jpeg([]) };
    like $@, qr/is_jpeg requires file-glob or filename/;
}

