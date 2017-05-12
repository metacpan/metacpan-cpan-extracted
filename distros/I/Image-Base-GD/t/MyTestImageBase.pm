# MyTestImageBase.pm -- some tests for Image::Base subclasses

# Copyright 2010, 2011, 2012 Kevin Ryde

# MyTestImageBase.pm is shared by several distributions.
#
# MyTestImageBase.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyTestImageBase.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


# wide/high ellipse cases
# fill check no gaps
# fill check concave


package MyTestImageBase;
BEGIN { require 5 }
use strict;

use vars '$white', '$white_expect', '$black', '$skip', '$handle_input';
$white = 'white';
$black = 'black';
$skip = undef;
$handle_input = sub {};

# uncomment this to run the ### lines
#use Devel::Comments;

use vars '@CARP_NOT';
@CARP_NOT = ('Test');

sub min {
  my $ret = shift;
  while (@_) {
    my $n = shift;
    if ($ret > $n) {
      $ret = $n;
    }
  }
  return $ret;
}
sub max {
  my $ret = shift;
  while (@_) {
    my $n = shift;
    if ($ret < $n) {
      $ret = $n;
    }
  }
  return $ret;
}

sub is {
  &$handle_input();
  if (eval { Test::More->can('is') }) {
    if (defined $skip) {
    SKIP: {
        &Test::More::skip ($skip, 1); # no prototypes
      }
    } else {
      &Test::More::is (@_); # no prototypes
    }
  } else {
    &Test::skip ($skip, @_); # no prototypes
  }
  # if (Test->can('is')) {
  #   } else {
  #     die "Oops, neither Test nor Test::More loaded";
  #   }
}

sub mung_colour {
  my ($colour) = @_;
  if ($colour eq '#000000' || $colour eq '#000000000000') {
    return $black;
  }
  if ($colour eq '#FFFFFF' || $colour eq '#FFFFFFFFFFFF') {
    return $white;
  }
  return $colour;
}

sub dump_image {
  my ($image) = @_;
  if (defined $skip) {
    return;
  }
  require MyTestHelpers;
  my $width = $image->get('-width');
  my $height = $image->get('-height');
  MyTestHelpers::diag("dump_image");
  my $y;
  foreach $y (0 .. $height-1) {
    my $str = '';
    my $x;
    foreach $x (0 .. $width-1) {
      my $colour = $image->xy($x,$y);
      if (! defined $colour) {
        $str .= 'U';
      } else {
        $colour = mung_colour($colour);
        if ($colour eq $black) {
          $str .= '_';
        } else {
          $str .= substr ($colour, 0,1);
        }
      }
    }
    MyTestHelpers::diag($str);
  }

  if (my $canvas = $image->get('-tkcanvas')) {
    my @items = $canvas->find('all');
    MyTestHelpers::diag("item count ",scalar(@items));
    my $item;
    foreach $item (@items) {
      my $type = $canvas->type($item);
      my @coords = $canvas->coords($item);
      my @opts;
      my $spec;
      foreach $spec ($canvas->itemconfigure($item)) {
        my $key = $spec->[0];
        if ($key eq '-fill') {
          my $value = $canvas->itemcget($item,$key);
          if (! defined $value) { $value = '[undef]'; }
          push @opts, " $key=$value";
        }
      }
      MyTestHelpers::diag("item $item $type @opts ",join(',',@coords));
    }
  }
}

#-----------------------------------------------------------------------------

sub is_pixel {
  my ($image, $x,$y, $colour, $name) = @_;
  my $width = $image->get('-width');

  my $got = mung_colour($image->xy($x,$y));
  is ($got, $colour,
      "pixel $x,$y  $colour  on $name");
  my $bad = ($got ne $colour);
  ### $bad
  return $bad;
}

sub is_hline {
  my ($image, $x1,$x2, $y, $colour, $name) = @_;
  return 0 if $x1 > $x2;
  my $width = $image->get('-width');
  return 0 if $y < 0 || $y >= $image->get('-height');
  return 0 if $x2 < 0 || $x1 >= $width;

  my $bad = 0;
  my $x;
  foreach $x (max(0,$x1) .. min($x2,$width-1)) {
    my $got = mung_colour($image->xy($x,$y));
    is ($got, $colour,
        "hline $x,$y  $colour  on $name");
    $bad += ($got ne $colour);
  }
  ### $bad
  return $bad;
}

sub is_vline {
  my ($image, $x, $y1,$y2, $colour, $name) = @_;
  return 0 if $y1 > $y2;
  return 0 if $x < 0 || $x >= $image->get('-width');
  my $height = $image->get('-height');
  return 0 if $y2 < 0 || $y1 >= $height;

  my $bad = 0;
  my $y;
  foreach $y (max(0,$y1) .. min($y2,$height-1)) {
    my $got = mung_colour($image->xy($x,$y));
    is ($got, $colour,
        "vline x=$x,y=$y want $colour  on $name");
    $bad += ($got ne $colour);
  }
  ### $bad
  return $bad;
}

sub is_rect {
  my ($image, $x1,$y1, $x2,$y2, $colour, $name) = @_;
  if ($x1 > $x2 || $y1 > $y2) {
    return 0;
  }
  my $bad = is_hline ($image, $x1,$x2, $y1, $colour, $name);
  if ($y2 != $y1) {
    $bad += is_hline ($image, $x1,$x2, $y2, $colour, $name);
  }
  $bad += is_vline ($image, $x1, $y1+1,$y2-1, $colour, $name);
  if ($x2 != $x1) {
    $bad += is_vline ($image, $x2, $y1+1,$y2-1, $colour, $name);
  }
  return $bad;
}

sub is_filled_rect {
  my ($image, $x1,$y1, $x2,$y2, $colour, $name) = @_;
  my $bad = 0;
  my $y;
  foreach $y ($y1 .. $y2) {
    $bad += is_hline ($image, $x1,$x2, $y, $colour, $name);
  }
  return $bad;
}

# demand that one or more pixels in hline have $colour
sub some_hline {
  my ($image, $x1,$x2, $y, $colour, $name) = @_;
  my $bad = 1;
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  my $x;
  foreach $x ($x1 .. $x2) {
    ### some_hline look at: "$x,$y"
    my $got = mung_colour($image->xy($x,$y));
    if ($got eq $colour) {
      $bad = 0;
      last;
    }
  }
  is ($bad, 0,
      "some_hline x=$x1..$x2,y=$y  $colour  on $name");
  return $bad;
}

sub some_vline {
  my ($image, $x, $y1,$y2, $colour, $name) = @_;
  my $bad = 1;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  my $y;
  foreach $y ($y1 .. $y2) {
    my $got = mung_colour($image->xy($x,$y));
    if ($got eq $colour) {
      $bad = 0;
      last;
    }
  }
  is ($bad, 0,
      "some_vline x=$x,y=$y1..$y2  $colour  on $name");
  return $bad;
}

# demand that all pixels $x1 to $x2 inclusive have $colour
sub all_hline {
  my ($image, $x1,$x2, $y, $colour, $name) = @_;
  my $bad = 0;
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  my $x;
  foreach $x ($x1 .. $x2) {
    ### all_hline look at: "$x,$y c=".$image->xy($x,$y)
    my $got = mung_colour($image->xy($x,$y));
    if ($got ne $colour) {
      $bad = 1;
    }
  }
  is ($bad, 0,
      "all_hline x=$x1..$x2,y=$y  $colour  on $name");
  return $bad;
}

# demand that all pixels $y1 to $y2 inclusive have $colour
sub all_vline {
  my ($image, $x, $y1,$y2, $colour, $name) = @_;
  my $bad = 0;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  my $y;
  foreach $y ($y1 .. $y2) {
    ### all_hline look at: "$x,$y"
    my $got = mung_colour($image->xy($x,$y));
    if ($got ne $colour) {
      $bad = 1;
    }
  }
  is ($bad, 0,
      "all_vline x=$x,y=$y1..$y2  $colour  on $name");
  return $bad;
}


#-----------------------------------------------------------------------------

my @sizes = ([0,0, 0,0],    # 1x1
             [5,7, 5,7],

             [3,2, 4,2],    # thin horiz
             [3,2, 13,2],
             [3,3, 4,3],
             [3,3, 13,3],

             [5,2, 5,3],    # thin vert
             [5,2, 5,9],
             [6,2, 6,3],
             [6,2, 6,9],

             [1,1, 2,2],    # 2x2
             [5,6, 7,8],

             [1,1, 18,8],   # big
            );

sub check_xy {
  my ($image, %options) = @_;
  my $big_fetch_expect = $options{'big_fetch_expect'};

  my $big_negative = -2**16 + 2;
  # exercise some negatives
  $image->xy ($big_negative,0, $white);
  $image->xy (0,$big_negative, $white);
  $image->xy ($big_negative,$big_negative, $white);
  is (scalar($image->xy($big_negative,$big_negative)), $big_fetch_expect,
      'xy() negative fetch');
  is (scalar($image->xy(0,$big_negative)), $big_fetch_expect,
      'xy() negative fetch');
  is (scalar($image->xy($big_negative,0)), $big_fetch_expect,
      'xy() negative fetch');

  my $big_positive = 2**16 + 2;
  $image->xy ($big_positive,$big_positive, $white);
  $image->xy (0,$big_positive, $white);
  $image->xy ($big_positive,0, $white);
  is (scalar($image->xy(0,$big_positive)), $big_fetch_expect,
      'xy() big positive fetch');
  is (scalar($image->xy($big_positive,0)), $big_fetch_expect,
      'xy() big positive fetch');
  is (scalar($image->xy($big_positive,$big_positive)), $big_fetch_expect,
      'xy() big positive fetch');
}

sub check_line {
  my ($image, %options) = @_;
  my ($width, $height) = $image->get('-width','-height');
  my $image_clear_func = $options{'image_clear_func'};

  my $elem;
  foreach $elem (@sizes) {
    my ($x1,$y1, $x2,$y2) = @$elem;

    {
      my $name = "line $x1,$y1 $x2,$y2";
      &$image_clear_func();
      $image->line ($x1,$y1, $x2,$y2, $white);

      my $bad = (
                 # endpoints
                 is_pixel ($image, $x1,$y1, $white, $name)
                 + is_pixel ($image, $x2,$y2, $white, $name)

                 # nothing in surrounding rectangle
                 + is_rect ($image, $x1-1,$y1-1, $x2+1,$y2+1, $black, $name));
      if ($bad) {
        dump_image ($image);
      }
    }
    {
      my $name = "line $x2,$y2 $x1,$y1, reversal";
      &$image_clear_func();
      $image->line ($x2,$y2, $x1,$y1, $white);

      my $bad = (
                 # endpoints
                 is_pixel ($image, $x1,$y1, $white, $name)
                 + is_pixel ($image, $x2,$y2, $white, $name)

                 # nothing in surrounding rectangle
                 + is_rect ($image, $x1-1,$y1-1, $x2+1,$y2+1, $black, $name));
      if ($bad) {
        dump_image ($image);
      }
    }
  }
}

sub rect_using_Other {
  my ($image, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  $image->Image_Base_Other_rectangles ($colour, $fill, $x1, $y1, $x2, $y2);
}

sub check_rectangle {
  my ($image, %options) = @_;
  my ($width, $height) = $image->get('-width','-height');
  my $image_clear_func = $options{'image_clear_func'};

  my $method;
  foreach $method ('rectangle',
                   ($image->can('Image_Base_Other_rectangles')
                    ? ('MyTestImageBase::rect_using_Other')
                    : ())) {

    # exercise some negatives
    foreach my $fill (0,1) {
      $image->$method (-100,-100,-10,-10, $white, $fill);
      $image->$method (-100,-100,5,5, $white, $fill);
      $image->$method (5,5,200,200, $white, $fill);
    }


    my $elem;
    foreach $elem (@sizes) {
      my ($x1,$y1, $x2,$y2) = @$elem;

      {
        my $name = "$method unfilled $x1,$y1, $x2,$y2";
        my $fill = undef;
        &$image_clear_func();

        my @args = ($x1,$y1, $x2,$y2, $white, $fill);
        if ($method eq 'Image_Base_Other_rectangles') {
          unshift @args, splice @args, -2, 2;
        }
        $image->$method (@args);

        my $bad
          = (is_rect ($image, $x1,$y1, $x2,$y2, $white_expect, $name)
             # outside
             + is_rect ($image, $x1-1,$y1-1, $x2+1,$y2+1, $black, $name)
             # inside
             + is_rect ($image, $x1+1,$y1+1, $x2-1,$y2-1, $black, $name));
        if ($bad) { dump_image($image); }
      }
      {
        my $name = "$method filled $x1,$y1, $x2,$y2";
        my $fill = 123;
        &$image_clear_func();

        my @args = ($x1,$y1, $x2,$y2, $white, $fill);
        if ($method eq 'Image_Base_Other_rectangles') {
          unshift @args, splice @args, -2, 2;
        }
        $image->$method (@args);

        my $bad
          = (is_filled_rect ($image, $x1,$y1, $x2,$y2, $white_expect, $name)
             # outside
             + is_rect ($image, $x1-1,$y1-1, $x2+1,$y2+1, $black, $name));
        if ($bad) { dump_image($image); }
      }
    }
  }
}

sub check_ellipse {
  my ($image, %options) = @_;
  my ($width, $height) = $image->get('-width','-height');
  my $image_clear_func = $options{'image_clear_func'};
  my $basefunc = $options{'base_ellipse_func'} || sub { 0 };

  my $elem;
  foreach $elem (@sizes) {
    my ($x1,$y1, $x2,$y2) = @$elem;

    my $fillaref;
    foreach $fillaref ([], [1]) {
      my $fill = ($fillaref->[0] || 0);
      my $name = "ellipse $x1,$y1, $x2,$y2, fill=$fill";
      # MyTestHelpers::diag($name);

      # if ($options{'base_ellipse'}
      #     || $basefunc->($x1,$y1, $x2,$y2)) {
      #   next if $name eq 'ellipse 3,2, 4,2';   # dodgy
      #   next if $name eq 'ellipse 3,2, 13,2';  # dodgy
      #   next if $name eq 'ellipse 1,1, 18,8';  # dodgy
      #   next if $name eq 'ellipse 3,3, 4,3';   # dodgy
      #   next if $name eq 'ellipse 1,1, 2,2';   # dodgy
      #   next if $name eq 'ellipse 3,3, 13,3';  # dodgy
      # }

        &$image_clear_func();
      $image->ellipse ($x1,$y1, $x2,$y2, $white, @$fillaref);

      my $bad = some_hline ($image, $x1,$x2, $y1, $white_expect, $name);
      if ($y2 != $y1) {
        $bad += some_hline ($image, $x1,$x2, $y2, $white_expect, $name);
      }
      $bad += some_vline ($image, $x1, $y1,$y2, $white_expect, $name);
      if ($x2 != $x1) {
        $bad += some_vline ($image, $x2, $y1,$y2, $white_expect, $name);
      }
      $bad += is_rect ($image, $x1-1,$y1-1, $x2+1,$y2+1, $black, $name);

      if ($fill) {
        $bad += (all_hline ($image, $x1,$x2, int(($y1+$y2)/2), $white_expect,$name)
                 + all_hline ($image, $x1,$x2, int(($y1+$y2+1)/2), $white_expect,$name)
                 + all_vline ($image, int(($x1+$x2)/2), $y1,$y2, $white_expect,$name)
                 + all_vline ($image, int(($x1+$x2+1)/2), $y1,$y2, $white_expect,$name)
                );
      }
      if ($bad) { dump_image($image); }
    }
  }
}

sub check_diamond {
  my ($image, %options) = @_;
  MyTestHelpers::diag("check_diamond()");

  $options{'image_clear_func'} ||= do {
    my ($width, $height) = $image->get('-width','-height');
    sub {
      $image->rectangle (0,0, $width-1,$height-1, $black, 1);
    }
  };

  my ($width, $height) = $image->get('-width','-height');
  my $image_clear_func = $options{'image_clear_func'};
  local $white_expect = $white_expect || $white;

  my $elem;
  foreach $elem (@sizes) {
    my ($x1,$y1, $x2,$y2) = @$elem;

    my $fillaref;
    foreach $fillaref ([],
                       ($options{'skip_fill'} ? () : ([1])),
                      ) {
      my $fill = ($fillaref->[0] || 0);
      my $name = "diamond $x1,$y1, $x2,$y2, fill=$fill";
      # MyTestHelpers::diag($name);

      &$image_clear_func();
      $image->diamond ($x1,$y1, $x2,$y2, $white, @$fillaref);

      my $bad;

      if ($options{'pngwriter_exceptions'} && $fill) {
        # dodgy top line of filled filleddiamond()
      } else {
        $bad = some_hline ($image, $x1,$x2, $y1, $white_expect, $name);
      }
      if ($y2 != $y1) {
        $bad += some_hline ($image, $x1,$x2, $y2, $white_expect, $name);
      }

      if ($options{'pngwriter_exceptions'}
          && $fill && $x1+1==$x2 && $y1+1==$y2) {
        # dodgy left side of 2x2 filleddiamond()
      } else {
        $bad += some_vline ($image, $x1, $y1,$y2, $white_expect, $name);
      }
      if ($x2 != $x1) {
        $bad += some_vline ($image, $x2, $y1,$y2, $white_expect, $name);
      }

      $bad += is_rect ($image, $x1-1,$y1-1, $x2+1,$y2+1, $black, $name);
      if ($bad) { dump_image($image); }
    }
  }
}

sub check_image {
  my ($image, %options) = @_;
  MyTestHelpers::diag("check_image()");

  local $white_expect = $white_expect || $white;

  $options{'image_clear_func'} ||= do {
    my ($width, $height) = $image->get('-width','-height');
    sub {
      $image->rectangle (0,0, $width-1,$height-1, $black, 1);
      # { print "blank to\n"; dump_image($image); }
    }
  };

  ### $white
  ### $black
  ### $white_expect

  check_xy ($image, %options);
  check_line ($image, %options);
  check_rectangle ($image, %options);
  check_ellipse ($image, %options);
}

1;
__END__
