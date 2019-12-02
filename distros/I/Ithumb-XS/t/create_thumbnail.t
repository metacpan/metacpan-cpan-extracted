#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('Ithumb::XS') };

# Source image have dimension 5x3 px.
use constant IMG_SRC => 't/src.png';
use constant IMG_OUT => 't/src_thumb.png';

ok(
    Ithumb::XS::convert_image({width => 2, height => 2, src_image => IMG_SRC, dst_image => IMG_OUT}),
    "create_thumbnail()"
);

unlink IMG_OUT if -f IMG_OUT;

eval {
    Ithumb::XS::convert_image({width => -2, height => 2, src_image => IMG_SRC, dst_image => IMG_OUT});
} or do {
    like($@, qr/invalid value of width/i, 'check with invalid width');
};

eval {
    Ithumb::XS::convert_image({width => 2, height => -2, src_image => IMG_SRC, dst_image => IMG_OUT});
} or do {
    like($@, qr/invalid value of height/i, 'check with invalid height');
};

eval {
    Ithumb::XS::convert_image({width => 2, height => 2, src_image => 'invalid_file.png', dst_image => IMG_OUT});
} or do {
    like($@, qr/file does not exist/i, 'check not exists file');
};

done_testing();
