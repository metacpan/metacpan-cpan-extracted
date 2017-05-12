# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 11_inspectpixels.t'

#########################

use Test::More tests => 42;
BEGIN { use_ok('Image::PBMlib') };
use Data::Dumper;

use strict;

use vars qw( $set $val $wantval @pix %report
             $error $deep $width $height $pixels $bytes $encode $type );

# does 2 or 9 tests
sub checkset {
  if(defined($wantval)) {
    ok($val == $wantval, "$set: pixel count");
  } else {
    ok(!defined($val), "$set: undef pixel count");
  }

  if(defined($error)) {
    ok($report{error} eq $error, "$set: expected error message");
    return;
  } else {
    ok( ( (!exists($report{error})) or
          (! defined( $report{error})) or
          (0 == length($report{error})) ), "$set: no error expected" ); 
  }

  ok($report{deep} eq $deep, "$set: array depth");

  ok($report{type} eq $type, "$set: output $report{type}");

  if(defined($width)) {
    ok($report{width} == $width, "$set: width");
  } else {
    ok(!defined($report{width}), "$set: undef width");
  }

  if(defined($height)) {
    ok($report{height} == $height, "$set: height");
  } else {
    ok(!defined($report{height}), "$set: undef height");
  }

  ok($report{pixels} == $pixels, "$set: pixels");

  ok($report{bytes} == $bytes, "$set: bytes");

  ok($report{encode} eq $encode, "$set: encode");

}

# failures: 2 tests each
# tests 2..3
$set = 'inspectpixels undef000';
@pix = ( [ undef, 0, 0, 0],);
$val = inspectpixels('RAW', 1, \@pix, \%report);
  $wantval = undef;
  $error = 'first pixel undef';
checkset();

# tests 4..5
$set = 'inspectpixels 00undef0';
@pix = ( '0:', '0:', undef, '0:',);
$val = inspectpixels('ASCII', 3700, \@pix, \%report);
  $wantval = undef;
  $error = 'pixel undef';
checkset();

# tests 6..7
$set = 'inspectpixels 00001';
@pix = ( [ '0:', '0:'], ['0:', '0/', 1] );
$val = inspectpixels('float', 3700, \@pix, \%report);
  $wantval = undef;
  $error = 'invalid format';
checkset();

# tests 8..9
$val = inspectpixels('raw', 3700, \@pix, \%report);
  $wantval = undef;
  $error = 'gray pixel encoded wrong';
checkset();

# tests 10..11
$set = 'inspectpixels 0:0:0,0/0/0';
@pix = ( [ '0:0:0', '0/0/0'], );
$val = inspectpixels('raw', 3700, \@pix, \%report);
  $wantval = undef;
  $error = 'rgb pixel encoded wrong';
checkset();

# tests 12..13
$set = 'inspectpixels 0:,0:,0,0:,0:,0';
@pix = ( [ [ '0:', '0:', '0'] , [ '0:', '0:', '0:' ], ] );
$val = inspectpixels('raw', 3700, \@pix, \%report);
  $wantval = undef;
  $error = 'rgb pixel array encoded wrong';
checkset();

# tests 14..15
$set = 'inspectpixels 0:,0:,0:,0:0:0';
@pix = ( [ [ '0:', '0:', '0:'] , '0:0:0' ] );
$val = inspectpixels('raw', 3700, \@pix, \%report);
  $wantval = undef;
  $error = 'rgb pixel not array';
checkset();

# successes: 9 tests each
# tests 16..24
$set = 'inspectpixels 0:0:0,0:0:0...';
@pix = ( [ '0:0:0', '0:0:0', '0:0:0', ], [ '0:0:0', '0:0:0', '0:0:0', ] );
$val = inspectpixels('raw', 3700, \@pix, \%report);
  $wantval = 6;
  $error = undef;
  $width = 3;
  $height = 2;
  $pixels = $width * $height;
  $type = 6;
  $bytes = 2;
  $deep = '2d';
  $encode = 'dec';
checkset();

# tests 25..33
$set = 'inspectpixels [0/ 0/ 0/] ...';
@pix = ( [ [ '0/', '0/', '0/' ], [ '0/', '0/', '0/' ], ],
	 [ [ '0/', '0/', '0/' ], [ '0/', '0/', '0/' ], ],
	 [ [ '0/', '0/', '0/' ], [ '0/', '0/', '0/' ], ],
	 [ [ '0/', '0/', '0/' ], [ '0/', '0/', '0/' ], ], );
$val = inspectpixels('ascii', 37, \@pix, \%report);
  $wantval = 8;
  $error = undef;
  $width = 2;
  $height = 4;
  $pixels = $width * $height;
  $type = 3;
  $bytes = 1;
  $deep = '3d';
  $encode = 'hex';
checkset();

# tests 34..42
$set = 'inspectpixels 0.1, 0.1,  ...';
@pix = ( '0.1,', '0.1,', '0.1,', '0.1,', '0.1,', '0.1,', '0.1,', );
$val = inspectpixels('raw', 37, \@pix, \%report);
  $wantval = 7;
  $error = undef;
  $width = undef;
  $height = undef;
  $pixels = $wantval;
  $type = 5;
  $bytes = 1;
  $deep = '1d';
  $encode = 'float';
checkset();

