#!/usr/bin/perl -w

# Copyright 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl c-curve-wx.pl
#
# This is a WxWidgets GUI drawing the C curve and some variations.  It's a
# little rough but can pan and zoom, and rolling the expansion level
# expansion level in the toolbar is an interesting way to see to see the
# curve or curves develop.
#
# Segments are drawn either as lines or triangles.  Triangles are on the
# side of expansion of each segment.  When multiple copies of the curve are
# selected they're in different colours.  (Though presently when line
# segments overlap only one colour is shown.)
#
# Drawing is done with Math::PlanePath::CCurve and
# Geometry::AffineTransform.  The drawing is not particularly efficient
# since it runs through all segments, even those which are off-screen.  The
# drawing is piece-wise in an idle loop, so you can change or move without
# waiting for it to finish.
#
# Some of the drawing options can be set initially from the command line.
# See the usage message print below or run --help.


use 5.008;
use strict;
use warnings;
use FindBin;
use Getopt::Long;
use Geometry::AffineTransform;
use List::Util 'min','max';
use Math::Libm 'M_PI', 'hypot';
use Math::PlanePath::CCurve;
use Time::HiRes;
use POSIX ();
use Wx;
use Wx::Event;

# uncomment this to run the ### lines
# use Smart::Comments;


our $VERSION = 125;

my $level = 5;
my $scale = 1;
my $x_offset = 0;
my $y_offset = 0;

my $window_initial_width;
my $initial_window_height;
my $window_initial_fullscreen;

my @types_list
  = (
     # curve goes East so x=0,y=0 to x=1,y=0
     # optional $rotate*90 degrees (anti-clockwise)

     { name => '1',
       copies => [ { x => 0, y => 0 } ],
     },
     { name => 'Part',
       copies => [ { x => 0, y => 0 } ],
       min_x => -.1, max_x => 1.1,
       min_y => -.1, max_y => .7,
     },
     { name => '2 Pair',
       #    0,0 -----> 1,0
       #    0,0 <----- 1,0
       copies => [ { x => 0, y => 0 },
                   { x => 1, y => 0, rotate => 2 } ],
     },
     { name => '2 Line',
       copies => [ { x => 0, y => 0 },
                   { x => -1, y => 0 } ],
     },
     { name => '2 Arms',
       copies => [ { x => 0, y => 0 },
                   { x => 0, y => 0, rotate => 2 } ],
     },
     # { name => '2 Above',
     #   copies => [ { x => 0, y => 0 },
     #               { x => 0, y => 1 } ],
     # },
     { name => '4 Pinwheel',
       copies => [ { x => 0, y => 0 },
                   { x => 0, y => 0, rotate => 1 },
                   { x => 0, y => 0, rotate => 2 },
                   { x => 0, y => 0, rotate => 3 },
                 ],
     },
     { name => '4 Square Inward',
       #     0,0  -----> 1,0
       #      ^           |
       #      |           v
       #     0,-1 <----- 1,-1
       copies => [ { x => 0, y => 0 },
                   { x => 0, y => -1, rotate => 1 },
                   { x => 1, y => -1, rotate => 2 },
                   { x => 1, y => 0,  rotate => 3 },
                 ],
     },
     { name => '4 Square Outward',
       #     0,1  <----- 1,1
       #      |           ^
       #      v           |
       #     0,0  -----> 1,0
       copies => [ { x => 0, y => 0  },
                   { x => 1, y => 0, rotate => 1 },
                   { x => 1, y => 1, rotate => 2 },
                   { x => 0, y => 1, rotate => 3 },
                 ],
     },
     { name => '4 Pairs',
       #    0,0  -----> 1,0 -----> 2,0
       #    0,0  <----- 1,0 <----- 2,0
       copies => [ { x => 0, y => 0 },
                   { x => 1, y => 0 },
                   { x => 2, y => 0, rotate => 2 },
                   { x => 1, y => 0, rotate => 2 },
                 ],
     },
     { name => '8 Cross',
       copies => [ { x => 0, y => 0 },
                   { x => 0, y => 0, rotate => 1 },
                   { x => 0, y => 0, rotate => 2 },
                   { x => 0, y => 0, rotate => 3 },

                   { x =>  1, y =>  0, rotate => 2 },
                   { x => -1, y =>  0 },
                   { x =>  0, y => -1, rotate => 1 },
                   { x =>  0, y => 1, rotate => 3 },
                 ],
     },
     { name => '8 Square',
       copies => [ { x => 0, y => 0 },  # 4 inward
                   { x => 1, y => 0, rotate => 1 },
                   { x => 1, y => 1, rotate => 2 },
                   { x => 0, y => 1, rotate => 3 },

                   { x => 0, y => 1 },  # 4 outward
                   { x => 0, y => 0, rotate => 1 },
                   { x => 1, y => 0, rotate => 2 },
                   { x => 1, y => 1, rotate => 3 },,
                 ],
     },
     { name => '24 Clipped',
       copies => [
                  { x => -1, y => 0 },
                  { x => 0, y => 0 },
                  { x => 1, y => 0 },
                  { x => -1, y => 1 },
                  { x => 0, y => 1 },
                  { x => 1, y => 1 },

                  { x => 0, y =>  0, rotate => 2 },
                  { x => 1, y =>  0, rotate => 2 },
                  { x => 2, y =>  0, rotate => 2 },
                  { x => 0, y =>  1, rotate => 2 },
                  { x => 1, y =>  1, rotate => 2 },
                  { x => 2, y =>  1, rotate => 2 },

                  { x => 0, y => -1, rotate => 1 },
                  { x => 0, y => 0, rotate => 1 },
                  { x => 0, y => 1, rotate => 1 },
                  { x => 1, y => -1, rotate => 1 },
                  { x => 1, y => 0, rotate => 1 },
                  { x => 1, y => 1, rotate => 1 },

                  { x => 0, y => 0, rotate => 3 },
                  { x => 0, y => 1, rotate => 3 },
                  { x => 0, y => 2, rotate => 3 },
                  { x => 1, y => 0, rotate => 3 },
                  { x => 1, y => 1, rotate => 3 },
                  { x => 1, y => 2, rotate => 3 },
                 ],
       min_x => -0.1, max_x => 1.1,
       min_y => -0.1, max_y => 1.1,
       clip_min_x => 0,
       clip_max_x => 1,
       clip_min_y => 0,
       clip_max_y => 1,
     },
     { name => '24',
       copies => [
                  { x => -1, y => 0 },
                  { x => 0, y => 0 },
                  { x => 1, y => 0 },
                  { x => -1, y => 1 },
                  { x => 0, y => 1 },
                  { x => 1, y => 1 },

                  { x => 0, y =>  0, rotate => 2 },
                  { x => 1, y =>  0, rotate => 2 },
                  { x => 2, y =>  0, rotate => 2 },
                  { x => 0, y =>  1, rotate => 2 },
                  { x => 1, y =>  1, rotate => 2 },
                  { x => 2, y =>  1, rotate => 2 },

                  { x => 0, y => -1, rotate => 1 },
                  { x => 0, y => 0, rotate => 1 },
                  { x => 0, y => 1, rotate => 1 },
                  { x => 1, y => -1, rotate => 1 },
                  { x => 1, y => 0, rotate => 1 },
                  { x => 1, y => 1, rotate => 1 },

                  { x => 0, y => 0, rotate => 3 },
                  { x => 0, y => 1, rotate => 3 },
                  { x => 0, y => 2, rotate => 3 },
                  { x => 1, y => 0, rotate => 3 },
                  { x => 1, y => 1, rotate => 3 },
                  { x => 1, y => 2, rotate => 3 },
                 ],
     },
     { name => 'Half',
       copies => [ { x => 0, y => 0 } ],
       clip_min_x => -2, clip_max_x => .5, # clip second half
       clip_min_y => -1, clip_max_y => 2,
     },
    );
my %types_hash = map { $_->{'name'} => $_ } @types_list;
my @type_names = map {$_->{'name'}} @types_list;
my $type = $types_list[0]->{'name'};

my @figure_names = ('Arrows','Triangles','Lines');
my $figure = $figure_names[0];

Getopt::Long::Configure ('no_ignore_case', 'bundling');
if (! Getopt::Long::GetOptions
    ('help|?'      => sub {
       print "$FindBin::Script [--options]\n
--version                   print program version
--display DISPLAY           X display to use
--level N                   expansion level
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
     'level=i'     => \$level,
     'geometry=s'  => sub {
       my ($opt, $str) = @_;
       $str =~ /^(\d+)x(\d+)$/ or die "Unrecognised --geometry \"$str\"";
       $window_initial_width = $1;
       $initial_window_height = $2;
     },
     'fullscreen'  => \$window_initial_fullscreen,
    )) {
  exit 1;
}

my $path = Math::PlanePath::CCurve->new;

my @colours;
my @brushes;
my @pens;
my $brush_black;
{
  package MyApp;
  use base 'Wx::App';
  sub OnInit {
    my ($self) = @_;
    # $self->SUPER::OnInit();

    foreach my $r (255/4, 255*2/4, 255) {
      foreach my $g (255/4, 255*2/4, 255) {
        foreach my $b (255/4, 255*2/4, 255) {
          my $colour = Wx::Colour->new ($r, $g, $b);
          push @colours, $colour;
          my $brush = Wx::Brush->new ($colour, Wx::wxSOLID());
          push @brushes, $brush;
          my $pen = Wx::Pen->new ($colour, 1, Wx::wxSOLID());
          push @pens, $pen;
        }
      }
    }
    $brush_black = Wx::Brush->new (Wx::wxBLACK, Wx::wxSOLID());
    return 1;
  }
}

my $app = MyApp->new;
$app->SetAppName($FindBin::Script);

use constant FULLSCREEN_HIDE_BITS => (Wx::wxFULLSCREEN_NOBORDER()
                                      | Wx::wxFULLSCREEN_NOCAPTION());

my $main = Wx::Frame->new(undef,               # parent
                          Wx::wxID_ANY(),      # ID
                          $FindBin::Script);    # title
$main->SetIcon (Wx::GetWxPerlIcon());

use constant ZOOM_IN_ID  => Wx::wxID_HIGHEST() + 1;
use constant ZOOM_OUT_ID => Wx::wxID_HIGHEST() + 2;
my $accel_table = Wx::AcceleratorTable->new
  ([Wx::wxACCEL_NORMAL(), Wx::WXK_NUMPAD_ADD(),      ZOOM_IN_ID],
   [Wx::wxACCEL_CTRL(),   Wx::WXK_NUMPAD_ADD(),      ZOOM_IN_ID],
   [Wx::wxACCEL_CTRL(),   'd',                       ZOOM_IN_ID],
   [Wx::wxACCEL_NORMAL(), 'd',                       ZOOM_IN_ID],
   [Wx::wxACCEL_NORMAL(), 'D',                       ZOOM_IN_ID],
   [Wx::wxACCEL_NORMAL(), Wx::WXK_NUMPAD_SUBTRACT(), ZOOM_OUT_ID],
   [Wx::wxACCEL_CTRL(),   Wx::WXK_NUMPAD_SUBTRACT(), ZOOM_OUT_ID]);
$main->SetAcceleratorTable ($accel_table);
### $accel_table

my $menubar = Wx::MenuBar->new;
$main->SetMenuBar ($menubar);

if (! defined $window_initial_width) {
  my $screen_size = Wx::GetDisplaySize();
  $main->SetSize (Wx::Size->new ($screen_size->GetWidth * 0.8,
                                 $screen_size->GetHeight * 0.8));
}

my $draw = Wx::Window->new ($main,               # parent
                            Wx::wxID_ANY(),      # ID
                            Wx::wxDefaultPosition(),
                            Wx::wxDefaultSize());
$draw->SetBackgroundColour (Wx::wxBLACK());
Wx::Event::EVT_PAINT ($draw, \&OnPaint);
Wx::Event::EVT_SIZE ($draw, \&OnSize);
Wx::Event::EVT_IDLE ($draw, \&OnIdle);
Wx::Event::EVT_MOUSEWHEEL ($draw, \&OnMouseWheel);
Wx::Event::EVT_LEFT_DOWN ($draw, \&OnLeftDown);
Wx::Event::EVT_MOTION ($draw, \&OnMotion);
Wx::Event::EVT_ENTER_WINDOW ($draw, \&OnMotion);
Wx::Event::EVT_KEY_DOWN ($draw, \&OnKey);
$draw->SetExtraStyle($draw->GetExtraStyle
                     | Wx::wxWS_EX_PROCESS_IDLE());
if (defined $window_initial_width) {
  $draw->SetSize(Wx::Size->new($window_initial_width,$initial_window_height));
}

{
  my $menu = Wx::Menu->new;
  $menubar->Append ($menu, '&File');

  # $menu->Append (Wx::wxID_PRINT(),
  #                '',
  #                Wx::GetTranslation('Print the image.'));
  # Wx::Event::EVT_MENU ($main, Wx::wxID_PRINT(), 'print_image');
  #
  # $menu->Append (Wx::wxID_PREVIEW(),
  #                '',
  #                Wx::GetTranslation('Preview image print.'));
  # Wx::Event::EVT_MENU ($main, Wx::wxID_PREVIEW(), 'print_preview');
  #
  # $menu->Append (Wx::wxID_PRINT_SETUP(),
  #                Wx::GetTranslation('Print &Setup'),
  #                Wx::GetTranslation('Setup page print.'));
  # Wx::Event::EVT_MENU ($main, Wx::wxID_PRINT_SETUP(), 'print_setup');

  $menu->Append(Wx::wxID_EXIT(),
                '',
                'Exit the program');
  Wx::Event::EVT_MENU ($main, Wx::wxID_EXIT(), sub {
                         my ($main, $event) = @_;
                         $main->Close;
                       });
}
{
  my $menu = Wx::Menu->new;
  $menubar->Append ($menu, '&View');
  {
    my $item = $menu->Append (Wx::wxID_ANY(),
                              "&Fullscreen\tCtrl-F",
                              "Toggle full screen or normal window (use accelerator Ctrl-F to return from fullscreen).",
                              Wx::wxITEM_CHECK());
    Wx::Event::EVT_MENU ($main, $item,
                         sub {
                           my ($self, $event) = @_;
                           ### Wx-Main toggle_fullscreen() ...
                           $main->ShowFullScreen (! $main->IsFullScreen,
                                                  FULLSCREEN_HIDE_BITS);
                         }
                        );
    Wx::Event::EVT_UPDATE_UI($main, $item,
                             sub {
                               my ($main, $event) = @_;
                               ### Wx-Main _update_ui_fullscreen_menuitem: "@_"
                               # though if FULLSCREEN_HIDE_BITS hides the
                               # menubar then the item won't be seen when
                               # checked ...
                               $item->Check ($main->IsFullScreen);
                             });
  }
  {
    $menu->Append (ZOOM_IN_ID,
                   "Zoom &In\tCtrl-+",
                   Wx::GetTranslation('Zoom in.'));
    Wx::Event::EVT_MENU ($main, ZOOM_IN_ID, \&zoom_in);
  }
  {
    $menu->Append (ZOOM_OUT_ID,
                   "Zoom &Out\tCtrl--",
                   Wx::GetTranslation('Zoom out.'));
    Wx::Event::EVT_MENU ($main, ZOOM_OUT_ID, \&zoom_out);
  }
  {
    my $item = $menu->Append (Wx::wxID_ANY(),
                              "&Centre\tCtrl-C",
                              Wx::GetTranslation('Centre display in window.'));
    Wx::Event::EVT_MENU ($main, $item, sub {
                           $x_offset = 0;
                           $y_offset = 0;
                         });
  }
}

my $toolbar = $main->CreateToolBar;
{
  {
    my $choice = Wx::Choice->new ($toolbar,
                                  Wx::wxID_ANY(),
                                  Wx::wxDefaultPosition(),
                                  Wx::wxDefaultSize(),
                                  \@type_names);
    $choice->SetSelection(0);
    $toolbar->AddControl($choice);
    $toolbar->SetToolShortHelp
      ($choice->GetId,
       'The display type.');
    Wx::Event::EVT_CHOICE ($main, $choice,
                           sub {
                             my ($main, $event) = @_;
                             $type = $type_names[$choice->GetSelection];
                             ### $type
                             $draw->Refresh;
                           });
  }
  {
    my $spin = Wx::SpinCtrl->new ($toolbar,
                                  Wx::wxID_ANY(),
                                  $level,  # initial value
                                  Wx::wxDefaultPosition(),
                                  Wx::Size->new(40,-1),
                                  Wx::wxSP_ARROW_KEYS(),
                                  0,                  # min
                                  POSIX::INT_MAX(),   # max
                                  $level);            # initial
    $toolbar->AddControl($spin);
    $toolbar->SetToolShortHelp ($spin->GetId,
                                'Expansion level.');
    Wx::Event::EVT_SPINCTRL ($main, $spin,
                             sub {
                               my ($main, $event) = @_;
                               $level = $spin->GetValue;
                               $draw->Refresh;
                             });
  }
  {
    my $choice = Wx::Choice->new ($toolbar,
                                  Wx::wxID_ANY(),
                                  Wx::wxDefaultPosition(),
                                  Wx::wxDefaultSize(),
                                  \@figure_names);
    $choice->SetSelection(0);
    $toolbar->AddControl($choice);
    $toolbar->SetToolShortHelp
      ($choice->GetId,
       'The figure to draw at each point.');
    Wx::Event::EVT_CHOICE ($main, $choice,
                           sub {
                             my ($main, $event) = @_;
                             $figure = $figure_names[$choice->GetSelection];
                             $draw->Refresh;
                           });
  }
}

#------------------------------------------------------------------------------
# Keyboard

sub zoom_in {
  $scale *= 1.5;
  # $x_offset *= 1.5;
  # $y_offset *= 1.5;
  $draw->Refresh;
}
sub zoom_out {
  $scale /= 1.5;
  # $x_offset /= 1.5;
  # $y_offset /= 1.5;
  $draw->Refresh;
}

# $event is a wxMouseEvent
sub OnKey {
  my ($draw, $event) = @_;
  ### Draw OnLeftDown() ...
  my $keycode = $event->GetKeyCode;
  ### $keycode
  # if ($keycode == Wx::WXK_NUMPAD_ADD()) {
  #   zoom_in();
  # } elsif ($keycode == Wx::WXK_NUMPAD_SUBTRACT()) {
  #   zoom_out();
  # }
}

#------------------------------------------------------------------------------
# mouse wheel scroll

sub OnMouseWheel {
  my ($draw, $event) = @_;
  ### OnMouseWheel() ..

  # "Control" by page, otherwise by step
  my $frac = ($event->ControlDown ? 0.9 : 0.1)
    * $event->GetWheelRotation / $event->GetWheelDelta;

  # "Shift" horizontally, otherwise vertically
  my $size = $draw->GetClientSize;
  if ($event->ShiftDown) {
    $x_offset += int($size->GetWidth * $frac);
  } else {
    $y_offset += int($size->GetHeight * $frac);
  }
  $draw->Refresh;
}


#------------------------------------------------------------------------------
# mouse drag

# $drag_x,$drag_y are the X,Y position where dragging started.
# If dragging is not in progress then $drag_x is undef.
my ($drag_x, $drag_y);

# $event is a wxMouseEvent
sub OnLeftDown {
  my ($draw, $event) = @_;
  ### Draw OnLeftDown() ...
  $drag_x = $event->GetX;
  $drag_y = $event->GetY;
  $event->Skip(1); # propagate to other processing
}
sub OnMotion {
  my ($draw, $event) = @_;
  ### Draw OnMotion() ...

  if ($event->Dragging) {
    if (defined $drag_x) {
      ### drag ...
      my $x = $event->GetX;
      my $y = $event->GetY;
      $x_offset += $x - $drag_x;
      $y_offset += $y - $drag_y;
      $drag_x = $x;
      $drag_y = $y;
      $draw->Refresh;
    }
  }
}

#------------------------------------------------------------------------------
# drawing

sub TopStart {
  my ($k) = @_;
  return (2**$k + ($k%2==0 ? -1 : 1))/3;
}
sub TopEnd {
  my ($k) = @_;
  return TopStart($k+1);
}

sub OnSize {
  my ($draw, $event) = @_;
  $draw->Refresh;
}

# $idle_drawing is a coderef which is setup by OnPaint() to draw more of the
# curves.  If it doesn't finish the drawing then it does a ->RequestMore()
# to go again when next idle (which might be immediately).
my $idle_drawing;

sub OnPaint {
  my ($draw, $event) = @_;
  ### Drawing OnPaint(): $event
  ### foreground: $draw->GetForegroundColour->GetAsString(4)
  ### background: $draw->GetBackgroundColour->GetAsString(4)
  my $busy = Wx::BusyCursor->new;
  my $dc = Wx::PaintDC->new ($draw);

  {
    my $brush = $dc->GetBackground;
    $brush->SetColour ($draw->GetBackgroundColour);
    $dc->SetBackground ($brush);
    $dc->Clear;
  }

  # $brush->SetColour (Wx::wxWHITE);
  # $brush->SetStyle (Wx::wxSOLID());
  # $dc->SetBrush ($brush);
  #
  # $dc->DrawRectangle (20,20,100,100);

  my $colour = Wx::wxGREEN();
  {
    my $pen = $dc->GetPen;
    $pen->SetColour($colour);
    $dc->SetPen($pen);
  }

  my $brush = $dc->GetBrush;
  $brush->SetColour ($colour);
  $brush->SetStyle (Wx::wxSOLID());
  $dc->SetBrush ($brush);

  my ($width,$height) = $dc->GetSizeWH;
  ### $width
  ### $height

  my ($n_lo, $n_hi);
  if ($type eq 'Part') {
    $n_lo = TopStart($level);
    $n_hi = TopEnd($level);
  } else {
    ($n_lo, $n_hi) = $path->level_to_n_range($level);
  }
  my ($x_lo,$y_lo) = $path->n_to_xy($n_lo);
  my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);
  my ($dx,$dy) = ($x_hi-$x_lo, $y_hi-$y_lo);
  my $len = hypot($dx,$dy);
  my $angle = atan2($dy,$dx) * 180 / M_PI();   # dx,dy plus 180deg
  ### $angle
  ### $len

  my $to01 = Geometry::AffineTransform->new;
  $to01->translate(-$x_lo, -$y_lo);
  $to01->rotate(- $angle);
  if ($len) {
    $to01->scale(1/$len, 1/$len);
  }

  my $t = $types_hash{$type};
  ### $t

  my $min_x = $t->{'min_x'};
  my $min_y = $t->{'min_y'};
  my $max_x = $t->{'max_x'};
  my $max_y = $t->{'max_y'};
  if (! defined $min_x) {
    $min_x = 0;
    $min_y = 0;
    $max_x = 0;
    $max_y = 0;

    foreach my $copy (@{$t->{'copies'}}) {
      my $this_min_x = -.5;
      my $this_max_x = 1.5;
      my $this_min_y = -1;
      my $this_max_y = .25;

      foreach (1 .. ($copy->{'rotate'} || 0)) {
        ($this_max_y,     $this_min_x,   $this_max_x,  $this_min_y)
          = ($this_max_x, -$this_max_y,  -$this_min_y, $this_min_x);
      }
      $this_min_x += $copy->{'x'};
      $this_max_x += $copy->{'x'};
      $this_min_y += $copy->{'y'};
      $this_max_y += $copy->{'y'};
      ### this extents: "X $this_min_x to $this_max_x    Y $this_min_y to $this_max_y"
      $min_x = min($min_x, $this_min_x);
      $min_y = min($min_y, $this_min_y);
      $max_x = max($max_x, $this_max_x);
      $max_y = max($max_y, $this_max_y);
    }
  }
  ### extents: "X $min_x to $max_x    Y $min_y to $max_y"

  #       min_x ----------- 0 ---- max_x
  #                    ^
  # mid = (max+min)/2
  my $extent_x = $max_x - $min_x;
  my $extent_y = $max_y - $min_y;
  ### $extent_x
  ### $extent_y

  my $affine = Geometry::AffineTransform->new;
  $affine->translate(- ($min_x + $max_x)/2,   # extent midpoints
                     - ($min_y + $max_y)/2);

  my $extent_scale = min($width/$extent_x, $height/$extent_y) * .9;
  $affine->scale($extent_scale, $extent_scale);                 # shrink
  ### $extent_scale

  $affine->scale(1, -1);                       # Y upwards
  $affine->scale($scale, $scale);
  $affine->scale(-1,-1);                       # rotate 180
  $affine->translate($width/2, $height/2);     # 0,0 at centre
  $affine->translate($x_offset, $y_offset);

  my ($prev_x,$prev_y) = $to01->transform($x_lo,$y_lo);
  ### origin: "$prev_x, $prev_y"

  undef $dc;

  my $bitmap = Wx::Bitmap->new ($width, $height);
  my $scale = 0.5;
  # $scale = sqrt(3)/2;

  my $iterations = 100;
  my $n = $n_lo+1;
  $idle_drawing = sub {
    my ($event) = @_;
    ### idle_drawing: $event

    my $time = Time::HiRes::time();
    # my $client_dc = Wx::ClientDC->new($draw);
    # my $dc = Wx::BufferedDC->new($client_dc, $bitmap);
    my $dc = Wx::ClientDC->new($draw);

    my $remaining = $iterations;
    for ( ; $n <= $n_hi; $n++) {
      if ($remaining-- < 0) {
        # each took time/iterations, want to take .25 sec so
        # new_iterations = .25/(time/iterations)
        # new_iterations = iterations * .25/time
        my $time = Time::HiRes::time() - $time;
        $iterations = int(($iterations+1) * .25/$time);
        # print "$iterations cf time $time\n";

        if ($event) { $event->RequestMore(1); }
        return;
      }

      my ($x,$y) = $path->n_to_xy($n);
      ($x,$y) = $to01->transform($x,$y);
      ### point: "$x, $y"

      my $c = 0;
      foreach my $copy (@{$t->{'copies'}}) {
        $c++;

        my $x = $x;
        my $y = $y;
        my $prev_x = $prev_x;
        my $prev_y = $prev_y;
        if ($copy->{'invert'}) {
          $y = -$y;
          $prev_y = -$prev_y;
        }
        if (my $r = $copy->{'rotate'}) {
          foreach (1 .. $r) {
            ($x,$y) = (-$y,$x); # rotate +90
            ($prev_x, $prev_y) = (-$prev_y, $prev_x);  # rotate +90
          }
        }
        $x += $copy->{'x'};
        $y += $copy->{'y'};
        $prev_x += $copy->{'x'};
        $prev_y += $copy->{'y'};

        my $dx = $x - $prev_x;
        my $dy = $y - $prev_y;
        my $mx = ($x + $prev_x)/2;  # midpoint prev to this
        my $my = ($y + $prev_y)/2;

        if (defined $t->{'clip_min_x'}) {
          my $cx = $mx - $dy * $scale * .5;
          my $cy = $my + $dx * $scale * .5;
          if ($cx < $t->{'clip_min_x'} || $cx > $t->{'clip_max_x'}
              || $cy < $t->{'clip_min_y'} || $cy > $t->{'clip_max_y'}) {
            next;
          }
        }
        $mx += $dy * $scale;   # dx,dy turned right -90deg
        $my -= $dx * $scale;

        ($prev_x,$prev_y) = $affine->transform($prev_x,$prev_y);
        ($mx, $my) = $affine->transform($mx,$my);
        ($x,$y) = $affine->transform($x,$y);
        ### screen: "$prev_x, $prev_y to $x, $y"

        if (xy_in_rect($x,$y, 0,$width,0,$height)
            || xy_in_rect($prev_x,$prev_y, 0,0,$width,$height)) {
          if ($figure eq 'Triangles') {
            $dc->SetBrush ($brushes[$c]);
            $dc->SetPen ($pens[$c]);
            $dc->DrawPolygon
              ([ Wx::Point->new($prev_x, $prev_y),
                 Wx::Point->new($mx,     $my),
                 Wx::Point->new($x,      $y),
               ],
               0,0);

          } elsif ($figure eq 'Arrows') {
            $dx = $x - $prev_x;
            $dy = $y - $prev_y;

            $prev_x += $dx*.1;  # shorten
            $prev_y += $dy*.1;
            $x -= $dx*.1;
            $y -= $dy*.1;

            my $rx = -$dy;  # to the right
            my $ry = $dx;
            $prev_x += $rx*.05; # gap between overlapping segments
            $prev_y += $ry*.05;
            $x += $rx*.05;
            $y += $ry*.05;

            $dc->SetPen ($pens[$c]);
            $dc->DrawLines
              ([ Wx::Point->new($prev_x, $prev_y),
                 Wx::Point->new($x, $y),
                 Wx::Point->new($x - $dx*.25 + $rx*.12,    # arrow harpoon
                                $y - $dy*.25 + $ry*.12),
               ],
               0,0);

          } else { # $figure eq 'Lines'
            $dc->SetPen ($pens[$c]);
            $dc->DrawLine ($prev_x,$prev_y, $x,$y);
            ($prev_x,$prev_y) = ($x,$y);
          }
        }
      }

      # after all copies
      ($prev_x,$prev_y) = ($x,$y);
    }

    if ($type eq 'square') {
      $dc->SetBrush ($brushes[0]);
      $dc->SetPen ($pens[0]);
      my ($x1,$y1) = $affine->transform(-$y_hi,$x_hi);
      my ($x2,$y2) = $affine->transform($x_hi,$y_hi);
      if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
      if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }
      $dc->DrawRectangle (0,0, $width,$y1-5);
      $dc->DrawRectangle (0,0, $x1-5, $height);
      $dc->DrawRectangle ($x2+5,0, $width, $height);
      $dc->DrawRectangle (0,$y2+5, $width,$height);
    }

    undef $idle_drawing;
  };
  $idle_drawing->();
}
sub OnIdle {
  my ($draw, $event) = @_;
  ### draw OnIdle(): $event
  if ($idle_drawing) {
    $idle_drawing->($event);
  }
}

sub xy_in_rect {
  my ($x,$y, $x1,$y1, $x2,$y2) = @_;
  return (($x >= $x1 && $x <= $x2)
          && ($y >= $y1 && $y <= $y2));
}

### $accel_table
$draw->SetFocus;
if ($window_initial_fullscreen) {
  $main->ShowFullScreen(1, FULLSCREEN_HIDE_BITS);
} else {
  $main->Show;
}
$app->MainLoop;
exit 0;
