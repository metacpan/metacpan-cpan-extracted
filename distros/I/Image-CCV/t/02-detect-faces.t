#!perl -w
use strict;
use warnings;

# This is mainly a safeguard-test to check that the hardcoded
# class names XS/Inline::C generate match up with what my
# Perl code expects
use Test::More tests => 3;

use Image::CCV;

my @faces = detect_faces('t/face_IMG_0762_bw_small.png');

is 0+@faces, 1, "We find one face";

my $confidence = pop @{ $faces[0] || [] };

is_deeply $faces[0], [
  '37',
  '33',
  '26',
  '26',
], "We detect the face at the expected co-ordinates";
  
cmp_ok abs($confidence - 5.346), '<=', 0.001, "We get a suitable confidence value";

# Most likely, this should be more lenient, especially towards
# the confidence value