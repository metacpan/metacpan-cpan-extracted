# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 12_encodepixels.t'

#########################

use Test::More tests => 22;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val @pix %expect_pix );

%expect_pix = (
# encoding for ascii files
  'enc1'    => "0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 \n",
  'enc10'   => "0 0 0 0 0 10 10 0 0 0 0 0 0 10 10 0 0 0 0 0 \n",
  'enc1000' => "0 0 0 0 0 1000 1000 0 0 0 0 0 0 1000 1000 0 0 0 0 0 \n",
  'enc10rgb' => "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 10 10 10 10 10 10 0 0 0 0 0 0 0 0 0 0 0 \n" .
                "0 0 0 0 0 0 0 10 10 10 10 10 10 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \n",
  'enc1000rgb' => "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1000 1000 1000 1000 1000 1000 0 0 0 0 0 \n" .
                  "0 0 0 0 0 0 0 0 0 0 0 0 0 1000 1000 1000 1000 1000 1000 0 0 0 0 0 0 0 \n" .
                  "0 0 0 0 0 0 0 0 \n",

# encoding for raw files
  'enc!~!' => '!~!',
  'encx8x' => 'x8x',
  'encABC' => 'ABCDEFGHI',
  'encAABBCC' => 'AABBCCDDEEFF',
  'encXYZ' => 'XXYYZZ',
  'encx8xbad' => "x8x\0\0",
);


@pix = (
  [ 0, 0, 0, 0],
  [ 0, 1, 1, 0],
  [ 0, 0, 0, 0],
  [ 0, 1, 1, 0],
  [ 0, 0, 0, 0],
);
$val = encodepixels('ascii', 1, \@pix);
ok($val eq $expect_pix{enc1}, 'encodepixels p1 proper 4x5');

@pix = (
  [ 0, 0, 0, 0],
  [ 0, 1, 1, ],
  [ 0, 0, 0, 0, 0],
  [ 0, 1, 10, 0],
  [ 0, 0, 0],
);
$val = encodepixels('ascii', 1, \@pix);
ok($val eq $expect_pix{enc1}, 'encodepixels p1 awkward 4x5');

@pix = (
  0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0,
);
$val = encodepixels('ascii', 1, \@pix);
ok($val eq $expect_pix{enc1}, 'encodepixels p1 1-d 4x5');

@pix = (
  [ "0:",  0,  0, 0],
  [  0  , 10, 10, 0],
  [  0  ,  0,  0, 0],
  [  0  , 10, 10, 0],
  [  0  ,  0,  0, 0],
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10}, 'encodepixels p2 proper 4x5');

@pix = (
  [ "0:",  0,  0, 0],
  [  0  , 10, 10, 0],
  [  0  ,  0,],
  [0,0,0, 10,100, 0],
  [  0  ,  0,  0],
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10}, 'encodepixels p2 awkward 4x5');

@pix = (
  [ "0.0,",  0,  0, 0],
  [  0  , 1.0, 1.0, 0],
  [  0  ,  0,],
  [0,0,0, 1,10.0, 0],
  [  0  ,  0,  0],
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10}, 'encodepixels p2 awkward float 4x5');

@pix = (
  [ "0/",  0,  0, 0],
  [  0  , 'a', 'A', 0],
  [  0  ,  0,],
  [0,0,0, 'A/','AA/', 0],
  [  0  ,  0,  0],
);

$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10}, 'encodepixels p2 awkward hex 4x5');

@pix = (
  0, 0, 0, 0, 0, 10, 10, 0, 0, 0, 0, 0, 0, 10, 10, 0, 0, 0, 0, 0,
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10}, 'encodepixels p2 1-d 4x5');

@pix = (
  0, 0, 0, 0, 0, 1000, 1000, 0, 0, 0, 0, 0, 0, 1000, 1000, 0, 0, 0, 0, 0,
);
$val = encodepixels('ascii', 1000, \@pix);
ok($val eq $expect_pix{enc1000}, 'encodepixels p2 2byte 1-d 4x5');

@pix = (
  [ ["0:",0,0],    [0,0,0],    [0,0,0], [0,0,0]],
  [    [0,0,0], [10,10,10], [10,10,10], [0,0,0]],
  [    [0,0,0],    [0,0,0],    [0,0,0], [0,0,0]],
  [    [0,0,0], [10,10,10], [10,10,10], [0,0,0]],
  [    [0,0,0],    [0,0,0],    [0,0,0], [0,0,0]],
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10rgb}, 'encodepixels p3 3-d 4x5');

@pix = (
  [ '0:0:0',    '0:0:0',    '0:0:0', '0:0:0'],
  [ '0:0:0', '10:10:10', '10:10:10', '0:0:0'],
  [ '0:0:0',    '0:0:0',    '0:0:0', '0:0:0'],
  [ '0:0:0', '10:10:10', '10:10:10', '0:0:0'],
  [ '0:0:0',    '0:0:0',    '0:0:0', '0:0:0'],
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10rgb}, 'encodepixels p3 dec 2-d 4x5');

@pix = (
  [ '0/0/0', '0/0/0', '0/0/0', '0/0/0'],
  [ '0/0/0', 'A/A/A', 'A/A/A', '0/0/0'],
  [ '0/0/0', '0/0/0', '0/0/0', '0/0/0'],
  [ '0/0/0', 'A/A/A', 'A/A/A', '0/0/0'],
  [ '0/0/0', '0/0/0', '0/0/0', '0/0/0'],
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10rgb}, 'encodepixels p3 hex 2-d 4x5');

@pix = (
  [ '0.0,0.0,0.0', '0.0,0.0,0.0', '0.0,0.0,0.0', '0.0,0.0,0.0'],
  [ '0.0,0.0,0.0', '1.0,1.0,1.0', '1.0,1.0,1.0', '0.0,0.0,0.0'],
  [ '0.0,0.0,0.0', '0.0,0.0,0.0', '0.0,0.0,0.0', '0.0,0.0,0.0'],
  [ '0.0,0.0,0.0', '1.0,1.0,1.0', '1.0,1.0,1.0', '0.0,0.0,0.0'],
  [ '0.0,0.0,0.0', '0.0,0.0,0.0', '0.0,0.0,0.0', '0.0,0.0,0.0'],
);
$val = encodepixels('ascii', 10, \@pix);
ok($val eq $expect_pix{enc10rgb}, 'encodepixels p3 float 2-d 4x5');

@pix = (
 [ '0:0:0',          '0:0:0',          '0:0:0', '0:0:0'],
 [ '0:0:0', '1000:1000:1000', '1000:1000:1000', '0:0:0'],
 [ '0:0:0',          '0:0:0',          '0:0:0', '0:0:0'],
 [ '0:0:0', '1000:1000:1000', '1000:1000:1000', '0:0:0'],
 [ '0:0:0',          '0:0:0',          '0:0:0', '0:0:0'],
);
$val = encodepixels('ascii', 1000, \@pix);
ok($val eq $expect_pix{enc1000rgb}, 'encodepixels p3 2-byte 2-d 4x5');

@pix = (
  [ qw( 0 0 1 0 0 0 0 1 ) ], 
  [ qw( 0 1 1 1 1 1 1 0 ) ],
  [ qw( 0 0 1 0 0 0 0 1 ) ]
);
$val = encodepixels('raw', 1, \@pix);
ok($val eq $expect_pix{'enc!~!'}, 'encodepixels p4 8x3');

@pix = (
  [ qw( 0 1 1 1 1 ) ],
  [ qw( 0 0 1 1 1 ) ],
  [ qw( 0 1 1 1 1 ) ]
);
$val = encodepixels('raw', 1, \@pix);
ok($val eq $expect_pix{'encx8x'}, 'encodepixels p4 5x3');

@pix = (
  [ qw( 0 1 1 1 1 0 ) ],
  [ qw( 0 0 1 1 1   ) ],
  [ qw( 0 1 1 1 1   ) ]
);
$val = encodepixels('raw', 1, \@pix);
ok($val eq $expect_pix{'encx8xbad'}, 'encodepixels p4 bad 6x3');

@pix = (
  [ "58/", "58/" ],
  [ "59/", "59/" ],
  [ "5A/", "5A/" ],
);
$val = encodepixels('raw', 255, \@pix);
ok($val eq $expect_pix{'encXYZ'}, 'encodepixels p5 2x3');

@pix = (
  [ "0.3450980," ],
  [ "0.3490196," ],
  [ "0.3529411," ],
);
$val = encodepixels('raw', 65535, \@pix);
ok($val eq $expect_pix{'encXYZ'}, 'encodepixels p5 1x3');

@pix = (
  [ "65:66:67" ],
  [ "68:69:70" ],
  [ "71:72:73" ]
);
$val = encodepixels('raw', 255, \@pix);
ok($val eq $expect_pix{'encABC'}, 'encodepixels p6 1x3');

@pix = (
  [ [ "16705:", 16962, 17219 ], [ 17476, 17733, 17990 ] ]
);
$val = encodepixels('raw', 65535, \@pix);
ok($val eq $expect_pix{'encAABBCC'}, 'encodepixels p6 2x1');

