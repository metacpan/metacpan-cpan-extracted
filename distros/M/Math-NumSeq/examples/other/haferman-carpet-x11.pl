#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl haferman-carpet-x11.pl
#
# See POD at the end of the file for usage etc.


BEGIN { require 5.0004 }
use strict;
use FindBin;
use Getopt::Long;
use IO::Select;
use List::Util 'min', 'max';
use POSIX 'ceil';
use X11::Protocol;
use X11::Protocol::WM 27; # version 27 for change_net_wm_state()
use vars '%Keysyms';
use X11::Keysyms '%Keysyms', qw(MISCELLANY LATIN1);

use vars '$VERSION';
$VERSION = 72;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------

# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
# Math::NumSeq::HafermanCarpet
# http://mathworld.wolfram.com/HafermanCarpet.html
# http://oeis.org/A118005


#------------------------------------------------------------------------------

# Return ($pow, $exp) where $pow = $base**$exp is $n rounded down to a power
# of $base.
sub round_down_pow {
  my ($n, $base) = @_;
  ### round_down_pow(): "$n base $base"

  # only for integer bases
  ### assert: $base == int($base)

  if ($n < $base) {
    return (1, 0);
  }

  # Math::BigInt and Math::BigRat overloaded log() return NaN, use integer
  # based blog()
  if (ref $n) {
    if ($n->isa('Math::BigRat')) {
      $n = int($n);
    }
    if ($n->isa('Math::BigInt')) {
      ### use blog() ...
      my $exp = $n->copy->blog($base);
      ### exp: "$exp"
      return (Math::BigInt->new(1)->blsft($exp,$base),
              $exp);
    }
  }

  my $exp = int(log($n)/log($base));
  my $pow = $base**$exp;
  ### n:   ref($n)."  $n"
  ### exp: ref($exp)."  $exp"
  ### pow: ref($pow)."  $pow"

  # check how $pow actually falls against $n, not sure should trust float
  # rounding in log()/log($base)
  # Crib: $n as first arg in case $n==BigFloat and $pow==BigInt
  if ($n < $pow) {
    ### hmm, int(log) too big, decrease...
    $exp -= 1;
    $pow = $base**$exp;
  } elsif ($n >= $base*$pow) {
    ### hmm, int(log) too small, increase...
    $exp += 1;
    $pow *= $base;
  }
  return ($pow, $exp);
}

# return true if file handle $fh has data ready to read
sub fh_readable {
  my ($fh) = @_;
  require IO::Select;
  my $s = IO::Select->new;
  $s->add($fh);
  my @ready = $s->can_read(0);
  return scalar(@ready);
}

# return ($quotient, $remainder)
sub divrem_floor {
  my ($n, $d) = @_;
  my $rem = $n % $d;
  return (int(($n-$rem)/$d), # exact division stays in UV
          $rem);
}

#------------------------------------------------------------------------------

# Return the Haferman carpet bit 0 or 1 which is at coordinates $x,$y.
# Coordinates are positive and negative.  For example with $initial=0 the
# pattern around the origin is
#
#       0   1   0    Y=+1
#       1   0   1    Y=0
#       0   1   0    Y=-1
#     X=-1 X=0 X=+1
#
# The carpet is symmetric in Y positive or negative so it doesn't matter
# whether Y is reckoned upwards or downwards.  Likewise symmetric in X.
#
# $initial is 0 or 1 for the centre cell at X=0,Y=0.  The return is based on
# the expansion rules applied starting from that initial centre value, and
# applied an even number of times to ensure that centre is unchanged.
#
# See "Carpet Cells" in the POD below for how this search for low odd X,Y
# pair works.
#
sub xy_to_haferman {
  my ($x,$y, $initial) = @_;
  ### xy_to_haferman(): "$x,$y initial=$initial"
  my $ret = 1;
  while ($x || $y) {
    ($x, my $xdigit) = divrem_negaternary($x);
    ($y, my $ydigit) = divrem_negaternary($y);
    ### digits: "rem $x,$y digits $xdigit,$ydigit parity=".(($xdigit+$ydigit)&1)
    if (($xdigit + $ydigit) & 1) {
      ### odd digit found ...
      return $ret;
    }
    $ret ^= 1;
  }
  return $initial;
}

# Print the picture for the POD.
#
# foreach my $y (-13 .. 13) {
#   print "   ";
#   foreach my $x (-13 .. 13) {
#     print xy_to_haferman($x,$y,0) ? ' *' : '  ';
#   }
#   print "\n";
# }
# exit 0;

# Peel a negaternary digit from the low end of $n.
# Return ($quotient, $digit).
# $digit is -1, 0 or +1 and $quotient = ($n - $digit)/3, so $quotient is the
# rest of $n after removing low $digit.
sub divrem_negaternary {
  my ($n) = @_;
  my $digit = $n % 3;
  if ($digit == 2) { $digit = -1 }
  return (int(($n - $digit) / 3),
          $digit);
}

#------------------------------------------------------------------------------

my $display = $ENV{'DISPLAY'};

# Initially the desired window size and thereafter the actual window size as
# reported by ConfigureNotify.
my $window_width;
my $window_height;

my $scale = 10;    # pixels
my $initial = 0;   # 0 or 1
my $window_initial_fraction = 0.7;  # fraction of screen width,height
my $window_initial_fullscreen;
my $want_dbe = 1;

Getopt::Long::Configure ('no_ignore_case', 'bundling');
if (! Getopt::Long::GetOptions
    ('help|?'      => sub {
       print "$FindBin::Script [--options]\n
--version                   print program version
--display DISPLAY           X display to use
--scale N                   cell size in pixels
--geometry WIDTHxHEIGHT     window size
--fullscreen                full screen window
--initial=1                 initial centre cell value
";
       exit 0;
     },
     'version'     => sub {
       print "$FindBin::Script version $VERSION\n";
       exit 0;
     },
     'display=s'   => \$display,
     'scale=i'     => \$scale,
     'geometry=s'  => sub {
       my ($opt, $str) = @_;
       $str =~ /^(\d+)x(\d+)$/ or die "Unrecognised --geometry \"$str\"";
       $window_width = $1;
       $window_height = $2;
     },
     'fullscreen'  => \$window_initial_fullscreen,
     'initial=i'   => \$initial,
    )) {
  exit 1;
}

# Quietly limit cell size to the protocol maximum size 2^15-1.
$scale = min($scale, 0x7FFF);

my $X = X11::Protocol->new ($display);

if (! defined $window_width) {
  $window_width = int($X->width_in_pixels * $window_initial_fraction);
}
$window_width = max($window_width, 1);
if (! defined $window_height || $window_height < 1) {
  $window_height = int($X->height_in_pixels * $window_initial_fraction);
}
$window_height = max($window_height, 1);

# True if window manager supports the NetWM "fullscreen" state.
my $have_netwm_fullscreen;
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($X->root, $X->atom('_NET_SUPPORTED'),
                       0,    # AnyPropertyType
                       0,    # offset
                       999,  # length
                       0);   # delete;
  my $_NET_WM_STATE_FULLSCREEN = $X->atom('_NET_WM_STATE_FULLSCREEN');
  $have_netwm_fullscreen = (grep {$_ == $_NET_WM_STATE_FULLSCREEN}
                            unpack('L*', $value));
}
### $have_netwm_fullscreen

if ($window_initial_fullscreen && ! $have_netwm_fullscreen) {
  $window_width  = $X->width_in_pixels;
  $window_height = $X->height_in_pixels;
}

my $foreground_pixel = $X->white_pixel;
my $background_pixel = $X->black_pixel;

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',
                  0,                # depth, same as parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  $window_width,$window_height,
                  0,                # border

                  # Desired bit-gravity for a window resize would be a kind
                  # of "Centred" but there's no such type.  The default
                  # "Forget" will clear to background until Expose redraws.
                  background_pixel => $background_pixel,
                  event_mask => $X->pack_event_mask('Exposure',
                                                    'KeyPress',
                                                    'ButtonPress',
                                                    'Button1Motion',
                                                    'ButtonRelease',
                                                    'StructureNotify'));

# icon bitmap +-------+
#             |   X   |
#             | X   X |
#             |   X   |
#             +-------+
my $icon_bitmap = $X->new_rsrc;
$X->CreatePixmap ($icon_bitmap, $window, 1, 32,32);
my $bitmap_gc = $X->new_rsrc;
$X->CreateGC ($bitmap_gc, $icon_bitmap,
              graphics_exposures => 0, foreground => 0);
$X->PolyFillRectangle ($icon_bitmap, $bitmap_gc, [ 0,0, 32,32 ]);
$X->ChangeGC($bitmap_gc, foreground => 1);
$X->PolyFillRectangle ($icon_bitmap, $bitmap_gc, [ 12,3, 9,9 ]);
$X->PolyFillRectangle ($icon_bitmap, $bitmap_gc, [ 3,12, 9,9 ]);
$X->PolyFillRectangle ($icon_bitmap, $bitmap_gc, [ 21,12, 9,9 ]);
$X->PolyFillRectangle ($icon_bitmap, $bitmap_gc, [ 12,21, 9,9 ]);

X11::Protocol::WM::set_wm_name ($X, $window, 'Haferman Carpet'); # title
X11::Protocol::WM::set_wm_icon_name ($X, $window, 'Haferman');
X11::Protocol::WM::set_wm_client_machine_from_syshostname ($X, $window);
X11::Protocol::WM::set_net_wm_pid ($X, $window);
X11::Protocol::WM::set_wm_command
  ($X, $window,
   $^X, # perl executable
   File::Spec->catfile($FindBin::Bin, $FindBin::Script));
X11::Protocol::WM::set_wm_protocols ($X, $window, 'WM_DELETE_WINDOW');
X11::Protocol::WM::set_wm_hints
  ($X, $window,
   input         => 1,
   icon_pixmap   => $icon_bitmap);
if ($window_initial_fullscreen) {
  X11::Protocol::WM::set_net_wm_state($X, $window, 'FULLSCREEN');
}

# $window_buffer is the DBE back buffer of $window, or if no DBE then
# $window itself.
my $window_buffer;
my $have_dbe;
if ($want_dbe && $X->init_extension('DOUBLE-BUFFER')) {
  $have_dbe = 1;
  $window_buffer = $X->new_rsrc;
  $X->DbeAllocateBackBufferName ($window, $window_buffer, 'Undefined');
} else {
  $window_buffer = $window;
}
### $have_dbe

my $window_gc = $X->new_rsrc;
$X->CreateGC ($window_gc, $window,
              foreground => $foreground_pixel,
              background => $background_pixel,
              graphics_exposures => 0);

my ($zero_bitmap, $one_bitmap);
my $block_pow;       # 3**$block_exp
my $block_exp;
my $block_size;      # $scale * 3**$block_exp
my $block_initial;   # 0 or 1

# Copy $from_bitmap square at 0,0 size $block_size to $to_bitmap at $x,$y.
# $x,$y are multiplied by $block_size, so for example $x=1,$y=0 is the block
# immediately to the right of the origin.
sub copy_bitmap {
  my ($from_bitmap, $to_bitmap, $x,$y) = @_;
  $x *= $block_size;
  $y *= $block_size;
  $X->CopyArea ($from_bitmap, $to_bitmap, $bitmap_gc,
                0,0,                      # src x,y
                $block_size,$block_size,  # width,height
                $x,$y);                   # dst x,y
}

# Create and draw $zero_bitmap and $one_bitmap.
# The size is chosen according to $window_width,$window_height and $scale.
# The size is stored in $block_size.  $zero_bitmap and $one_bitmap are both
# $block_size square.
#
sub make_bitmaps {
  ### make_bitmaps() ...
  ### $scale

  if ($zero_bitmap) { $X->FreePixmap($zero_bitmap); }
  if ($one_bitmap)  { $X->FreePixmap($one_bitmap); }

  ($block_pow, $block_exp)
    = round_down_pow(max($window_width,$window_height)/$scale,
                     3);
  $block_size = $block_pow*$scale;

  $zero_bitmap = $X->new_rsrc;
  $X->CreatePixmap ($zero_bitmap, $window, 1, $block_size,$block_size);
  $one_bitmap = $X->new_rsrc;
  $X->CreatePixmap ($one_bitmap, $window, 1, $block_size,$block_size);

  # initial single cell of $scale x $scale pixels
  $block_size = $scale;
  $X->ChangeGC($bitmap_gc, foreground => 0);
  $X->PolyFillRectangle ($zero_bitmap, $bitmap_gc,
                         [ 0,0, $block_size,$block_size ]);
  $X->ChangeGC($bitmap_gc, foreground => 1);
  $X->PolyFillRectangle ($one_bitmap, $bitmap_gc,
                         [ 0,0, $block_size,$block_size ]);

  foreach (1 .. $block_exp) {
    # expand 1 -> 1  1  1
    #             1  1  1
    #             1  1  1
    copy_bitmap ($one_bitmap, $one_bitmap, 0,1);
    copy_bitmap ($one_bitmap, $one_bitmap, 0,2);
    copy_bitmap ($one_bitmap, $one_bitmap, 1,0);
    copy_bitmap ($one_bitmap, $one_bitmap, 1,1);
    copy_bitmap ($one_bitmap, $one_bitmap, 1,2);
    copy_bitmap ($one_bitmap, $one_bitmap, 2,0);
    copy_bitmap ($one_bitmap, $one_bitmap, 2,1);
    copy_bitmap ($one_bitmap, $one_bitmap, 2,2);

    # expand 0 -> 0  1  0
    #             1  0  1
    #             0  1  0
    copy_bitmap ($one_bitmap,  $zero_bitmap, 0,1);
    copy_bitmap ($zero_bitmap, $zero_bitmap, 0,2);
    copy_bitmap ($one_bitmap,  $zero_bitmap, 1,0);
    copy_bitmap ($zero_bitmap, $zero_bitmap, 1,1);
    copy_bitmap ($one_bitmap,  $zero_bitmap, 1,2);
    copy_bitmap ($zero_bitmap, $zero_bitmap, 2,0);
    copy_bitmap ($one_bitmap,  $zero_bitmap, 2,1);
    copy_bitmap ($zero_bitmap, $zero_bitmap, 2,2);

    # swap 0 <-> 1 bitmaps so that the expansions become the Haferman style
    #   0 -> 1  1  1      1 -> 0  1  0
    #        1  1  1           1  0  1
    #        1  1  1           0  1  0
    #
    ($zero_bitmap,$one_bitmap) = ($one_bitmap,$zero_bitmap);
    $block_size *= 3;
  }

  $block_initial = ($block_exp & 1) ^ ($initial != 0);
  ### final block_size: $block_size
}

# $redraw_bitmaps is true if the $zero_bitmap and $one_bitmap should be
# redrawn due to scale change or window size change.
# $redraw is true if an Expose said the window should be redrawn.
my $redraw_bitmaps = 1;
my $redraw;

my $scroll_step = 50;
my $scroll_x = 0;
my $scroll_y = 0;

# Root window coordinates of the last drag position.  This is the initial
# ButtonPress position, or later the last ButtonMotion which has been
# applied.  undef if no drag in progress.
my ($drag_x, $drag_y);

# Pre-fetch atoms so no round-trips under the 'event_handler'.
my $WM_DELETE_WINDOW = $X->atom('WM_DELETE_WINDOW');
my $WM_PROTOCOLS = $X->atom('WM_PROTOCOLS');

# $want_keyboard_mapping is true if a MappingNotify said we should refetch
# the @keysym_arefs table.
my $want_keyboard_mapping = 1;
my @keysym_arefs;

# event_to_keysym() returns the keysym for a KeyPress event based on
# current @keysym_arefs mapping table.
#
sub event_to_keysym {
  my ($h) = @_;

  my $keycode = $h->{'detail'};
  my $shift = ($h->{'state'} & 1);
  my $keysym = $keysym_arefs[$keycode - $X->{'min_keycode'}]->[$shift];

  ### keycode: sprintf('%d %#x', $keycode, $keycode)
  ### keysym_aref: $keysym_arefs[$keycode - $X->{'min_keycode'}]
  ### keysym: sprintf '%d %X', $keysym, $keysym

  return $keysym || $Keysyms{'NoSymbol'};
}
sub event_to_keysym_update {
  if ($want_keyboard_mapping) {
    $want_keyboard_mapping = 0;
    @keysym_arefs =  $X->GetKeyboardMapping
      ($X->{'min_keycode'},
       $X->{'max_keycode'} - $X->{'min_keycode'} + 1);

    ### keycode table size: scalar(@keysym_arefs)
    ### keycode min: $X->{'min_keycode'}
    ### keycode max: $X->{'max_keycode'}
    ### keysym left: $Keysyms{'Left'}
    ### keysym right: $Keysyms{'Right'}
  }
}

$X->{'event_handler'} = sub {
  my (%h) = @_;
  ### event_handler: \%h

  if ($h{'name'} eq 'KeyPress') {
    my $keysym = event_to_keysym(\%h);

    if ($keysym == $Keysyms{'Left'}
        || $keysym == $Keysyms{'KP_Left'}) {
      $scroll_x -= $scroll_step;
      $redraw = 1;
    } elsif ($keysym == $Keysyms{'Right'}
             || $keysym == $Keysyms{'KP_Right'}) {
      $scroll_x += $scroll_step;
      $redraw = 1;
    } elsif ($keysym == $Keysyms{'Up'}
             || $keysym == $Keysyms{'KP_Up'}) {
      $scroll_y -= $scroll_step;
      $redraw = 1;
    } elsif ($keysym == $Keysyms{'Page_Up'}) {
      $scroll_y -= ceil($window_height * .8);
      $redraw = 1;
    } elsif ($keysym == $Keysyms{'Down'}
             || $keysym == $Keysyms{'KP_Down'}) {
      $scroll_y += $scroll_step;
      $redraw = 1;
    } elsif ($keysym == $Keysyms{'Page_Down'}) {
      $scroll_y += ceil($window_height * .8);
      $redraw = 1;

    } elsif ($keysym == $Keysyms{'space'}) {
      $initial =  1 - $initial;  # flip 0<->1
      $redraw = 1;
      ### $initial

    } elsif ($keysym == $Keysyms{'plus'}
             || $keysym == $Keysyms{'KP_Add'}) {
      $scale++;
      $redraw = 1;
      $redraw_bitmaps = 1;
      # adjust scroll to keep centre of window at same bit of carpet
      $scroll_x = int($scroll_x * $scale / ($scale-1));
      $scroll_y = int($scroll_y * $scale / ($scale-1));
    } elsif ($keysym == $Keysyms{'minus'}
             || $keysym == $Keysyms{'KP_Subtract'}) {
      if ($scale > 1) {
        $scale--;
        $redraw = 1;
        $redraw_bitmaps = 1;
        # adjust scroll to keep centre of window at same bit of carpet
        $scroll_x = int($scroll_x * $scale / ($scale+1));
        $scroll_y = int($scroll_y * $scale / ($scale+1));
      }
    } elsif ($keysym == $Keysyms{'C'} || $keysym == $Keysyms{'c'}) {
      $scroll_x = 0;
      $scroll_y = 0;
      $redraw = 1;
    } elsif ($keysym == $Keysyms{'I'} || $keysym == $Keysyms{'i'}) {
      ($foreground_pixel,$background_pixel) = ($background_pixel,$foreground_pixel);
      $X->ChangeGC ($window_gc,
                    foreground => $foreground_pixel,
                    background => $background_pixel);
      $redraw = 1;

    } elsif ($keysym == $Keysyms{'F'} || $keysym == $Keysyms{'f'}) {
      X11::Protocol::WM::change_net_wm_state
          ($X, $window, 'toggle', 'FULLSCREEN');

    } elsif ($keysym == $Keysyms{'Q'} || $keysym == $Keysyms{'q'}) {
      exit 0;
    }

  } elsif ($h{'name'} eq 'ButtonPress') {
    if ($h{'detail'} == 1) {
      ### button1 drag begin ...
      $drag_x = $h{'root_x'};
      $drag_y = $h{'root_y'};
    } elsif ($h{'detail'} == 4) {  # mouse wheel scroll
      $scroll_y += $scroll_step;
      $redraw = 1;
    } elsif ($h{'detail'} == 5) {  # mouse wheel scroll
      $scroll_y -= $scroll_step;
      $redraw = 1;
    }
  } elsif ($h{'name'} eq 'MotionNotify' || $h{'name'} eq 'ButtonRelease') {
    if (defined $drag_x) {
      ### drag move: ($drag_x - $h{'root_x'}), ($drag_y - $h{'root_y'})
      $scroll_x += ($drag_x - $h{'root_x'});
      $scroll_y += ($drag_y - $h{'root_y'});
      $drag_x = $h{'root_x'};
      $drag_y = $h{'root_y'};
      $redraw = 1;
      if ($h{'name'} eq 'ButtonRelease') {
        ### drag end ...
        undef $drag_x;
      }
    }

  } elsif ($h{'name'} eq 'ConfigureNotify'
           && $h{'window'} == $window) {
    $window_width = $h{'width'};
    $window_height = $h{'height'};
    $redraw_bitmaps = 1;
    $redraw = 1;
  } elsif ($h{'name'} eq 'Expose') {
    if ($h{'count'} == 0) {  # when no further exposures for this window
      $redraw = 1;
    }

  } elsif ($h{'name'} eq 'ClientMessage') {
    # WM_DELETE_PROTOCOL used only because X11::Protocol 0.56 goes into an
    # infinite loop on KillClient(), so instead have the window manager tell
    # us to exit.
    if ($h{'format'} == 32
        && $h{'type'} == $WM_PROTOCOLS
        && unpack('L',$h{'data'}) == $WM_DELETE_WINDOW) {
      exit 0;
    }

  } elsif ($h{'name'} eq 'MappingNotify' && $h{'request'} eq 'Keyboard') {
    ### MappingNotify keyboard changed ...
    $want_keyboard_mapping = 1;
  }
};

$X->MapWindow ($window);

my $fh = $X->{'connection'}->fh;
for (;;) {
  event_to_keysym_update();

  # handle_input() while there's events etc from the server.
  # Then if $redraw is not wanted go into handle_input() to wait for events.
  # (The redraw code includes at least one round-trip and that might read
  # events which turns on $redraw again.)
  # 
  while (fh_readable($fh) || ! $redraw) {
    $X->handle_input;
  } 

  if ($redraw) {
    ### main loop redraw ...
    $redraw = 0;
    if ($redraw_bitmaps) {
      $redraw_bitmaps = 0;
      make_bitmaps();
    }

    my $x_centre = int($block_size/2 - $window_width/2) + $scroll_x;
    my $y_centre = int($block_size/2 - $window_height/2) + $scroll_y;
    ### centre: "$x_centre,$y_centre   of $block_size in $window_width,$window_height"

    my ($yhaf, $y) = divrem_floor($y_centre, $block_size);
    my ($xhaf_left, $x_left) = divrem_floor($x_centre, $block_size);
    $y = - $y;
    $x_left = - $x_left;
    my $block_initial = ($block_exp & 1);

    for ( ; $y < $window_height; $y += $block_size, $yhaf += 1) {
      for (my $x = $x_left, my $xhaf = $xhaf_left;
           $x < $window_width;
           $x += $block_size, $xhaf += 1) {

        my $cell = xy_to_haferman($xhaf,$yhaf, $block_initial);
        ### draw: "xy=$x,$y haf=$xhaf,$yhaf value=$cell"
        $X->CopyPlane ($cell ? $one_bitmap : $zero_bitmap,
                       $window_buffer,
                       $window_gc,
                       0,0,                      # src x,y
                       $block_size,$block_size,  # width,height
                       $x,$y,                    # dst x,y
                       1);                       # bit plane
      }
    }
    if ($have_dbe) {
      $X->DbeSwapBuffers ($window, 'Undefined');
    }

    # Make a round-trip after drawing, so as not to hammer the server.
    # During this round-trip any button or key events are processed by the
    # event_handler and may result in another draw needed.  But this will be
    # a draw of their net total movement or re-scaling, not a draw of each
    # one individually.
    $X->QueryPointer($X->root);
  }
}
exit 0;

=for stopwords X11

=head1 NAME

haferman-carpet-x11.pl -- display the Haferman carpet

=head1 SYNOPSIS

 haferman-carpet-x11.pl [--options]

=head1 DESCRIPTION

C<haferman-carpet-x11.pl> displays the Haferman carpet in a scrollable X11
window.

      *     *     *   * * *   *   * * *   *     *     *
    *   * *   * *   * * * * *   * * * * *   * *   * *   *
      *     *     *   * * *   *   * * *   *     *     *
      *     *     *     *   * * *   *     *     *     *
    *   * *   * *   * *   * * * * *   * *   * *   * *   *
      *     *     *     *   * * *   *     *     *     *
      *     *     *   * * *   *   * * *   *     *     *
    *   * *   * *   * * * * *   * * * * *   * *   * *   *
      *     *     *   * * *   *   * * *   *     *     *
    * * *   *   * * *   *     *     *   * * *   *   * * *
    * * * *   * * * * *   * *   * *   * * * * *   * * * *
    * * *   *   * * *   *     *     *   * * *   *   * * *
      *   * * *   *     *     *     *     *   * * *   *
    *   * * * * *   * *   * *   * *   * *   * * * * *   *
      *   * * *   *     *     *     *     *   * * *   *
    * * *   *   * * *   *     *     *   * * *   *   * * *
    * * * *   * * * * *   * *   * *   * * * * *   * * * *
    * * *   *   * * *   *     *     *   * * *   *   * * *
      *     *     *   * * *   *   * * *   *     *     *
    *   * *   * *   * * * * *   * * * * *   * *   * *   *
      *     *     *   * * *   *   * * *   *     *     *
      *     *     *     *   * * *   *     *     *     *
    *   * *   * *   * *   * * * * *   * *   * *   * *   *
      *     *     *     *   * * *   *     *     *     *
      *     *     *   * * *   *   * * *   *     *     *
    *   * *   * *   * * * * *   * * * * *   * *   * *   *
      *     *     *   * * *   *   * * *   *     *     *

=head1 OPTIONS

=over

=item C<--fullscreen>

Start with the window full screen.

=item C<--geometry WIDTHxHEIGHT>

Initial size of the window.  For example C<--geometry=300x200>.

=item C<--initial 1>

Set the initial cell value, which is the cell at the very centre of the
pattern.  It can be 0 or 1.  The default is 0.

=item C<--scale N>

Number of pixels per cell.

=back

=head1 KEYS

The key and button controls are

=over

=item C

Centre the carpet in the window (its initial position).

=item F

Toggle fullscreen (requires a Net-WM window manager).

=item I

Invert black/white colours.

=item Q

Quit.

=item Arrow keys, Page up, Page down

Scroll the carpet in the window.

=item Space

Toggle initial cell value 0 E<lt>-E<gt> 1.

=item +, -

Increase or decrease the scale (zoom in or out).

=item Button 1

Drag the carpet in the window.

=back

=head1 IMPLEMENTATION

=head2 Carpet Cells

The value of the carpet at a given X,Y is given by the position of the
lowest odd digit pair of X,Y when X and Y are written in negaternary,

     lowest "odd"        carpet
    X,Y digit pair       value
    --------------       ------
    even position          0
    odd position           1
    no such pair       initial cell

An "odd" pair of digits means a pair which has xdigit+ydigit == 1 mod 2.
Since each digit is -1,0,1 this is abs(xdigit)!=abs(ydigit).

    "even" digit pairs              "odd" digit pairs
    0,0 1,1 -1,1 1,-1, -1,-1        0,1 1,0 0,-1 -1,0

For example X=-4, Y=1 written in negaternary is X=[-1][-1], Y=[0][1].  The
two lowest digits are xdigit=-1, ydigit=1 which is an "even" pair.  The next
two digits are xdigit=-1, ydigit=0 which is an "odd" pair.  That "odd" pair
is at an odd position (the low end is position 0 and the next is position 1,
etc).  So in the table look under "odd position" for carpet value 1.

If there are no "odd" digit pairs at all in X,Y then the carpet cell is the
initial cell value which is the cell at the very centre of the carpet.  As
described above the default in the program is 0.

=head2 Drawing

The X drawing is done by constructing two bitmaps which are a block of "0"
or "1" expanded down according to the Haferman carpet rule.

    +---+---+---+         +---+---+---+
    |           |         | 0 | 1 | 0 |
    +           +         +---+---+---+
    |     1     |    =>   | 1 | 0 | 1 |
    +           +         +---+---+---+
    |           |         | 0 | 1 | 0 |
    +---+---+---+         +---+---+---+

The bitmap size is scale*3^exp with exp chosen so this size is less than the
window size (the bigger of width and height).  With such a size at most
three blocks across and down suffice to cover the window,

           block    block    block
          +--------+--------+--------+
    block |        |        |        |
          |  window|        |        |    Y=+1
          |  +-------------------+   |
          |  |     |        |    |   |
          +--|-----+--------+----|---+
    block |  |     |        |    |   |
          |  |     |        |    |   |    Y=0
          |  |     |        |    |   |
          |  |     |        |    |   |
          +--|-----+--------+----|---+
    block |  |     |        |    |   |
          |  +-------------------+   |    Y=-1
          |        |        |        |
          |        |        |        |
          +--------+--------+--------+

            X=-1      X=0       X=+1

The desired pixel region X,Y becomes X,Y coordinates of the "block" and an
offset.  The block X,Y gives a cell value as described above, and that cell
value selects the "0" or "1" bitmap.  If exp in the bitmap size is odd then
the "initial" value used for the cell calculation must be inverted.  This is
since an odd exp is an odd number of expansions and that flips the centre
cell 0E<lt>-E<gt>1.

Scrolling is smoothed by drawing with the server DOUBLE-BUFFER extension if
available.  But even without that it's only at most 9 block copies and so
should look reasonable.

=head1 ENVIRONMENT VARIABLES

=over

=item C<DISPLAY>

The X display to use.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<Math::NumSeq::HafermanCarpet>

L<http://mathworld.wolfram.com/HafermanCarpet.html>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Math-NumSeq is Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut
