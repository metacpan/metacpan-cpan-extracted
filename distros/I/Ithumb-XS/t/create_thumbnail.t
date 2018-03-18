#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Ithumb::XS') };

# Source image have dimension 5x3 px.
my $IMG_SRC = 't/src.png';
my $IMG_OUT = 't/src_thumb.png';

ok(
    Ithumb::XS::create_thumbnail($IMG_SRC, 2, 2, $IMG_OUT),
    "create_thumbnail()"
); 

unlink $IMG_OUT if -f $IMG_OUT;

done_testing(2);
