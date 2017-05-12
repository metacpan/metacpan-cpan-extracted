
use Test::More tests => 3486; # qw( no_plan );
use Graphics::ColorUtils;

# ==================================================
# Globals

my $d = 64; # Stepsize for back/forth tests - use smaller steps if you like
my @c;      # Color triple


# ==================================================
# YIQ

for( my $rr=0; $rr<256; $rr+=$d ) {
  for( my $gg=0; $gg<256; $gg+=$d ) {
    for( my $bb=0; $bb<256; $bb+=$d ) {
      @c = yiq2rgb( rgb2yiq( $rr, $gg, $bb ) );
      ok( abs($c[0] - $rr) < 2, "YIQ 1 Back/Forth Red" ); 
      ok( abs($c[1] - $gg) < 2, "YIQ 1 Back/Forth Green" );
      ok( abs($c[2] - $bb) < 2, "YIQ 1 Back/Forth Blue" );
    }
  }
}

for( my $y=0; $y<1; $y+=0.2 ) {
  for( my $i=0; $i<1; $i+=0.2 ) {
    for( my $q=.1; $q<1; $q+=0.2 ) {
      @c = rgb2yiq( yiq2rgb( $y, $i, $q ) );
      ok( abs($c[0] - $y) < .02, "YIQ 2 Back/Forth Y" );
      ok( abs($c[1] - $i) < .02, "YIQ 2 Back/Forth I" );
      ok( abs($c[2] - $q) < .02, "YIQ 2 Back/Forth Q" );

      like( yiq2rgb( $y, $i, $q ), qr/#[0-9a-fA-F]{6}/, "YIQ - scalar" );
    }
  }
}


# ==================================================
# CMY

for( my $rr=0; $rr<256; $rr+=$d ) {
  for( my $gg=0; $gg<256; $gg+=$d ) {
    for( my $bb=0; $bb<256; $bb+=$d ) {
      @c = cmy2rgb( rgb2cmy( $rr, $gg, $bb ) );
      ok( abs($c[0] - $rr) < 2, "CMY 1 Back/Forth Red" ); 
      ok( abs($c[1] - $gg) < 2, "CMY 1 Back/Forth Green" );
      ok( abs($c[2] - $bb) < 2, "CMY 1 Back/Forth Blue" );

      @c = rgb2cmy( $rr, $gg, $bb );
      is( 255-255*$c[0], $rr, "CMY - Red" );
      is( 255-255*$c[1], $gg, "CMY - Green" );
      is( 255-255*$c[2], $bb, "CMY - Blue" );
    }
  }
}

for( my $c=0; $c<1; $c+=0.2 ) {
  for( my $m=0; $m<1; $m+=0.2 ) {
    for( my $y=.1; $y<1; $y+=0.2 ) {
      @c = rgb2cmy( cmy2rgb( $c, $m, $y ) );
      ok( abs($c[0] - $c) < .02, "CMY 2 Back/Forth C" );
      ok( abs($c[1] - $m) < .02, "CMY 2 Back/Forth M" );
      ok( abs($c[2] - $y) < .02, "CMY 2 Back/Forth Y" );

      like( cmy2rgb( $c, $m, $y ), qr/#[0-9a-fA-F]{6}/, "CMY - scalar" );
    }
  }
}


# ==================================================
# HLS

is( hls2rgb( 0,   0.5, 1 ), '#ff0000', "hls2rgb( 0, 0.5, 1 )" );
is( hls2rgb( 120, 0.5, 1 ), '#00ff00', "hls2rgb( 120, 0.5, 1 )" );
is( hls2rgb( 240, 0.5, 1 ), '#0000ff', "hls2rgb( 0, 0.5, 1 )" );
is( hls2rgb( 360, 0.5, 1 ), '#ff0000', "hls2rgb( 360, 0.5, 1)" );

is( hls2rgb(5, 0.2, 0.2), hls2rgb(365, 0.2, 0.2),  "HLS: Wrap hue positive" );
is( hls2rgb(55, 0.2, 0.2), hls2rgb(415, 0.2, 0.2), "HLS: Wrap hue positive" );
is( hls2rgb(-1, 0.2, 0.2), hls2rgb(359, 0.2, 0.2), "HLS: Wrap hue negative" );

is( hls2rgb( 17, 0, 0.4 ), '#000000', "HLS: Black" );
is( hls2rgb( 23, 1, 0.2 ), '#ffffff', "HLS: White" );

@c = hls2rgb( 17, 0.8, 0 );
ok( $c[0] == $c[1] && $c[1] == $c[2], 'HLS: Saturation 0 => achromatic' );

@c = hls2rgb( 38, .8, .2 );
ok( 0 <= $c[0] && $c[0] < 256, "HLS - Red" );
ok( 0 <= $c[1] && $c[1] < 256, "HLS - Green" );
ok( 0 <= $c[2] && $c[2] < 256, "HLS - Blue" );

# ---

for( my $rr=0; $rr<256; $rr+=$d ) {
  for( my $gg=0; $gg<256; $gg+=$d ) {
    for( my $bb=0; $bb<256; $bb+=$d ) {
      @c = hls2rgb( rgb2hls( $rr, $gg, $bb ) );
      ok( abs($c[0] - $rr) < 2, "HLS 1 Back/Forth Red" ); # Roundoff!
      ok( abs($c[1] - $gg) < 2, "HLS 1 Back/Forth Green" );
      ok( abs($c[2] - $bb) < 2, "HLS 1 Back/Forth Blue" );
    }
  }
}

for( my $hh=0; $hh<360; $hh+=36 ) {
  for( my $ll=0; $ll<1; $ll+=0.2 ) {
    for( my $ss=.1; $ss<1; $ss+=0.2 ) { # Don't start sat at 0 - achromatic
      @c = rgb2hls( hls2rgb( $hh, $ll, $ss ) );

      if( $c[1] == 0 ) { # Saturation=0 -> do not check hue
	ok( 1, "HLS 2 Back/Forth - sat=1, do not check Hue" );
      } else {
	ok( abs($c[0] - $hh) < 9,   "HLS 2 Back/Forth Hue" );
      }

      ok( abs($c[1] - $ll) < .02, "HLS 2 Back/Forth Lit" );

      if( $c[1] == 0 ) {
	ok( 1, "HLS 2 Back/Forth - lit=1, do not check Sat" );
      } else {
	ok( abs($c[2] - $ss) < .02, "HLS 2 Back/Forth Sat" );
      }
    }
  }
}


# ==================================================
# HSV

is( hsv2rgb( 0, 1, 1 ), '#ff0000', "hsv2rgb( 0, 1, 1 )" );
is( hsv2rgb( 120, 1, 1 ), '#00ff00', "hsv2rgb( 120, 1, 1 )" );
is( hsv2rgb( 240, 1, 1 ), '#0000ff', "hsv2rgb( 0, 1, 1 )" );
is( hsv2rgb( 360, 1, 1 ), '#ff0000', "hsv2rgb( 360, 1, 1)" );

is( hsv2rgb(5, 0.2, 0.2), hsv2rgb(365, 0.2, 0.2),  "HSV: Wrap hue positive" );
is( hsv2rgb(55, 0.2, 0.2), hsv2rgb(415, 0.2, 0.2), "HSV: Wrap hue positive" );
is( hsv2rgb(-1, 0.2, 0.2), hsv2rgb(359, 0.2, 0.2), "HSV: Wrap hue negative" );
# larger negative wrap runs into round-off

is( hsv2rgb( 17, 0.4, 0 ), '#000000', "HSV Black" );
is( hsv2rgb( 23, 0, 1 ), '#ffffff', "HSV White" );

@c = hsv2rgb( 17, 0, 0.8 );
ok( $c[0] == $c[1] && $c[1] == $c[2], 'HSV: Saturation 0 => achromatic' );

@c = hsv2rgb( 38, .8, .2 );
ok( 0 <= $c[0] && $c[0] < 256, "HSV - Red" );
ok( 0 <= $c[1] && $c[1] < 256, "HSV - Green" );
ok( 0 <= $c[2] && $c[2] < 256, "HSV - Blue" );

# ---

for( my $rr=0; $rr<256; $rr+=$d ) {
  for( my $gg=0; $gg<256; $gg+=$d ) {
    for( my $bb=0; $bb<256; $bb+=$d ) {
      @c = hsv2rgb( rgb2hsv( $rr, $gg, $bb ) );
      ok( abs($c[0] - $rr) < 2, "HSV 1 Back/Forth Red" ); # Roundoff!
      ok( abs($c[1] - $gg) < 2, "HSV 1 Back/Forth Green" );
      ok( abs($c[2] - $bb) < 2, "HSV 1 Back/Forth Blue" );
    }
  }
}

for( my $hh=0; $hh<360; $hh+=36 ) {
  for( my $ss=.1; $ss<1; $ss+=0.2 ) { # Don't start sat at 0 - achromatic
    for( my $vv=0; $vv<1; $vv+=0.2 ) {
      @c = rgb2hsv( hsv2rgb( $hh, $ss, $vv ) );

      if( $c[1] == 0 ) { # Saturation=0 -> do not check hue
	ok( 1, "HSV 2 Back/Forth - sat=1, do not check Hue" );
      } else {
	ok( abs($c[0] - $hh) < 9, "HSV 2 Back/Forth Hue" );
      }

      if( $c[2] == 0 ) {
	ok( 1, "HSV 2 Back/Forth - val=1, do not check Sat" );
      } else {
	ok( abs($c[1] - $ss) < .02, "2 Back/Forth Sat" );
      }

      ok( abs($c[2] - $vv) < .02, "HSV 2 Back/Forth Val" );
    }
  }
}
