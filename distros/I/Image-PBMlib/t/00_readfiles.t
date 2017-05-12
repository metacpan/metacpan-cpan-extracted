# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 00_readfiles.t'

#########################

use Test::More tests => 119;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( @files $three %expect_pix $file %i %p $m
             $rc $bgp $format $size $type $bbb $pspsps
           );

# All ten images are the same, but the can be encoded as bitmap (1,4),
# graymap (2,5), or pixmap(4,6), in ascii (1-3) or raw (4-6), and (for the
# non-bitmaps) with 1 or 2 bytes per value.
@files = ( 'p1.pnm',
           'p2-1byte.pnm',
           'p2-2byte.pnm',
           'p3-1byte.pnm',
           'p3-2byte.pnm',
           'p4.pnm',
           'p5-1byte.pnm',
           'p5-2byte.pnm',
           'p6-1byte.pnm',
           'p6-2byte.pnm',
         );

# this image is three copies of p4.pnm in one file
$three =   'three-image-p4.pnm';

if ( ! -f $three ) {
  chdir 't';
}

# Image looks like:
#       @@@@
#       @--@
#       @@@@
#       @--@
#       @@@@
# $" is array separator in double quoted context.
$" = '*';
%expect_pix = (

# reads from files

  'b' => '1*1*1*1*1*0*0*1*1*1*1*1*1*0*0*1*1*1*1*1',

  'g' => '1.0,*1.0,*1.0,*1.0,*1.0,*0.0,*0.0,*1.0,*1.0,*1.0,*1.0,*1.0,*1.0,*0.0,*0.0,*1.0,*1.0,*1.0,*1.0,*1.0,',

  'p' => '1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*0.0,0.0,0.0*0.0,0.0,0.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*0.0,0.0,0.0*0.0,0.0,0.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0*1.0,1.0,1.0',

);

# does 9 tests
sub checkfile {

  # 1
  ok($rc eq '', "$file: readpnmfile return code");

  # 2
  ok($i{$file}{error} eq '', "$file: error string $i{$file}{error}");

  # 3
  ok($i{$file}{bgp} eq $bgp, "$file: bpg '$i{$file}{bgp}' eq $bgp");

  # 4
  ok($i{$file}{format} eq $format, "$file: format '$i{$file}{format}' eq $format");

  # 5
  ok($i{$file}{type} eq $type, "$file: type '$i{$file}{type}' eq $type");

  # 6
  ok($i{$file}{width} == 4, "$file: width '$i{$file}{width}' == 4");

  # 7
  ok($i{$file}{height} == 5, "$file: height '$i{$file}{height}' == 5");

  # 8
  ok($i{$file}{pixels} == 20, "$file: pixels '$i{$file}{pixels}' == 20");

  # stringify!
  my $ps = '';
  my $n;
  for $n (0..4) {
    my $r = $p{$file}[$n];
    $ps .= "@{$r}" . $";
  }
  chop($ps);

  # 9
  ok($ps eq $expect_pix{$bgp}, "$file stringified image is $ps");

  return $ps; 	# used for final test only
}

# calls checkfile on 8 files (8*9 == 72 tests)
for $file (@files) {
  if ($file =~ /\bp([14])[.]/i) {
    $type   = $1;
    $size   = 0;
    $bgp    = 'b';
  } elsif ($file =~ /\bp([2356])-([12])byte[.]/i) {
    $type   = $1;
    $size   = $2;
    if($type == 2 or $type == 5) {
      $bgp  = 'g';
    } else {
      $bgp  = 'p';
    }
  } else {
    fail("unexpected file name");
  }

  if($type < 4) {
    $format = 'ascii';
  } else {
    $format = 'raw';
  }

  if(!open(STREAM, "<:raw", $file)) {
    fail("open $file: $!");
  }

  # make the hash and array exist.
  $i{$file}{filename} = $file;
  $p{$file}[0] = ( undef );

  $rc = readpnmfile( \*STREAM, $i{$file}, $p{$file}, "float" );

  close STREAM;

  checkfile();

}

$file   = $three;
$type   = 4;
$format = 'raw';
$bgp    = 'b';
if(!open(STREAM, "<:raw", $file)) {
  fail("open $file: $!");
}

$pspsps = '';
$bbb    = $expect_pix{$bgp} . $expect_pix{$bgp} . $expect_pix{$bgp};

# calls checkfile() 3 times (3*9 == 27 tests)
for $m (0..2) {
  $file = "$three:$m";

  # make the hash and array exist.
  $i{$file}{filename} = $file;
  $p{$file}[0] = ( undef );

  $rc = readpnmfile( \*STREAM, $i{$file}, $p{$file}, "float" );

  $pspsps .= checkfile();
}

close STREAM;

ok($pspsps eq $bbb, "three image $three stringified as $pspsps");
__END__
:set nopaste
:set paste
