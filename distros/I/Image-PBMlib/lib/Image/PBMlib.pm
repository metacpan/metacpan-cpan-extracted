#! perl -w
# A PBM/PGM/PPM library.
# Benjamin Elijah Griffin       28 Feb 2012
# elijah@cpan.org

package Image::PBMlib;
use 5.010000;
use strict;
use warnings;

use vars qw( @ISA @EXPORT );
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(  readpnmfile checkpnminfo readpnmheader readpnmpixels
	       makepnmheader encodepixels writepnmfile inspectpixels
	       explodetriple rescaleval rescaletriple
	       hextripletofloat dectripletofloat
	       hexvaltofloat decvaltofloat
	       floattripletodec floattripletohex
	       floatvaltodec floatvaltohex
	       comparefloatval comparefloattriple
	       comparepixelval comparepixeltriple
	    );

$Image::PBMlib::VERSION = '2.00';

=head1 NAME

Image::PBMlib - Helper functions for PBM/PGM/PPM image file formats

=head1 SYNOPSIS

    use Image::PBMlib;

    ... open(PNM, '<:raw', "image.ppm")...

    my (%info, @pixels);
    # fourth is encoding of float, dec, or hex
    readpnmfile( \*PNM, \%info, \@pixels, 'float' );
    # sets $info{error} if an error

    readpnmheader( \*PNM, \%info );
    # sets $info{error} if an error

    checkpnminfo( \%info );
    # sets $info{error} if an error

    # float, dec, or hex
    readpnmpixels( \*PNM, \%info, \@pixels, 'float') 
    # sets $info{error} if an error

    # R/G/B to RRRR/GGGG/BBBB, max 1 to 65535
    my $rgb = hextripletofloat( "F00/B/A4", $maxvalue );

    # R:G:B, max 1 to 65535
    my $rgb = dectripletofloat( "3840:11:164", $maxvalue );

    # returns the number of bytes written, as a positive
    # number if no error, and zero or -1*bytes if error
    my $return = writepnmfile(\*PNM, \%info, \@pixels);

    # this header can contain comments
    my $header = makepnmheader(\%info);

    # this header will not contain comments
    # 1 for ascii PBM, 2 for ascii PGM, 3 for ascii PPM,
    # 4 for raw   PBM, 5 for raw   PGM, 6 for raw   PPM
    my $header = makepnmheader('5', $width, $height, $maxvalue);

    # raw, dec, or hex format pixels, in 'raw' or 'ascii'
    # for writing to a file
    my $block = encodepixels('raw', $maxvalue, \@pixels);

=head1 DESCRIPTION

This is primarily a library for reading and writing portable bitmap (PBM), 
portable graymap (PGM), and portable pixmap (PPM) files. As a
set they are portable anymap (PNM). There is a separate PAM
format that is not yet supported. Within each format there are
two representations on disk, ASCII and RAW. ASCII is suitable
for raw email transmission, short lines, all 7-bit characters.
RAW is much more compact and generally preferred. A single RAW
formatted file can contain multiple concatenated images.

These image formats are only the barest step up from raw raster
data, and have a very simple format which is the key to be "portable".
Writing out images in these formats is very easy. Reading only
slightly more complicated.

=head2 Maxvalue

Version 1.x of this library had serious bugs except for the most
basic versions of PGM and PPM files, by not properly observing
the maxvalue. Version 2.x fixes that at a compatiblity cost. Raw
gray and color channel information is now stored as a floating
point number from 0.0 as full black to 1.0 as full white, and
it is scaled to the approprate maxvalue, which is a decimal integer
from 1 to 65535 inclusive.

=head2 Pixels

When this version of the library returns a pixel it will be:
"0" or "1" for PBM files; "0.0," to "1.0," for PGM in float
format, "0:" to "65535:" for PGM in decimal, "0/" to "FFFF/"
for PGM in hexadecimal; "0.0,0.0,0.0" to "1.0,1.0,1.0" for
PPM in float, "0:0:0" to "65535:65535:65535" for PPM in decimal,
and "FFFF/FFFF/FFFF" for PPM in hexadecimal. 

That is to say PBM files always return just zeros and ones,
regardless of float, dec, or hex settings.

PGM files return a floating point number, an unrescaled dec or
hex value, but always followed by a comma if float, a colon if
decimal, and a slash if hex. Unrescaled means that if the
maxvalue is 1000 (decimal integer), then white is "1.0," in
float, "1000:" in dec, and "3E8/" in hex.

PPM files return a RGB set of floating point numbers, an
unrescaled set of dec or hex values, which are always separated
by commas if float, colons if decimal, and slashes if hex. Be sure
to read what unscaled means in the previous paragraph.

Image::PBMlib likes pixels in a two dimensional array, but can
use a single dimensional array. 

=cut

BEGIN {
} # end BEGIN


# Internal read header function. Does not do argument checks.
sub int_readpnmheader {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $in = '';
  my $pre = '';
  my $no_comments;
  my $rc;

  $rc = read($gr, $in, 3);

  if (!defined($rc) or $rc != 3) {
    $$ir{error} = 'Read error or EOF on magic number';
    $$ir{fullheader} = $in;
    return;
  }

  if ($in =~ /\nP[123456]/) {
    # hmmm. bad concatenated file?
    my $peek;
    $rc = read($gr, $peek, 1);
    if($rc and $peek eq "\n") {
      $in =~ s/^\n//;
      $in .= "\n";
    }
  }

  if ($in =~ /^P([123456])\s/) {
    $$ir{type} = $1;
    if ($$ir{type} > 3) {
      $$ir{raw} = 1;
      $$ir{format} = 'raw';
    } else {
      $$ir{raw} = 0;
      $$ir{format} = 'ascii';
    }

    if ($$ir{type} == 1 or $$ir{type} == 4) {
      $$ir{max} = 1;
      $$ir{bgp} = 'b';
    } elsif ($$ir{type} == 2 or $$ir{type} == 5) {
      $$ir{bgp} = 'g';
    } else {
      $$ir{bgp} = 'p';
    }

    while(1) {
      $rc = read($gr, $in, 1, length($in));
      if (!defined($rc) or $rc != 1) {
	$$ir{error} = 'Read error or EOF during header';
        $$ir{fullheader} = $in;
	return;
      }

      # yes, really reset ir{comments} every time through loop
      $no_comments = $in;
      $$ir{comments} = '';
      while ($no_comments =~ /#.*\n/) {
        $no_comments =~ s/#(.*\n)/ /;
	$$ir{comments} .= $1;
      }

      if ($$ir{bgp} eq 'b') {
        if ($no_comments =~ /^P\d\s+(\d+)\s+(\d+)\s/) {
	  $$ir{width}  = $1;
	  $$ir{height} = $2;
	  $$ir{pixels} = $1*$2;
          last;
	}
      } else {
	# graymap and pixmap
        if ($no_comments =~ /^P\d\s+(\d+)\s+(\d+)\s+(\d+)\s/) {
	  $$ir{width}  = $1;
	  $$ir{height} = $2;
	  $$ir{max}    = $3;
	  $$ir{pixels} = $1*$2;
          last;
	}
      }
    } # while reading header

    $$ir{error} = '';
  } else {
    $$ir{error} = 'Wrong magic number';
  }

  $$ir{fullheader} = $in;
  return;
} # end &int_readpnmheader

# internal single value to float function
sub int_decvaltofloat {
  my $v = shift;
  my $m = shift;
  my $p;

  # eat our own dog food for indicating a decimal value
  $v =~ s/:$//;

  if($v >= $m) {
    $p = '1.0,';
  } elsif ($v == 0) {
    $p = '0.0,';
  } else {
    $p = sprintf('%0.8f,', ($v/$m));
  }

  return $p;
} # end &int_decvaltofloat

# internal RGB to float function
sub int_dectripletofloat {
  my $r = shift;
  my $g = shift;
  my $b = shift;
  my $m = shift;
  my $p;

  # eat our own dog food for indicating a decimal value
  $r =~ s/:$//;
  $g =~ s/:$//;
  $b =~ s/:$//;

  if($r > $m) { $r = $m; }
  if($g > $m) { $g = $m; }
  if($b > $m) { $b = $m; }

  $p = sprintf('%0.8f,%0.8f,%0.8f', ($r/$m), ($g/$m), ($b/$m));

  # paranoia: I don't trust floating point to get 1.0 exactly
  $p =~ s/1[.]\d+/1.0/g;

  # more compact
  $p =~ s/0[.]0+\b/0.0/g;

  return $p;
} # end &int_dectripletofloat

# internal single float to dec function
sub int_floatvaltodec {
  my $v = shift;
  my $m = shift;
  my $p;

  # eat our own dog food for indicating a float value
  $v =~ s/,$//;

  # 1/65535 is about .0000152590
  if($v >= 0.999999) {
    $p = "$m:";
  } elsif ($v <= 0.000001) {
    $p = '0:';
  } else {
    # counter-intuitive way to round to an interger, but int() is
    # rather broken.
    $p = sprintf('%1.0f:', ($v*$m));
  }

  return $p;
} # end &int_floatvaltodec

# internal RGB float to dec function
sub int_floattripletodec {
  my $r = shift;
  my $g = shift;
  my $b = shift;
  my $m = shift;
  my $p;

  $r = int_floatvaltodec($r, $m);
  $g = int_floatvaltodec($g, $m);
  $b = int_floatvaltodec($b, $m);

  $p = "$r$g$b";
  # remove final (extra) comma
  $p =~ s/,$//;

  return $p;
} # end &int_floattripletodec

# internal single float to hex function
sub int_floatvaltohex {
  my $v = shift;
  my $m = shift;
  my $p;

  # eat our own dog food for indicating a float value
  $v =~ s/,$//;

  # 1/65535 is about .0000152590
  if($v >= 0.999999) {
    $p = sprintf("%X/", $m);
  } elsif ($v <= 0.000001) {
    $p = '0/';
  } else {
    # counter-intuitive way to round to an interger, but int() is
    # rather broken.
    $p = sprintf("%X/", sprintf('%1.0f', ($v*$m)));
  }

  return $p;
} # end &int_floatvaltohex

# internal RGB float to hex function
sub int_floattripletodhex{
  my $r = shift;
  my $g = shift;
  my $b = shift;
  my $m = shift;
  my $p;

  $r = int_floatvaltohex($r, $m);
  $g = int_floatvaltohex($g, $m);
  $b = int_floatvaltohex($b, $m);

  $p = "$r$g$b";
  # remove final (extra) slash
  $p =~ s:/$::;

  return $p;
} # end &int_floattripletohex

# hands off to correct int_encodepixels_N type
sub int_encodepixels {
  my $type   = shift;
  my $p_r    = shift;
  my $deep   = shift;
  my $encode = shift;
  my $max    = shift;

  # most common to least common
  # type 7 is PAM, not supported here (yet)
  # types 1 and 4 are PBM and don't need a max

  if($type == 6) {
  	return int_encodepixels_6($p_r, $deep, $encode, $max);
  }
  if($type == 5) {
  	return int_encodepixels_5($p_r, $deep, $encode, $max);
  }
  if($type == 4) {
  	return int_encodepixels_4($p_r, $deep, $encode      );
  }
  if($type == 3) {
  	return int_encodepixels_3($p_r, $deep, $encode, $max);
  }
  if($type == 2) {
  	return int_encodepixels_2($p_r, $deep, $encode, $max);
  }
  if($type == 1) {
  	return int_encodepixels_1($p_r, $deep, $encode      );
  }

  # should never reach here
  return undef;

} # end &int_encodepixels

# Internal read pixels for P1: ascii bitmap. Does not do argument checks.
sub int_readpixels_1 {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $pr = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  my $used = 0;
  my $read;
  my $bit;
  my $w = 0;
  my $h = 0;

  while(defined($read = <$gr>)) {
    while($read =~ /\b(\d+)\b/g) {
      $bit = ($1)? 1 : 0;
      $$pr[$h][$w] = $bit;
      $used ++;
      if($used >= $$ir{pixels}) { last; }
      $w ++;
      if($w >= $$ir{width}) {
        $w = 0;
	$h ++;
      }
    }
  } # while read from file

  if($used < $$ir{pixels}) {
    $$ir{error} = 'type 1 read: not enough pixels';
  } else {
    $$ir{error} = '';
  }
} # end &int_readpixels_1

# Internal write pixels for P1: ascii bitmap. Does not do argument checks.
sub int_encodepixels_1 {
  my $pr   = shift; # pixel array ref
  my $deep = shift; # how deep is our array
  my $enc  = shift; # source pixel encoding

  my $w = 0;
  my $h = 0;
  my $out = '';
  my $wide = 0;
  my $pix;
  my $cur;

  if($deep eq '1d') { 
    # $#{array} returns counts starting at -1 for empty array
    $pix = 1+ $#{$pr};
    $cur = $$pr[$w];
  } else {
    # deep = 3d only allowed for P3/P6
    $pix = (1+ $#{$pr}) * (1+ $#{$$pr[0]});
    $cur = $$pr[$h][$w];
  }

  while($pix > 0) {
    $cur =~ s![,:/]$!!;
    if($enc eq 'float') {
      if($cur > 0.5) {
	$out .= '1 ';
      } else {
	$out .= '0 ';
      }
    } else {
      # for PBM, we assume $max is 1
      if($cur) {
	$out .= '1 ';
      } else {
	$out .= '0 ';
      }
    }

    $wide += 2;
    if($wide > 70) {
      $out .= "\n";
      $wide = 0;
    }

    $pix --;
    $w ++;
    if($deep eq '1d') {
      if(exists($$pr[$w]) and defined($$pr[$w])) {
        $cur = $$pr[$w];
      } else {
        $cur = 0;
      }
    } else {
      if(!exists($$pr[$h][$w])) {
        $w = 0;
	$h ++;
      }
      if(exists($$pr[$h][$w]) and defined($$pr[$h][$w])) {
        $cur = $$pr[$h][$w];
      } else {
        $cur = 0;
      }
    }
  } # while pix

  if($wide) {
    $out .= "\n";
  }
  return($out);
} # end &int_encodepixels_1

# Internal read pixels for P2: ascii graymap. Does not do argument checks.
sub int_readpixels_2 {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $pr = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  my $used = 0;
  my $read;
  my $val;
  my $pix;
  my $w = 0;
  my $h = 0;
  
  while(defined($read = <$gr>)) {
    while($read =~ /\b(\d+)\b/g) {
      $val = $1;

      if($enc eq 'dec') {
        $pix = "$val:";
      } elsif ($enc eq 'hex') {
        $pix = sprintf('%X:', $val);
      } else {
        if($val >= $$ir{max}) {
	  $pix = '1.0,';
	} elsif ($val == 0) {
	  $pix = '0.0,';
	} else {
	  $pix = sprintf('%0.8f,', $val/$$ir{max});
	}
      }

      $$pr[$h][$w] = $pix;
      $used ++;
      if($used >= $$ir{pixels}) { last; }
      $w ++;
      if($w >= $$ir{width}) {
        $w = 0;
	$h ++;
      }
    }
  } # while read from file

  if($used < $$ir{pixels}) {
    $$ir{error} = 'type 2 read: not enough pixels';
  } else {
    $$ir{error} = '';
  }
} # end &int_readpixels_2

# Internal write pixels for P2: ascii graymap. Does not do argument checks.
sub int_encodepixels_2 {
  my $pr   = shift; # pixel array ref
  my $deep = shift; # how deep is our array
  my $enc  = shift; # source pixel encoding
  my $max  = shift; # max value

  my $w = 0;
  my $h = 0;
  my $out = '';
  my $val;
  my $wide = 0;
  my $pix;
  my $cur;

  if($deep eq '1d') { 
    # $#{array} returns counts starting at -1 for empty array
    $pix = 1+ $#{$pr};
    $cur = $$pr[$w];
  } else {
    # deep = 3d only allowed for P3/P6
    $pix = (1+ $#{$pr}) * (1+ $#{$$pr[0]});
    $cur = $$pr[$h][$w];
  }

  while($pix > 0) {

    if($enc eq 'float') {
      $val = int_floatvaltodec($cur, $max);
      chop($val); # eat last ':'
    } elsif($enc eq 'hex') {
      $cur =~ s!/$!!;
      $val = hex($cur);
    } else {
      $cur =~ s!:$!!;
      $val = 0+$cur; # normalize numbers
    }

    if($val > $max) {
      $val = $max;
    }

    if(70 < ($wide + 1 + length($val))) {
      $wide = 0;
      $out .= "\n";
    }
    $out  .= $val . ' ';
    $wide += 1 + length($val);

    $pix --;
    $w ++;
    if($deep eq '1d') {
      if(exists($$pr[$w]) and defined($$pr[$w])) {
        $cur = $$pr[$w];
      } else {
        $cur = 0;
      }
    } else {
      if(!exists($$pr[$h][$w])) {
        $w = 0;
	$h ++;
      }
      if(exists($$pr[$h][$w]) and defined($$pr[$h][$w])) {
        $cur = $$pr[$h][$w];
      } else {
        $cur = 0;
      }
    }
  } # while pix

  if($wide) {
    $out .= "\n";
  }

  return($out);
} # end &int_encodepixels_2

# Internal read pixels for P3: ascii pixmap. Does not do argument checks.
sub int_readpixels_3 {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $pr = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  my $used = 0;
  my $read;
  my $val;
  my $pix;
  my $w = 0;
  my $h = 0;
  my $r;
  my $g;
  my $state = 'r';

  while(defined($read = <$gr>)) {
    while($read =~ /\b(\d+)\b/g) {
      $val = $1;

      if($enc eq 'dec') {
        $pix = "$val:";
      } elsif ($enc eq 'hex') {
        $pix = sprintf('%X:', $val);
      } else {
        if($val >= $$ir{max}) {
	  $pix = '1.0,';
	} elsif ($val == 0) {
	  $pix = '0.0,';
	} else {
	  $pix = sprintf('%0.8f,', $val/$$ir{max});
	}
      }

      if($state eq 'r') {
        $r = $pix;
	$state = 'g';
      } elsif($state eq 'g') {
        $g = $pix;
	$state = 'b';
      } else {

	chop($pix);
	$$pr[$h][$w] = "$r$g$pix";
	$used ++;
	if($used >= $$ir{pixels}) { last; }
	$w ++;
	if($w >= $$ir{width}) {
	  $w = 0;
	  $h ++;
	}

	$state = 'r';
      }
    }
  } # while read from file

  if($used < $$ir{pixels}) {
    $$ir{error} = 'type 3 read: not enough pixels';
  } else {
    $$ir{error} = '';
  }
} # end &int_readpixels_3

# Internal write pixels for P3: ascii pixmap. Does not do argument checks.
sub int_encodepixels_3 {
  my $pr   = shift; # pixel array ref
  my $deep = shift; # how deep is our array
  my $enc  = shift; # source pixel encoding
  my $max  = shift; # max value

  my $w = 0;
  my $h = 0;
  my $out = '';
  my $val;
  my $wide = 0;
  my $pix;
  my @cur;
  my $rgb;

  if($deep eq '1d') { 
    # $#{array} returns counts starting at -1 for empty array
    $pix = 1+ $#{$pr};
    @cur = explodetriple($$pr[$w]);
  } else {
    # explodetriple makes deep = 2d work like deep = 3d
    $pix = (1+ $#{$pr}) * (1+ $#{$$pr[0]});
    @cur = explodetriple($$pr[$h][$w]);
  }

  while($pix > 0) {

    for $rgb (0,1,2) {
      if($enc eq 'float') {
	$val = int_floatvaltodec($cur[$rgb], $max);
        chop($val); # eat last ':'
      } elsif($enc eq 'hex') {
	$cur[$rgb] =~ s!/$!!;
	$val = hex($cur[$rgb]);
      } else {
	$cur[$rgb] =~ s!:$!!;
	$val = 0+$cur[$rgb]; # normalize numbers
      }

      if($val > $max) {
	$val = $max;
      }

      if(70 < ($wide + 1 + length($val))) {
	$wide = 0;
	$out .= "\n";
      }
      $out  .= $val . ' ';
      $wide += 1 + length($val);
    } # for rgb

    $pix --;
    $w ++;
    if($deep eq '1d') {
      if(exists($$pr[$w]) and defined($$pr[$w])) {
        @cur = explodetriple($$pr[$w]);
      } else {
        @cur = (0,0,0);
      }
    } else {
      if(!exists($$pr[$h][$w])) {
        $w = 0;
	$h ++;
      }
      if(exists($$pr[$h][$w]) and defined($$pr[$h][$w])) {
        @cur = explodetriple($$pr[$h][$w]);
      } else {
        @cur = (0,0,0);
      }
    }
  } # while pix

  if($wide) {
    $out .= "\n";
  }
  return($out);
} # end &int_encodepixels_3

# Internal read pixels for P4: raw bitmap. Does not do argument checks.
sub int_readpixels_4 {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $pr = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  my $used = 0;
  my $read;
  my $bits;
  my $bit;
  my $w = 0;
  my $h = 0;

  READ:
  while(read($gr,$read,1)) {
    # $bits will be '01000001' if $read is 'A'
    $bits = unpack('B*', $read);

    for $bit ($bits =~ /([01])/g) {
      $$pr[$h][$w] = $bit;
      $used ++;
      if($used >= $$ir{pixels}) { last READ; }
      $w ++;
      if($w >= $$ir{width}) {
        $w = 0;
	$h ++;
	# pbm pads each row with unused bits, if (width % 8) != 0
	next READ;
      }
    }
  } # while read from file

  if($used < $$ir{pixels}) {
    $$ir{error} = 'type 4 read: not enough pixels';
  } else {
    $$ir{error} = '';
  }
} # end &int_readpixels_4

# Internal write pixels for P4: raw bitmap. Does not do argument checks.
sub int_encodepixels_4 {
  my $pr   = shift; # pixel array ref
  my $deep = shift; # how deep is our array
  my $enc  = shift; # source pixel encoding

  my $w = 0;
  my $h = 0;
  my $out = '';
  my $used = 0;
  my $pix;
  my $cur;
  my $val = '';

  if($deep eq '1d') { 
    # $#{array} returns counts starting at -1 for empty array
    $pix = 1+ $#{$pr};
    $cur = $$pr[$w];
  } else {
    # deep = 3d only allowed for P3/P6
    $pix = (1+ $#{$pr}) * (1+ $#{$$pr[0]});
    $cur = $$pr[$h][$w];
  }

  while($pix > 0) {
    $cur =~ s![,:/]$!!;
    if($enc eq 'float') {
      if($cur > 0.5) {
	$val .= '1';
      } else {
	$val .= '0';
      }
    } else {
      # for PBM, we assume $max is 1
      if($cur) {
	$val .= '1';
      } else {
	$val .= '0';
      }
    }

    $used ++;
    if($used == 8) {
      $out .= pack("B*", $val);
      $used = 0;
      $val  = '';
    }

    $pix --;
    $w ++;
    if($deep eq '1d') {
      if(exists($$pr[$w]) and defined($$pr[$w])) {
        $cur = $$pr[$w];
      } else {
        $cur = 0;
      }
    } else {
      if(!exists($$pr[$h][$w])) {
        $w = 0;
	$h ++;

	# PBM raw is padded to full byte at end of each row
	if($used) {
	  $out .= pack("B*", substr($val.'0000000',0,8) );
	  $used = 0;
	  $val  = '';
	}
      }
      if(exists($$pr[$h][$w]) and defined($$pr[$h][$w])) {
        $cur = $$pr[$h][$w];
      } else {
        $cur = 0;
      }
    }
  } # while pix

  if($used) {
    $out .= pack("B*", substr($val.'0000000',0,8) );
  }
  return($out);
} # end &int_encodepixels_4

# Internal read pixels for P5: raw graymap. Does not do argument checks.
sub int_readpixels_5 {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $pr = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  my $used = 0;
  my $read;
  my $val;
  my $pix;
  my $rc;
  my $w = 0;
  my $h = 0;
  my $expect = 1;

  if ($$ir{max} > 255) {
    $expect = 2;
  }
  
  while($rc = read($gr,$read,$expect)) {
    if($rc == $expect) {
      if($expect == 1) {
	# $val will be 65 if $read is 'A'
        $val = unpack('C', $read);
      } else {
	# $val will be 16706 if $read is 'AB'
	$val = unpack('n', $read);
      }

      if($enc eq 'dec') {
        $pix = "$val:";
      } elsif ($enc eq 'hex') {
        $pix = sprintf('%X:', $val);
      } else {
        if($val >= $$ir{max}) {
	  $pix = '1.0,';
	} elsif ($val == 0) {
	  $pix = '0.0,';
	} else {
	  $pix = sprintf('%0.8f,', $val/$$ir{max});
	}
      }

      $$pr[$h][$w] = $pix;
      $used ++;
      if($used >= $$ir{pixels}) { last; }
      $w ++;
      if($w >= $$ir{width}) {
        $w = 0;
	$h ++;
      }
    }
  } # while read from file

  if($used < $$ir{pixels}) {
    $$ir{error} = 'type 5 read: not enough pixels';
  } else {
    $$ir{error} = '';
  }
} # end &int_readpixels_5


# Internal write pixels for P5: raw graymap. Does not do argument checks.
sub int_encodepixels_5 {
  my $pr   = shift; # pixel array ref
  my $deep = shift; # how deep is our array
  my $enc  = shift; # source pixel encoding
  my $max  = shift; # max value

  my $w = 0;
  my $h = 0;
  my $out = '';
  my $val;
  my $pix;
  my $cur;
  my $packer;

  if($max > 255) {
    $packer = 'n';
  } else {
    $packer = 'C';
  }
  if($deep eq '1d') { 
    # $#{array} returns counts starting at -1 for empty array
    $pix = 1+ $#{$pr};
    $cur = $$pr[$w];
  } else {
    # deep = 3d only allowed for P3/P6
    $pix = (1+ $#{$pr}) * (1+ $#{$$pr[0]});
    $cur = $$pr[$h][$w];
  }

  while($pix > 0) {

    if($enc eq 'float') {
      $val = int_floatvaltodec($cur, $max);
      chop($val); # eat last ':'
    } elsif($enc eq 'hex') {
      $cur =~ s!/$!!;
      $val = hex($cur);
    } else {
      $cur =~ s!:$!!;
      $val = 0+$cur; # normalize numbers
    }

    if($val > $max) {
      $val = $max;
    }

    $out  .= pack($packer, $val);

    $pix --;
    $w ++;
    if($deep eq '1d') {
      if(exists($$pr[$w]) and defined($$pr[$w])) {
        $cur = $$pr[$w];
      } else {
        $cur = 0;
      }
    } else {
      if(!exists($$pr[$h][$w])) {
        $w = 0;
	$h ++;
      }
      if(exists($$pr[$h][$w]) and defined($$pr[$h][$w])) {
        $cur = $$pr[$h][$w];
      } else {
        $cur = 0;
      }
    }
  } # while pix

  return($out);

} # end &int_encodepixels_5


# Internal read pixels for P6: raw pixmap. Does not do argument checks.
sub int_readpixels_6 {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $pr = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  my $used = 0;
  my $read;
  my $val;
  my $pix;
  my $rc;
  my $w = 0;
  my $h = 0;
  my $r;
  my $g;
  my $b;
  my $expect = 3;

  if ($$ir{max} > 255) {
    $expect = 6;
  }

  while($rc = read($gr,$read,$expect)) {
    if($rc == $expect) {
      if($expect == 3) {
	# ($r,$g,$b) will be (65,66,0) if $read is 'AB<nul>'
        ($r,$g,$b) = unpack('CCC', $read);
      } else {
	# ($r,$g,$b) will be (16706,49,12544) if $read is 'AB<nul>11<nul>'
        ($r,$g,$b) = unpack('nnn', $read);
      }
      

      if($enc eq 'dec') {
        $pix = "$r:$g:$b";
      } elsif ($enc eq 'hex') {
        $pix = sprintf('%X:%X:%X', $r, $g, $b);
      } else {
	$pix = int_dectripletofloat($r,$g,$b,$$ir{max});
      }

      $$pr[$h][$w] = $pix;
      $used ++;
      if($used >= $$ir{pixels}) { last; }
      $w ++;
      if($w >= $$ir{width}) {
	$w = 0;
	$h ++;
      }

    }
  } # while read from file

  if($used < $$ir{pixels}) {
    $$ir{error} = 'type 6 read: not enough pixels';
  } else {
    $$ir{error} = '';
  }
} # end &int_readpixels_6

# Internal write pixels for P6: raw pixmap. Does not do argument checks.
sub int_encodepixels_6 {
  my $pr   = shift; # pixel array ref
  my $deep = shift; # how deep is our array
  my $enc  = shift; # source pixel encoding
  my $max  = shift; # max value

  my $w = 0;
  my $h = 0;
  my $out = '';
  my $val;
  my $pix;
  my @cur;
  my $rgb;
  my $packer;

  if($max > 255) {
    $packer = 'n';
  } else {
    $packer = 'C';
  }

  if($deep eq '1d') { 
    # $#{array} returns counts starting at -1 for empty array
    $pix = 1+ $#{$pr};
    @cur = explodetriple($$pr[$w]);
  } else {
    # explodetriple makes deep = 2d work like deep = 3d
    $pix = (1+ $#{$pr}) * (1+ $#{$$pr[0]});
    @cur = explodetriple($$pr[$h][$w]);
  }

  while($pix > 0) {

    for $rgb (0,1,2) {
      if($enc eq 'float') {
	$val = int_floatvaltodec($cur[$rgb], $max);
        chop($val); # eat last ':'
      } elsif($enc eq 'hex') {
	$cur[$rgb] =~ s!/$!!;
	$val = hex($cur[$rgb]);
      } else {
	$cur[$rgb] =~ s!:$!!;
	$val = 0+$cur[$rgb]; # normalize numbers
      }

      if($val > $max) {
	$val = $max;
      }

      $out  .= pack($packer, $val);
    } # for rgb

    $pix --;
    $w ++;
    if($deep eq '1d') {
      if(exists($$pr[$w]) and defined($$pr[$w])) {
        @cur = explodetriple($$pr[$w]);
      } else {
        @cur = (0,0,0);
      }
    } else {
      if(!exists($$pr[$h][$w])) {
        $w = 0;
	$h ++;
      }
      if(exists($$pr[$h][$w]) and defined($$pr[$h][$w])) {
        @cur = explodetriple($$pr[$h][$w]);
      } else {
        @cur = (0,0,0);
      }
    }
  } # while pix

  return($out);

} # end &int_encodepixels_6

# Internal read pixels function. Does not do argument checks.
sub int_readpixels {
  my $gr = shift; # input file glob ref
  my $ir = shift; # image info hash ref
  my $pr = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  # most common to least common
  # type 7 is PAM, not supported here (yet)
  if($$ir{type} == 6) { return int_readpixels_6($gr, $ir, $pr, $enc); }
  if($$ir{type} == 5) { return int_readpixels_5($gr, $ir, $pr, $enc); }
  if($$ir{type} == 4) { return int_readpixels_4($gr, $ir, $pr, $enc); }
  if($$ir{type} == 3) { return int_readpixels_3($gr, $ir, $pr, $enc); }
  if($$ir{type} == 2) { return int_readpixels_2($gr, $ir, $pr, $enc); }
  if($$ir{type} == 1) { return int_readpixels_1($gr, $ir, $pr, $enc); }
  
  $$ir{error} = 'image type not recognized';
} # end &int_readpixels

# Internal argument check for encodepixels() and inspectpixels()
sub int_prelim_inspect {
  my $fmt = shift;
  my $max = shift;
  my $p_r = shift;
  my %inspect;

  $inspect{error} = '';
    
  if($fmt =~ /^raw$/i) {
    $inspect{type} = 3; # will be modified later
  } elsif($fmt =~ /^ascii$/i) {
    $inspect{type} = 0; # will be modified later
  } else {
    $inspect{error} = 'invalid format';
    return \%inspect;
  }

  if(($max !~ /^\d+$/) or ($max < 1) or ($max > 65535)) {
    $inspect{error} = 'invalid max';
    return \%inspect;
  }
  if($max > 255) {
    $inspect{bytes} = 2;
  } else {
    $inspect{bytes} = 1;
  }

  if(     ref($p_r)        ne 'ARRAY') {
    $inspect{error} = 'pixels not an array';
    return \%inspect;
  }

  if(                                     ref($$p_r[0])       eq '') {
    $inspect{deep}   = '1d';
    $inspect{first}  = $$p_r[0];
    $inspect{pixels} = 1+ $#{$p_r};

  } elsif(ref($$p_r[0])    eq 'ARRAY' and ref($$p_r[0][0])    eq '') {
    $inspect{deep}   = '2d';
    $inspect{first}  = $$p_r[0][0];
    $inspect{height} = 1+ $#{$p_r};
    $inspect{width}  = 1+ $#{$$p_r[0]};
    $inspect{pixels} = $inspect{width} * $inspect{height};

  } elsif(ref($$p_r[0][0]) eq 'ARRAY' and ref($$p_r[0][0][0]) eq '') {
    $inspect{deep}   = '3d';
    $inspect{first}  = $$p_r[0][0][0];
    $inspect{height} = 1+ $#{$p_r};
    $inspect{width}  = 1+ $#{$$p_r[0]};
    $inspect{pixels} = $inspect{width} * $inspect{height};

  } else {
    # too many levels?
    $inspect{error} = 'pixels not expected structure';
    return \%inspect;
  }

  if(!defined($inspect{first})) {
    $inspect{error} = 'first pixel undef';
    return \%inspect;
  }
  if($inspect{first}      =~ m!^[.0-9]+,!) {
    $inspect{encode} = 'float';

  } elsif($inspect{first} =~ m!^[0-9]+:!) {
    $inspect{encode} = 'dec';

  } elsif($inspect{first} =~ m!^[0-9a-fA-F]+/!) {
    $inspect{encode} = 'hex';

  } elsif($inspect{first} =~ m!^[01]+$!) {
    # for PBM
    $inspect{encode} = 'dec';

  } else {
    $inspect{error} = 'first pixel unrecognized';
    return \%inspect;
  }

  if($max == 1) {
    $inspect{type} += 1; # now either 1 or 4

  } elsif($inspect{deep} eq '3d') {
    $inspect{type} += 3; # now either 3 or 6

  } else {
    # still could be 2, 3, 5, 6
    if($inspect{first} =~ m!^[.0-9a-fA-F]+[,:/][.0-9a-fA-F]+[,:/][.0-9a-fA-F]+!) {
      $inspect{type} += 3; # now either 3 or 6
    } else {
      $inspect{type} += 2; # now either 2 or 5
    }
  }

  return \%inspect;
} # end &int_prelim_inspect


=head1 FUNCTIONS

=head2 readpnmfile( \*PNM, \%info, \@pixels, $encoding );

Reads from a file handle and sets hash %info with properties,
puts pixels into @pixels, formated as "float", "dec", or "hex".
The @pixels structure is an array of rows, each row being an
array of pixel strings.

The %info hash has numerous properties about the source file.
The function itself returns 'error' for usage errors, and the
empty string normally.

This function essentially chains readpnmheader(),
checkpnminfo(), and readpnmpixels().

A single file, if in the RAW format, can contain multiple
concatenated images. This function will only read one at a
time, but can be called multiple times on the same file handle.

=over

=item *

$info{bgp}

Will contain one of "b", "g", or "p" for pbm (bitmap), pgm (graymap),
or ppm (pixmap). This is an informational value not used by this library.

=item *

$info{type}

Will contain one of "1" for ASCII PBM, "2" for ASCII PGM, "3" for
ASCII PPM, "4" for raw PBM, "5" for raw PGM, or "6" for raw PPM.
This numerical value is right out of the header of the PBM family
of files and is essential to understanding the pixel format.

=item *

$info{max}

Will contain the max value of the image as a decimal integer. This
is needed to properly understand what a decimal or hexadecimal
pixel value means. It is used to convert raw pixel data into 
floating point values (and back to integers).

=item *

$info{format}

Will contain 'raw' or 'ascii'.

=item *

$info{raw}

Will contain a true value if the file is raw encoded, and false
for ASCII. This is an informational value not used by this library.

=item *

$info{height}

Will contain the height of the image in pixels.

=item *

$info{width}

Will contain the width of the image in pixels.

=item *

$info{pixels}

Will contain the number of pixels (height * width).

=item *

$info{comments}

Will contain any comments found in the header, concatenated.

=item *

$info{fullheader}

Will contain the complete, unparsed, header.

=item *

$info{error}

Will contain an empty string if no errors occured, or an error
message, including usage errors.

=back

=cut

# readpnmfile(\*PNM, \%imageinfo, \@pixels, 'float' );
sub readpnmfile {
  my $f_r = shift;	# file
  my $i_r = shift;	# image info
  my $p_r = shift;	# 2d array of pixels
  my $enc = shift;	# encoding string

  if('HASH' ne ref($i_r)) {
    # not a hash, can't return errors the normal way
    return 'error';
  }

  if('GLOB' ne ref($f_r)) {
    $$i_r{error} = 'readpnmfile: first arg not a file handle ref';
    return 'error';
  }

  if('ARRAY' ne ref($p_r)) {
    $$i_r{error} = 'readpnmfile: third arg not an array ref';
    return 'error';
  }

  if($enc =~ /^(float|dec|raw)/i) {
    $enc = lc($1);
  } else {
    $$i_r{error} = 'readpnmfile: fourth arg not recognized pixel encoding';
    return 'error';
  }

  int_readpnmheader($f_r, $i_r);

  if(length($$i_r{error})) {
    $$i_r{error} = 'readpnmfile: ' . $$i_r{error};
    return '';
  }

  checkpnminfo($i_r);
  if(exists($$i_r{error}) and length($$i_r{error})) {
    $$i_r{error} = 'readpnmfile: ' . $$i_r{error};
    return 'error';
  }

  int_readpixels($f_r, $i_r, $p_r, $enc);
  if(length($$i_r{error})) {
    $$i_r{error} = 'readpnmfile: ' . $$i_r{error};
  }

  return '';
} # end &readpnmfile


##################################################################


=head2 checkpnminfo( \%info )

Checks the values in the image info hash for completeness. Used
internally between reading the header and reading the pixels of
an image, but might be useful generally.  Expects to find numerical
values for type, pixels, max, width, and height.

=cut

sub checkpnminfo {
  my $i_r = shift;	# image info

  if((!exists($$i_r{type})   or ($$i_r{type}   !~ /^\d/)) or
     (!exists($$i_r{pixels}) or ($$i_r{pixels} !~ /^\d/)) or
     (!exists($$i_r{max})    or ($$i_r{max}    !~ /^\d/)) or
     (!exists($$i_r{width})  or ($$i_r{width}  !~ /^\d/)) or
     (!exists($$i_r{height}) or ($$i_r{height} !~ /^\d/)) ) {
    $$i_r{error} = 'image info incomplete';
    return 'error';
  }
} # end &checkheader



##################################################################



=head2 readpnminfo( \*PNM, \%info )

Reads just the header of a PBM/PGM/PPM file from the file handle
and populates the image info hash. See C<readpnmfile> for a
description of the image info hash. Returns the string 'error'
if there is an problem, and the empty string otherwise. Sets
the $info{error} value with an error string.

=cut

sub readpnmheader {
  my $f_r = shift;      # file
  my $i_r = shift;      # image info

  if('HASH' ne ref($i_r)) {
    # not a hash, can't return errors the normal way
    return 'error';
  }

  if('GLOB' ne ref($f_r)) {
    $$i_r{error} = 'readpnmfile: first arg not a file handle ref';
    return 'error';
  }

  int_readpnmheader($f_r, $i_r);

  if(length($$i_r{error})) {
    $$i_r{error} = 'readpnmheader: ' . $$i_r{error};
    return '';
  }

  checkpnminfo($i_r);
  if(exists($$i_r{error}) and length($$i_r{error})) {
    $$i_r{error} = 'readpnmheader: ' . $$i_r{error};
    return 'error';
  }

  return '';
} # end &readpnmheader



##################################################################


=head2 readpnmpixels( \*PNM, \%info, \@pixels, $encoding )

Reads just the pixels of a PBM/PGM/PPM file from the file handle
and populates the pixels array. See C<readpnmfile> for a
description of the image info hash, pixel array output format,
and encoding details. Returns 'error' if there is an problem, and
the empty string otherwise. Sets the $info{error} value with an
error string.

=cut

sub readpnmpixels {
  my $g_r = shift; # input file glob ref
  my $i_r = shift; # image info hash ref
  my $p_r = shift; # pixel array ref
  my $enc = shift; # target pixel encoding

  if('HASH' ne ref($i_r)) {
    # not a hash, can't return errors the normal way
    return 'error';
  }

  if('GLOB' ne ref($g_r)) {
    $$i_r{error} = 'readpnmpixels: first arg not a file handle ref';
    return 'error';
  }

  if('ARRAY' ne ref($p_r)) {
    $$i_r{error} = 'readpnmpixels: third arg not an array ref';
    return 'error';
  }

  if($enc =~ /^(float|dec|raw)/i) {
    $enc = lc($1);
  } else {
    $$i_r{error} = 'readpnmpixels: fourth arg not recognized pixel encoding';
    return 'error';
  }

  checkpnminfo($i_r);
  if(exists($$i_r{error}) and length($$i_r{error})) {
    $$i_r{error} = 'readpnmpixels: ' . $$i_r{error};
    return 'error';
  }

  int_readpixels($g_r,$i_r,$p_r,$enc);
  if(exists($$i_r{error}) and length($$i_r{error})) {
    $$i_r{error} = 'readpnmpixels: ' . $$i_r{error};
    return 'error';
  }

  return '';
} # end &readpnmpixels



##################################################################


=head2 $float_pixel = hextripletofloat( $hex_pixel, $max )

=head2 $float_pixel = hextripletofloat( \@hex_pixel, $max )

For a pixel string with hex red green and blue values separated by
slashes (R/G/B to RRRR/GGGG/BBBB) or an array of hex values, and a
of max 1 to 65535, convert to the comma separated floating point
pixel format.

No error is returned if $max is outside of the allowed range, but 0
will kill the program. Any value larger than max is clipped.

C<$hex_pixel> can be a scalar or an array ref (eg C<\@triple>) and
C<$float_pixel> can be a scalar or an array (eg C<@triple>).

Returns undef if $hex_pixel is malformed.

=cut

sub hextripletofloat {
  my $trip = shift;
  my $max  = shift;
  my $rgb  = undef;
  my @val;

  if(wantarray()) {
    my @set;

    if(ref($trip) eq 'ARRAY') {
      @val = ( $$trip[0], $$trip[1], $$trip[2]);
      map { s:/$:: } @val;

    } elsif($trip =~ m:^([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)/?$:) {
      @val = ( $1, $2, $3 );
    }

    @set = ( int_decvaltofloat(hex($val[0]), $max),
	     int_decvaltofloat(hex($val[1]), $max),
	     int_decvaltofloat(hex($val[2]), $max) );
    return @set;
  }

  if(ref($trip) eq 'ARRAY') {
    @val = ( $$trip[0], $$trip[1], $$trip[2]);
    map { s:/$:: } @val;
    $rgb = int_dectripletofloat(hex($val[0]),
				hex($val[1]), 
				hex($val[2]), $max)
  } elsif($trip =~ m:^([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)/?$:) {
    $rgb = int_dectripletofloat(hex($1), hex($2), hex($3), $max);
  }
  return $rgb;
} # end hextripletofloat



##################################################################


=head2 $float_pixel = dectripletofloat( $dec_pixel, $max )

=head2 $float_pixel = dectripletofloat( \@dec_pixel, $max )

For a pixel string with decimal red green and blue values separated by
colons (eg R:G:B), or an array of decimal values, and a max of 1 to 65535,
convert to the comma separated floating point pixel format.

No error is returned if $max is outside of the allowed range, but 0 will
kill the program. Any value larger than max is clipped.

C<$dec_pixel> can be a scalar or an array ref (eg C<\@triple>) and
C<$float_pixel> can be a scalar or an array (eg C<@triple>).

Returns undef if $dec_pixel is malformed.

=cut

# R:G:B, max 1 to 65535
sub dectripletofloat {
  my $trip = shift;
  my $max  = shift;
  my $rgb  = undef;

  if(wantarray()) {
    my @set;

    if(ref($trip) eq 'ARRAY') {
      @set = ( int_decvaltofloat($$trip[0], $max),
               int_decvaltofloat($$trip[1], $max),
	       int_decvaltofloat($$trip[2], $max) );

    } elsif($trip =~ m/^(\d+):(\d+):(\d+):?$/) {
      @set = ( int_decvaltofloat($1, $max),
               int_decvaltofloat($2, $max),
	       int_decvaltofloat($3, $max) );
    }
    return @set;
  }

  if(ref($trip) eq 'ARRAY') {
    $rgb = int_dectripletofloat($$trip[0],
                                $$trip[1],
				$$trip[2], $max);
  } elsif($trip =~ m/^(\d+):(\d+):(\d+):?$/) {
    $rgb = int_dectripletofloat($1, $2, $3, $max);
  }
  return $rgb;
}



##################################################################


=head2 $float_pixel = hexvaltofloat( $hex_val, $max )

For a pixel value in hexadecimal and a max of 1 to 65535,
convert to the comma separated floating point pixel value format.

No error is returned if $max is outside of the allowed range, but 0 will
kill the program. Any value larger than max is clipped.

Returns undef if $hex_pixel is malformed.

=cut

sub hexvaltofloat {
  my $val = shift;
  my $max = shift;
  my $fl  = undef;

  # allow trailing slash, since we use them
  if($val =~ m:^([a-fA-F0-9]+)/?$:) {
    $fl = int_decvaltofloat(hex($1), $max);
  }

  return $fl;
} # end &hexvaltofloat



##################################################################


=head2 $float_pixel = decvaltofloat( $dec_val, $max )

For a pixel value in decimal and a max of 1 to 65535,
convert to the comma separated floating point pixel value format.

No error is returned if $max is outside of the allowed range, but 0 will
kill the program. Any value larger than max is clipped.

Returns undef if $dec_pixel is malformed.

=cut

sub decvaltofloat {
  my $val = shift;
  my $max = shift;
  my $fl  = undef;

  # allow trailing colon, since we use them
  if($val =~ /^(\d+):?$/) {
    $fl = int_decvaltofloat($1, $max);
  }

  return $fl;
} # end &decvaltofloat



##################################################################


=head2 $dec_pixel = floattripletodec( \@float_pixel, $max )

=head2 $dec_pixel = floattripletodec( $float_pixel, $max )

For a pixel string with floating red green and blue values separated by
commas (eg R:G:B), and max 1 to 65535, convert to the colon separated
decimal pixel format. No error is returned
if $max is outside of the allowed range, but 0 will kill the program.
Any value larger than max is clipped.

C<$float_pixel> can be a scalar or an array ref (eg C<\@triple>) and
C<$dec_pixel> can be a scalar or an array (eg C<@triple>).

Returns undef if $float_pixel is malformed.

=cut

sub floattripletodec {
  my $trip = shift;
  my $max  = shift;
  my $rgb  = undef;

  if(wantarray()) {
    my @set;

    if(ref($trip) eq 'ARRAY') {
      @set = ( int_floatvaltodec($$trip[0], $max),
               int_floatvaltodec($$trip[1], $max),
	       int_floatvaltodec($$trip[2], $max) );

    } elsif($trip =~ m/^([.\d+]),([.\d+]),([.\d+]),?$/) {
      @set = ( int_floatvaltodec($1, $max),
               int_floatvaltodec($2, $max),
	       int_floatvaltodec($3, $max) );
    }
    return @set;
  }

  if(ref($trip) eq 'ARRAY') {
    $rgb = int_floattripletodec($$trip[0],
                                $$trip[1],
				$$trip[2], $max);
  } elsif($trip =~ m/^([.\d+]),([.\d+]),([.\d+]),?$/) {
    $rgb = int_floattripletodec($1, $2, $3, $max);
  }
  return $rgb;

} # end &floattripletodec



##################################################################


=head2 $hex_pixel = floattripletohex( \@float_pixel, $max )

=head2 $hex_pixel = floattripletohex( $float_pixel, $max )

For a pixel string with floating red green and blue values separated by
commas (eg R:G:B), and max 1 to 65535, convert to the slash separated
hex pixel format. No error is returned
if $max is outside of the allowed range, but 0 will kill the program.
Any value larger than max is clipped.

C<$float_pixel> can be a scalar or an array ref (eg C<\@triple>) and
C<$hex_pixel> can be a scalar or an array (eg C<@triple>).

Returns undef if $float_pixel is malformed.

=cut

sub floattripletohex {
  my $trip = shift;
  my $max  = shift;
  my $rgb  = undef;

  if(wantarray()) {
    my @set;

    if(ref($trip) eq 'ARRAY') {
      @set = ( int_floatvaltohex($$trip[0], $max),
               int_floatvaltohex($$trip[1], $max),
	       int_floatvaltohex($$trip[2], $max) );

    } elsif($trip =~ m/^([.\d+]),([.\d+]),([.\d+]),?$/) {
      @set = ( int_floatvaltohex($1, $max),
               int_floatvaltohex($2, $max),
	       int_floatvaltohex($3, $max) );
    }
    return @set;
  }

  if(ref($trip) eq 'ARRAY') {
    $rgb = int_floattripletohex($$trip[0],
                                $$trip[1],
				$$trip[2], $max);
  } elsif($trip =~ m/^([.\d+]),([.\d+]),([.\d+]),?$/) {
    $rgb = int_floattripletohex($1, $2, $3, $max);
  }
  return $rgb;

} # end &floattripletodec



##################################################################


=head2 $dec_pixel = floatvaltodec( $float_pixel, $max )

For a floating point pixel value and max 1 to 65535, convert to the decimal
pixel format. No error is returned
if $max is outside of the allowed range, but 0 will kill the program.
Any value larger than max is clipped.

Returns undef if $float_pixel is malformed.

=cut

sub floatvaltodec {
  my $trip = shift;
  my $max  = shift;
  my $p    = undef;

  $p = int_floatvaltodec($trip, $max);
 
  return $p;

} # end &floatvaltodec



##################################################################


=head2 $hex_pixel = floatvaltohex( $float_pixel, $max )

For a floating point pixel value and max 1 to 65535, convert to the hexadecimal
pixel format. No error is returned
if $max is outside of the allowed range, but 0 will kill the program.
Any value larger than max is clipped.

Returns undef if $float_pixel is malformed.

=cut

sub floatvaltohex {
  my $trip = shift;
  my $max  = shift;
  my $p    = undef;

  $p = int_floatvaltohex($trip, $max);
 
  return $p;

} # end &floatvaltohex



##################################################################


=head2 $status = comparefloattriple(\@a, \@b)

=head2 $status = comparefloattriple($a, $b)

Returns -1, 0, or 1 much like <=>, but allows a variance of up
to half 1/65535. Checks only a single pair at a time (red value
of $a to red value of $b, etc) and stops at the first obvious
non-equal value.  Does not check if any value is outside of 0.0
to 1.0. Returns undef if either triple can't be understood.

=cut

sub comparefloattriple {
  my $a = shift;
  my $b = shift;
  my $v;

  my $a_r; my $a_g; my $a_b;
  my $b_r; my $b_g; my $b_b;

  ($a_r, $a_g, $a_b) = explodetriple($a);
  ($b_r, $b_g, $b_b) = explodetriple($b);

  if(!defined($a_r) or !defined($b_r)) { return undef; }

  $v = comparefloatval($a_r, $b_r);
  if($v) { return $v; }

  $v = comparefloatval($a_g, $b_g);
  if($v) { return $v; }

  $v = comparefloatval($a_b, $b_b);
  return $v;
} # end &comparefloattriple



##################################################################


=head2 $status = comparefloatval($a, $b)

Returns -1, 0, or 1 much like <=>, but allows a variance of up
to half 1/65535. Checks only a single pair (not an RGB triple),
does not check if either value is outside of 0.0 to 1.0.

=cut

sub comparefloatval {
  my $a = shift;
  my $b = shift;
  # 1/65535 ~ .0000152590; .0000152590 / 2 = .0000076295
  my $alpha = 0.0000076295;

  # eat our own dog food for indicating a float value
  $a =~ s/,$//;
  $b =~ s/,$//;

  my $low_a = $a - $alpha;
  my $hi_a  = $a + $alpha;

  if($low_a > $b) { return  1; }
  if($hi_a  < $b) { return -1; }

  return 0;
} # end &comparefloatval


##################################################################

=head2 $status = comparepixelval($a, $max_a, $b, $max_b)

Returns -1, 0, or 1 much like <=>, taking into account that
each is really a fraction: C<$v / $max_v>. Decimal values should
have a colon (eg "123:"), while hex values should have a slash
(eg "7B/"). Uses integer comparisions and should not be used with
floating point values. Max should always be a regular decimal integer.
Checks only a single pair (not an RGB triple),
does not enforce checks on the max values. 

This is a less forgiving comparison than C<comparefloatval()>.

=cut

sub comparepixelval {
  my $a   = shift;
  my $a_m = shift;
  my $b   = shift;
  my $b_m = shift;

  # eat our own dog food for indicating a dec / hex value
  if($a =~ s:/$::) {
    $a = hex($a);
  } else {
    $a =~ s/:$//;
  }
  if($b =~ s:/$::) {
    $b = hex($b);
  } else {
    $b =~ s/:$//;
  }

  if($a_m == $b_m) {
    return ($a <=> $b);
  }

  # simple way to get to common denominator
  $a = $a * $b_m;
  $b = $b * $a_m;

  return ($a <=> $b);
} # end &comparepixelval


##################################################################

=head2 $status = comparepixeltriple(\@a, $max_a, \@b, $max_b)

=head2 $status = comparepixeltriple($a, $max_a, $b, $max_b)

Returns -1, 0, or 1 much like <=>, taking into account that
RGB each is really a fraction: C<$v / $max_v>. Decimal values should
be colon separated (eg "123:1:1024" or terminated ["123:", "1:", "1024:"]),
while hex values should have slashes
(eg "7B/1/400" or ["7B/", "1/", "400/"]). Uses integer comparisions and
should not be used with floating point values. Max should always be a
regular decimal integer. Checks only a single pair at a time (red value
of $a to red value of $b, etc) and stops at the first obvious
non-equal value.  Does not enforce checks on the max values. 
Returns undef if either triple can't be understood.

This is a less forgiving comparison than C<comparefloattriple()>.

=cut

sub comparepixeltriple {
  my $a   = shift;
  my $a_m = shift;
  my $b   = shift;
  my $b_m = shift;
  my $v;

  my $a_r; my $a_g; my $a_b;
  my $b_r; my $b_g; my $b_b;

  ($a_r, $a_g, $a_b) = explodetriple($a);
  ($b_r, $b_g, $b_b) = explodetriple($b);

  if(!defined($a_r) or !defined($b_r)) { return undef; }

  # eat our own dog food for indicating a dec / hex value
  if($a_r =~ s:/$::) { $a_r = hex($a_r); } else { $a_r =~ s/:$//; }
  if($a_g =~ s:/$::) { $a_g = hex($a_g); } else { $a_g =~ s/:$//; }
  if($a_b =~ s:/$::) { $a_b = hex($a_b); } else { $a_b =~ s/:$//; }
  if($b_r =~ s:/$::) { $b_r = hex($b_r); } else { $b_r =~ s/:$//; }
  if($b_g =~ s:/$::) { $b_g = hex($b_g); } else { $b_g =~ s/:$//; }
  if($b_b =~ s:/$::) { $b_b = hex($b_b); } else { $b_b =~ s/:$//; }

  if($a_m == $b_m) {
    return (($a_r <=> $b_r) or ($a_g <=> $b_g) or ($a_b <=> $b_b));
  }

  # simple way to get to common denominator
  $a_r = $a_r * $b_m;
  $b_r = $b_r * $a_m;

  $v = ($a_r <=> $b_r);
  if($v) { return $v; }

  $a_g = $a_g * $b_m;
  $b_g = $b_g * $a_m;

  $v = ($a_g <=> $b_g);
  if($v) { return $v; }

  $a_b = $a_b * $b_m;
  $b_b = $b_b * $a_m;

  return ($a_g <=> $b_g);

} # end &comparepixeltriple


##################################################################

=head2 ($r, $g, $b) = explodetriple( \@pixel );

=head2 ($r, $g, $b) = explodetriple( $pixel );

Helper function to separate the values of an RGB pixel, either in
array or string format. Float pixels have comma separated triples,
and comma suffixed single values. Decimal pixels use colons, and
hex pixels use slashes. Does not enforce values to be within the
allowed range.

Returns undef if the pixel could not be understood.

=cut

sub explodetriple {
  my $a = shift;
  my $a_r;
  my $a_g;
  my $a_b;

  if(ref($a) eq 'ARRAY') {
    $a_r = $$a[0];
    $a_g = $$a[1];
    $a_b = $$a[2];
  } else {
    if($a =~ m/^(\d+):(\d+):(\d+):?$/) {
      $a_r = $1 .':';
      $a_g = $2 .':';
      $a_b = $3 .':';
    } elsif ($a =~ m:^([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)/?$:) {
      $a_r = $1 .'/';
      $a_g = $2 .'/';
      $a_b = $3 .'/';
    } elsif ($a =~ m/^([.0-9]+),([.0-9]+),([.0-9]+),?$/) {
      $a_r = $1 .',';
      $a_g = $2 .',';
      $a_b = $3 .',';
    } else {
      return undef;
    }
  }

  return ($a_r, $a_g, $a_b);

} # end &explodetriple


##################################################################

=head2 @pixel = rescaletriple( \@pixel, $old_max, $new_max );

=head2 $pixel = rescaletriple( $pixel, $old_max, $new_max );

Helper function to rescale the values of an RGB pixel to a new max
value, either in array or string format. Float pixels do not need
rescaling. Decimal pixels use colons as separator / suffix, and
hex pixels use slashes. Does not enforce values to be within the
allowed range.

Returns undef if the pixel could not be understood.

=cut

sub rescaletriple {
  my $p   = shift;
  my $o_m = shift;
  my $n_m = shift;
  my $p_r;
  my $p_g;
  my $p_b;
  my $enc;
  my $r;

  ($p_r, $p_g, $p_b) = explodetriple($p);

  if(!defined($p_r)) { return undef; }

  if($p_r =~ /:/) {
    $enc = 'dec';
  } elsif ($p_r =~ m:/:) {
    $enc = 'hex';
  } 

  # undef if it was a float triple
  if(defined($enc)) {
    $p_r = rescaleval($p_r, $o_m, $n_m);
    $p_g = rescaleval($p_g, $o_m, $n_m);
    $p_b = rescaleval($p_b, $o_m, $n_m);
  }

  if(wantarray()) {
    return ($p_r, $p_g, $p_b);
  } else {
    $r = "$p_r$p_g$p_b";
    chop $r;
    return $r;
  }

} # end &rescaletriple


##################################################################


=head2 $value = rescaleval( $value, $old_max, $new_max );

Helper function to rescale a single value to a new max
value, either in array or string format. Float values do not need
rescaling. Decimal values use colons as suffix, and
hex values use slashes. Does not enforce values to be within the
allowed range.

Returns undef if the value could not be understood.

=cut

sub rescaleval {
  my $v   = shift;
  my $o_m = shift;
  my $n_m = shift;
  my $r;

  if($o_m == $n_m) {
    # no change
    return $v;
  }

  if($v =~ /:$/) {
    $v =~ s/:$//;

    $r = int_floatvaltodec( ($v / $o_m), $n_m);
  } elsif ($v =~ m:/$:) {
    $v =~ s:/$::; $v = hex($v);

    $r = int_floatvaltohex( ($v / $o_m), $n_m);
  } elsif ($v =~ m/,$/) {
    # no change
    return $v;
  } else {
    return undef;
  }

  return $r; 
} # end &rescaleval



##################################################################


=head2 $header = makepnmheader( \%info );

=head2 $header = makepnmheader($type, $width, $height, $max);

Takes a hash reference similar to C<readpnmheader()> or
C<readpnmfile> would return and makes a PBM, PGM, or PPM header string
from it. C<makeppmheader> first looks for a B<type> in the hash and
uses that, otherwise it expects B<bgp> and B<format> to be set in the hash
(and it will set B<type> for you then). If there is a non-empty
B<comments> in the hash, that will be put in as one or more lines
of comments. There must be sizes for B<width> and B<height>, and if
the image is not a bitmap, there should be one for B<max>. A missing
B<max> will result in C<makeppmheader> guessing 255 and setting
B<max> accordingly.

The numerical types are 1 for ASCII PBM, 2 for ASCII PGM, 3 for
ASCII PPM, 4 for raw PBM, 5 for raw PGM, and 6 for raw PPM. The
maxvalue is ignored for PBM files.

Returns the header string if successful.
Returns undef if there is an error.

=cut

sub makepnmheader {
  my $type;
  my $w;
  my $h;
  my $max;

  my $hr = shift; # header hash ref
  my $head = '';
  my $com  = '';
  my $setmax;

  if(ref($hr) ne 'HASH') {
    $type = $hr;
    $w    = shift;
    $h    = shift;
    $max  = shift;

    if(!defined($type) or !defined($w) or !defined($h)) {
      return undef;
    }

    if($type !~ /^[123456]$/) {
      return undef;
    }
    if($w    !~ /^\d+$/) {
      return undef;
    }
    if($h    !~ /^\d+$/) {
      return undef;
    }

  } else {

    if (defined($$hr{width}) and $$hr{width} =~ /^\d+$/) {
      $w = $$hr{width};
    } else {
      return undef;
    }

    if (defined($$hr{height}) and $$hr{height} =~ /^\d+$/) {
      $h = $$hr{height};
    } else {
      return undef;
    }

    if (defined($$hr{max}) and $$hr{max} =~ /^\d+$/) {
      $max = $$hr{max};
    } else {
      $max    = 255;
      $setmax = 1;
    }

    if (defined($$hr{type}) and $$hr{type} =~ /^[123456]$/) {
      $type = $$hr{type};

    } elsif(defined($$hr{bgp}) and defined($$hr{format}) and
	  $$hr{bgp} =~ /^([bgp])$/i) {
    
      my $bgp = lc($1);
      if ($bgp eq 'b') {
	$type = 1;
      } elsif ($bgp eq 'g') {
	$type = 2;
      } else {
	$type = 3;
      }

      if ($$hr{format} =~ /raw/i) {
	$type += 3;
      } elsif ($$hr{format} !~ /ascii/i) {
        return undef;
      }

      $$hr{type} = $type;
    } else {
      return undef;
    }

    if(defined($$hr{comments}) and length($$hr{comments})) {
      $com = $$hr{comments};
      $com =~ s/^/#/gm;
      if(substr($com, -1, 1) ne "\n") {
	$com .= "\n";
      };
    }

  }

  if($w < 1 or $h < 1) {
    return undef;
  }

  $head = "P$type\n$com";
  $head .= "$w $h\n";

  if($type != 1 and $type != 4) {
    if(!defined($max) or $max < 1 or $max > 65535) {
      return undef;
    }
    $head .= "$max\n";
    if($setmax) {
      $$hr{max} = $max;
    }
  }

  return $head;
} # end &makepnmheader

##################################################################


=head2 $block = encodepixels($format, $max, \@pixels);

Encodes pixels into 'raw' or 'ascii' PBM/PGM/PPM format. The
supplied pixels can be decimal, hex, or floating point values.
Decimal and hex values greater than $max will be clipped to $max.
A $max of 1 will encode a PBM file, otherwise the first pixel
will be examined to determine if it is PGM or PPM data.

The array of pixels can be one, two, or three dimensional. A
two dimensional array is prefered and will be considered to
be same format C<readpnmfile()> and C<readpnmpixels()> uses.
There, the @pixels structure is an array of rows, each row
being an array of pixel strings. This function will expect
every row to have the same number of pixels as the first. If
subsequent rows have different amounts, the results can be
unpredictable. Missing values will be assumed to be 0 if it
it tries to read past the end of the array.

A three dimensional @pixels structure is considered to be an
array of rows, each row being an array of PPM pixel values.

A one dimensional @pixels structure is an array of pixel strings
with no hint of row and column structure.
With a one dimensional array, raw PBM files will be
misencoded if number of columns is not a multiple of 8 and the data
represents more than one row: each row is supposed to be padded to
a multiple of 8 bits.

Returns undef if $encoding is not recognized, $max is out of bounds
(1 to 65535, inclusive), or @pixels cannot be understood.

=cut

# $block = encodepixels($encoding, $max, \@pixels);
sub encodepixels {
  my $fmt = shift;
  my $max = shift;
  my $p_r = shift;
  my $i;

  $i = int_prelim_inspect($fmt, $max, $p_r);

  if(exists($$i{error}) and length($$i{error})) {
    # we don't return a meaningful error
    return undef;
  }

  return int_encodepixels($$i{type}, $p_r, $$i{deep}, $$i{encode}, $max);
} # end &encodepixels


##################################################################


=head2 $return = writepnmfile(\*PNM, \%info, \@pixels);

Writes an entire PNM image to a given filehandle. Sometimes more
memory efficient than a C<makepnmheader()> C<encodepixels()> pair
(by encoding row by row when possible). Does not do an C<inspectpixels()>.

Writes are done using C<syswrite()> so see that the documentation for
that function for warnings about mixing with other file operations.

Returns undef if $encoding is not recognized, $max is out of bounds
(1 to 65535, inclusive), or @pixels cannot be understood. Returns
number of bytes written with positive values for complete success,
0 for no bytes successfully written, and -1 * bytes written for
a partial success (eg, ran out of disk space).

=cut

# $return = writepnmfile(\*PNM, \%info, \@pixels);
sub writepnmfile {
  my $f_r = shift;	# file
  my $i_r = shift;	# image info
  my $p_r = shift;	# array of pixels
  my $header;
  my $inspect;
  my $fmt;
  my $max;
  my $encode;
  my $deep;
  my $type;
  my $bytes;
  my $rc;
  my $row;
  my $pixels;

  if((ref($f_r) ne 'GLOB') or (ref($i_r) ne 'HASH') or (ref($p_r) ne 'ARRAY')) {
    return undef;
  }

  $header = makepnmheader($i_r);
  if(!defined($header)) {
    return undef;
  }

  $fmt = $$i_r{format};
  $max = $$i_r{max};

  if(!defined($fmt)) {
    if($$i_r{type} > 3) {
      $fmt = 'raw';
    } else {
      $fmt = 'ascii';
    }
  }
  $inspect = int_prelim_inspect($fmt, $max, $p_r);

  if(exists($$inspect{error}) and length($$inspect{error})) {
    # last undef case
    return undef;
  }

  $encode = $$inspect{encode};
  $deep   = $$inspect{deep};
  $type   = $$inspect{type};

  $rc = syswrite($f_r, $header);
  if($rc != length($header)) {
    return ($rc * -1);
  }
  $bytes = $rc;

  if($deep eq '1d') {
    # oh well, have to encode it all
    $pixels = int_encodepixels($type, $p_r, $deep, $encode, $max);
    $rc = syswrite($f_r, $pixels);
    $bytes += $rc;
    if($rc != length($pixels)) {
      return ($bytes * -1);
    }
    return $bytes;
  }

  for $row (@$p_r) {
    $pixels = int_encodepixels($type, [ $row ], $deep, $encode, $max);
    $rc = syswrite($f_r, $pixels);
    $bytes += $rc;
    if($rc != length($pixels)) {
      return ($bytes * -1);
    }
  }

  return $bytes;
} # end &writepnmfile

##################################################################


=head2 inspectpixels($format, $max, \@pixels, \%report );

Performs all of the argument checks of C<encodepixels()>, and
if no errors are found it does a thorough inspection all pixels
looking for inconsitencies.

Returns undef if there was an error, and the number of pixels
if it succeeded. (An image with no pixels is considered an error.)
The report hash will contain information gleaned from the inspection.

=over

=item *

$report{error}

Set if there is an error with a description of the problem.

=item *

$report{where}

Set if there is an error with the array coordinates of the problem.

=item *

$report{deep}

Set to '1d', '2d', or '3d' to describe the pixel array.

=item *

$report{width}

Width of the pixel array (if not '1d' deep).

=item *

$report{height}

Height of the pixel array (if not '1d' deep).

=item *

$report{pixels}

Expected number pixels.

=item *

$report{bytes}

Number of bytes needed to encode each pixel, if in raw. Will be 1
for PBM files.

=item *

$report{encode}

The 'float', 'dec', or 'hex' encoding of the first pixel. All others
are expected to match this.

=item *

$report{first}

First pixel found.

=item *

$report{type}

The numerical type of the format. Might be wrong if B<$report{first}>
is unset. Will contain one of "1" for ASCII PBM, "2" for ASCII PGM, "3" for
ASCII PPM, "4" for raw PBM, "5" for raw PGM, or "6" for raw PPM.

=item *

$report{checked}

Number of pixels checked.

=back

=cut

sub inspectpixels {
  my $fmt = shift;
  my $max = shift;
  my $p_r = shift;
  my $i_r = shift;

  # int_prelim_inspect returns a hash ref
  %$i_r = %{int_prelim_inspect($fmt, $max, $p_r)};

  if(exists($$i_r{error}) and length($$i_r{error})) {
    # the inspection report error explains the problem
    return undef;
  }

  my $w = 0;
  my $h = 0;
  my $checked = 0;
  my $cur;
  my @rgb;

  if($$i_r{deep} eq '1d') { $cur = $$p_r[$w]; }
  else { $cur = $$p_r[$h][$w]; }

  CHECK_ALL:
  while(defined($cur)) {

    if($$i_r{deep} eq '3d') {
      if(ref($cur) ne 'ARRAY') {
        $$i_r{error} = 'rgb pixel not array';

      } elsif ($#{$cur} != 2) {
        $$i_r{error} = 'rgb pixel array wrong size';

      } elsif (!checkval($$cur[0], $$i_r{encode}) or
               !checkval($$cur[1], $$i_r{encode}) or
	       !checkval($$cur[2], $$i_r{encode}))  {
        $$i_r{error} = 'rgb pixel array encoded wrong';

      }
    } # 3d

    elsif(ref($cur) ne '') {
        $$i_r{error} = 'pixel not scalar';
    }

    elsif(($$i_r{type} == 6) or ($$i_r{type} == 3)) { # pixmap
      @rgb = explodetriple($cur);

      if ($#rgb != 2) {
        $$i_r{error} = 'rgb pixel not a triple';

      } elsif (!checkval($rgb[0], $$i_r{encode}) or
               !checkval($rgb[1], $$i_r{encode}) or
	       !checkval($rgb[2], $$i_r{encode}))  {
        $$i_r{error} = 'rgb pixel encoded wrong';
      }
    } # pixmap

    elsif(($$i_r{type} == 5) or ($$i_r{type} == 2)) { # graymap
      if (!checkval($cur, $$i_r{encode})) {
        $$i_r{error} = 'gray pixel encoded wrong';
      }
    } # graymap

    if(length($$i_r{error})) {
      $$i_r{checked} = $checked;
      $$i_r{where}   = "$h,$w";
      return undef;
    }

    # that pixel works out okay
    $checked ++;

    if($checked == $$i_r{pixels}) {
      last CHECK_ALL;
    }

    if($$i_r{deep} eq '1d') {
      $w ++;
      $cur = $$p_r[$w];
    } else { 
      $w ++;
      if($w > ($$i_r{width} - 1)) {
        if(exists($$p_r[$h][$w])) {
          $$i_r{error} = 'row too wide';
	  last CHECK_ALL;
	} else {
	  $w = 0;
	  $h ++;
	}
      }
      if (!exists($$p_r[$h][$w])) {
	$$i_r{error} = 'row not wide enough';
	last CHECK_ALL;
      }
      $cur = $$p_r[$h][$w];
    }
  } # while CHECK_ALL

  $$i_r{checked} = $checked;

  if($checked != $$i_r{pixels}) {
    $$i_r{error} = 'pixel undef';
    $$i_r{where} = "$h,$w";
    return undef;
  }

  return $$i_r{pixels};
} # end &inspectpixels


##################################################################


=head2 checkval($value, $encode);

Checks that a value (not an RGB triple) conforms to an encoding of
'float', 'dec', or 'hex'. Returns undef if there was an error, and a
positive value otherwise.  

=cut

sub checkval {
  my $v   = shift;
  my $enc = shift;

  if(!defined($v) or !defined($enc)) {
    return undef;
  }

  if($enc eq 'float') {
    if($v =~ /^[.\d]+,$/) {
      return 1;
    }
  } elsif($enc eq 'dec') {
    if($v =~ /^[\d]+:$/) {
      return 1;
    }
  } elsif($enc eq 'hex') {
    if($v =~ m:^[\da-fA-F]+/$:) {
      return 1;
    }
  }

  return undef;
} # sub &checkval

##################################################################




=head1 PORTABILITY

This code is pure perl for maximum portability, as befitting the
PBM/PGM/PPM philosophy.

=head1 CHANGES

2.0 is a nearly complete rewrite fixing the bugs that arose from
not taking the max value into account. Only the code to read an
image header is taken from 1.x. None of the function names are the
same and most of the interface has changed.

1.05 fixes two comment related bugs (thanks Ladislav Sladecek!) and
some error reporting bugs with bad filehandles.

=head1 BUGS

No attempt is made to deal with comments after the header in ASCII
formatted files.

No attempt is made to handle the PAM format.

Pure perl code makes this slower than it could be.

Not all PBM/PGM/PPM tools are safe for images from untrusted sources
but this one should be. Be careful what you use this with. This
software can create raw files with multibyte (max over 255) values, but
some older PBM/PGM/PPM tools can only handle ASCII files for large
max values (or cannot handle it at all).

=head1 SEE ALSO

The manual pages for B<pbm>(5),  B<pgm>(5), and B<ppm>(5) define the
various file formats. The netpbm and pbmplus packages include a host
of interesting PNM tools.

=head1 COPYRIGHT

Copyright 2012, 2003 Benjamin Elijah Griffin / Eli the Bearded
E<lt>elijah@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__END__
