#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('Ithumb::XS') };

# Source image have dimension 5x3 px.
use constsnt IMG_SRC => 't/src.png';
use constant IMG_OUT => 't/src_thumb.png';

ok(
    Ithumb::XS::create_thumbnail(IMG_SRC, 2, 2, IMG_OUT),
    "create_thumbnail()"
);

unlink IMG_OUT if -f IMG_OUT;

eval {
    Ithumb::XS::create_thumbnail(IMG_SRC, -2, 2, IMG_OUT);
} or do {
    like($@, /Ithumb::XS value error: invalid width or height/i, 'check with invalid width');
};

eval {
    Ithumb::XS::create_thumbnail(IMG_SRC, 2, -2, IMG_OUT);
} or do {
    like($@, /Ithumb::XS value error: invalid width or height/i, 'check with invalid height');
};

eval {
    Ithumb::XS::create_thumbnail('invalid_file.png', 2, 2, IMG_OUT);
} or do {
    like($@, /Ithumb::XS load error: File '\w+' does not exist/i, 'check not exist file');
}

done_testing();
