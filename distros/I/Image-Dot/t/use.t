#!/usr/bin/env perl -w 
use strict; 
use Test; 
BEGIN { plan tests => 4 } 

use Image::Dot;
ok(1);

my $dot;

$dot = dot_PNG_RGB(0, 0, 0);
ok(1);
$dot = dot_PNG_RGBA(0, 0, 0, 0);
ok(1);
$dot = dot_GIF_transparent;
ok(1);

exit; 
__END__ 

