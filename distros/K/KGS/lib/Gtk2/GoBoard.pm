package Gtk2::GoBoard;

use Scalar::Util;

use POSIX qw(ceil);

use Gtk2;

use Gtk2::GoBoard::Constants;

use Glib::Object::Subclass
   Gtk2::AspectFrame,
   properties => [
      Glib::ParamSpec->IV (
         "size",
         "Board Size",
         "The Go Board size, 2..38",
         2, 38, 19,
         [qw(construct-only writable readable)],
      ),
      Glib::ParamSpec->scalar (
         "cursor",
         "cursor callback",
         "The callback that modifies the cursor mask",
         [qw(writable readable)],
      ),
   ],
   signals => {
      "button-press" => {
         flags       => [qw/run-first/],
         return_type => undef, # void return
         param_types => [Glib::Int, Glib::Int, Glib::Int], # instance and data are automatic
      },
      "button-release" => {
         flags       => [qw/run-first/],
         return_type => undef, # void return
         param_types => [Glib::Int, Glib::Int, Glib::Int], # instance and data are automatic
      },
      destroy        => sub {
         $_[0]->signal_chain_from_overridden;
         %{$_[0]} = ();
      },
   };

# some internal constants

sub TRAD_WIDTH  (){ 42.42 } # traditional board width
sub TRAD_HEIGHT (){ 45.45 } # traditional board height
sub TRAD_RATIO  (){ TRAD_WIDTH / TRAD_HEIGHT } # traditional (nihon-kiin) horizontal spacing
sub TRAD_SIZE_B (){  2.18 } # traditional black stone size
sub TRAD_SIZE_W (){  2.12 } # traditional white stone size

sub SHADOW	(){  0.06 } # 0.09 probably max.

# find a data file using @INC
sub findfile {
   my @files = @_;
   file:
   for (@files) {
      for my $prefix (@INC) {
         if (-f "$prefix/$_") {
            $_ = "$prefix/$_";
            next file;
         }
      }
      die "$_: file not found in \@INC\n";
   }
   wantarray ? @files : $files[0];
}

sub load_image {
   my $path = findfile $_[0];
   new_from_file Gtk2::Gdk::Pixbuf $path
      or die "$path: $!";
}

sub load_images {
   @::black_img    =       load_image "Gtk2/GoBoard/images/b-01.png";
   @::white_img    = map +(load_image "Gtk2/GoBoard/images/w-0$_.png"), 1,2,3,4,5;
   $::shadow_img   =       load_image "Gtk2/GoBoard/images/shadow.png";
   @::triangle_img = map +(load_image "Gtk2/GoBoard/images/triangle-$_.png"), qw(b w);
   @::square_img   = map +(load_image "Gtk2/GoBoard/images/square-$_.png"), qw(b w);
   @::circle_img   = map +(load_image "Gtk2/GoBoard/images/circle-$_.png"), qw(b w);
   $::board_img    =       load_image "Gtk2/GoBoard/images/woodgrain-01.jpg";
}

sub INIT_INSTANCE {
   my $self = shift;

   @::black_img
      or load_images;

   $self->double_buffered (0);
   $self->set (border_width => 0, shadow_type => 'none',
               obey_child => 0, ratio => TRAD_RATIO);

   $self->add ($self->{canvas} = new Gtk2::DrawingArea);

   $self->{canvas}->signal_connect (motion_notify_event  => sub { $self->motion });
   $self->{canvas}->signal_connect (leave_notify_event   => sub { $self->cursor (0); delete $self->{cursorpos} });
   $self->{canvas}->signal_connect (button_press_event   => sub { $self->button ("press", $_[1]) });
   $self->{canvas}->signal_connect (button_release_event => sub { $self->button ("release", $_[1]) });

   $self->{canvas}->signal_connect_after (configure_event => sub { $self->configure_event ($_[1]) });
   $self->{canvas}->signal_connect_after (realize => sub {
      my $window = $_[0]->window;
      my $color = new Gtk2::Gdk::Color 0xdfdf, 0xb2b2, 0x5d5d;
      $window->get_colormap->alloc_color ($color, 0, 1);
      $window->set_background ($color);
   });

   $self->{canvas}->set_events ([
      @{ $self->{canvas}->get_events },
     'leave-notify-mask',
     'button-press-mask',
     'button-release-mask',
     'pointer-motion-mask',
     'pointer-motion-hint-mask'
   ]);
}

sub SET_PROPERTY {
   my ($self, $pspec, $newval) = @_;

   $pspec = $pspec->get_name;

   $self->cursor (0) if $pspec eq "cursor";
   $self->{$pspec} = $newval;
   $self->cursor (1) if $pspec eq "cursor";
}

sub configure_event {
   my ($self, $event) = @_;

   return if $self->{idle};

   return unless $self->{canvas}->allocation->width  != $self->{width}
              || $self->{canvas}->allocation->height != $self->{height};

   my $drawable = $self->{window} = $self->{canvas}->window;
   $drawable->set_back_pixmap (undef, 0);

   delete $self->{stack};

   # remove Glib::Source $self->{idle};
   $self->{idle} ||= add Glib::Idle sub {
      $self->{width}  = $self->{canvas}->allocation->width;
      $self->{height} = $self->{canvas}->allocation->height;
      $self->draw_background;

      $self->draw_board (delete $self->{board}, 0) if $self->{board};
      $self->{window}->clear_area (0, 0, $self->{width}, $self->{height});

      delete $self->{idle};

      0;
   };

   1;
}

sub set_board {
   my ($self, $board) = @_;

   $self->cursor (0);
   $self->draw_board ($board, 1);
   $self->cursor (1);
}

sub new_pixbuf {
   my ($w, $h, $alpha, $fill) = @_;

   my $pixbuf = new Gtk2::Gdk::Pixbuf 'rgb', $alpha, 8, $w, $h;
   $pixbuf->fill ($fill) if defined $fill;

   $pixbuf;
}

sub scale_pixbuf {
   my ($src, $w, $h, $mode, $alpha) = @_;

   my $dst = new_pixbuf $w, $h, $alpha;

   $src->scale(
      $dst, 0, 0, $w, $h, 0, 0,
      $w / $src->get_width, $h / $src->get_height,
      $mode,
   );

   $dst;
}

sub pixbuf_rect {
   my ($pb, $colour, $x1, $y1, $x2, $y2, $alpha) = @_;
   # we fake lines by... a horrible method :/
   my $colour_pb = new_pixbuf 1, 1, 0, $colour;
   $colour_pb->composite ($pb, $x1, $y1, $x2 - $x1 + 1, $y2 - $y1 + 1, $x1, $y1, $x2 + 1, $y2 + 1,
                          'nearest', $alpha);
}

sub center_text {
   my ($self, $drawable, $colour, $x, $y, $size, $text) = @_;

   # could be optimized by caching quite a bit

   my $context = $self->get_pango_context;
   my $font = $context->get_font_description;
   $font->set_size ($size * Gtk2::Pango->scale);

   my $layout = new Gtk2::Pango::Layout $context;
   $layout->set_text ($text);
   my ($w, $h) = $layout->get_pixel_size;

   my $gc = new Gtk2::Gdk::GC $drawable;

   my $r = (($colour >> 24) & 255) * (65535 / 255);
   my $g = (($colour >> 16) & 255) * (65535 / 255);
   my $b = (($colour >>  8) & 255) * (65535 / 255);

   $gc->set_rgb_fg_color (new Gtk2::Gdk::Color $r, $g, $b);
   
   $drawable->draw_layout ($gc, $x - $w*0.5, $y - $h*0.5, $layout);
}

# draw an empty board and attach the bg pixmap
sub draw_background {
   my ($self) = @_;
   my $canvas = $self->{canvas};

   my $size = $self->{size};

   my $w = $self->{width};
   my $h = $self->{height};

   my $pixmap = new Gtk2::Gdk::Pixmap $self->window, $w, $h, -1;

   #my $gridcolour  = 0x88444400; # black is traditional, but only with overlapping stones
   my $gridcolour  = 0x44444400; # black is traditional, but only with overlapping stones
   my $labelcolour = 0x88444400;

   # we leave enough space for the shadows.. I like smaller stones, and we
   # do no need to do the nifty recursive screen updates that cgoban2 does
   my $borderw = int ($w / ($size + 1) * 0.5);
   my $borderh = $borderw;
   my $w2      = $w - $borderw * 2;
   my $h2      = $h - $borderh * 2;
   my $edge    = ceil ($w2 / ($size + 1));
   my $ofs     = $edge * 0.5;

   my @kx = map int ($w2 * $_ / ($size+1) + $borderw + 0.5), 0 .. $size; $self->{kx} = \@kx;
   my @ky = map int ($h2 * $_ / ($size+1) + $borderh + 0.5), 0 .. $size; $self->{ky} = \@ky;

   my $pixbuf;

   my ($bw, $bh) = ($::board_img->get_width, $::board_img->get_height);

   if ($w < $bw && $h < $bh) {
      $pixbuf = new_pixbuf $w, $h, 0;
      $::board_img->copy_area (0, 0, $w, $h, $pixbuf, 0, 0);
   } else {
      $pixbuf = scale_pixbuf $::board_img, $w, $h, $::config->{speed} ? 'nearest' : 'bilinear', 0;
   }

   my $linew = int ($w / 40 / $size);

   # ornamental border... we have time to waste :/
   pixbuf_rect $pixbuf, 0xffcc7700, 0, 0,           $w-1, $linew, 255;
   pixbuf_rect $pixbuf, 0xffcc7700, 0, 0,           $linew, $h-1, 255;
   pixbuf_rect $pixbuf, 0xffcc7700, $w-$linew-1, 0, $w-1, $h-1,   255;
   pixbuf_rect $pixbuf, 0xffcc7700, 0, $h-$linew-1, $w-1, $h-1,   255;

   for my $i (1 .. $size) {
      pixbuf_rect $pixbuf, $gridcolour, $kx[$i] - $linew, $ky[1] - $linew, $kx[$i] + $linew, $ky[$size] + $linew, 255;
      pixbuf_rect $pixbuf, $gridcolour, $kx[1] - $linew, $ky[$i] - $linew, $kx[$size] + $linew, $ky[$i] + $linew, 255;
   }

   # hoshi points
   my $hoshi = sub {
      my ($x, $y) = @_;
      my $hs = 1 | int $edge / 4;
      $hs = 5 if $hs < 5;
      $x = $kx[$x] - $hs / 2; $y = $ky[$y] - $hs / 2;

      # we use the shadow mask... not perfect, but I want to finish this
      $::shadow_img->composite ($pixbuf,
            $x, $y, ($hs + 1) x2, $x, $y,
            $hs / $::shadow_img->get_width, $hs / $::shadow_img->get_height,
            'bilinear', 255);
   };

   if ($size > 6) {
      my $h1 = $size < 10 ? 3 : 4; # corner / edge offset
      $hoshi->($h1, $h1);
      $hoshi->($size - $h1 + 1, $h1);
      $hoshi->($h1, $size - $h1 + 1);
      $hoshi->($size - $h1 + 1, $size - $h1 + 1);

      if ($size % 2) { # on odd boards, also the remaining 5
         my $h2 = ($size + 1) / 2;
         if ($size > 10) {
            $hoshi->($h1, $h2);
            $hoshi->($size - $h1 + 1, $h2);
            $hoshi->($h2, $size - $h1 + 1);
            $hoshi->($h2, $h1);
         }
         # the tengen
         $hoshi->($h2, $h2);
      }
   }

   # now we have a board sans text
   $pixmap->draw_pixbuf ($self->style->white_gc,
         $pixbuf,
         0, 0, 0, 0, $w, $h,
         "normal", 0, 0);

   # now draw the labels
   for my $i (1 .. $size) {
      # 38 max, but we allow a bit more
      my $label = (qw(- A  B  C  D  E  F  G  H  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
                        AA BB CC DD EE FF GG HH JJ KK LL MM NN OO PP QQ RR SS TT UU VV WW XX YY ZZ))[$i];

      $self->center_text ($pixmap, $labelcolour, $kx[$i], $borderh,       $ofs * 0.7, $label);
      $self->center_text ($pixmap, $labelcolour, $kx[$i], $h2 + $borderh, $ofs * 0.7, $label);
      $self->center_text ($pixmap, $labelcolour, $borderw, $ky[$i],       $ofs * 0.7, $size - $i + 1);
      $self->center_text ($pixmap, $labelcolour, $w2 + $borderw, $ky[$i], $ofs * 0.7, $size - $i + 1);
   }

   $self->{window}->set_back_pixmap ($pixmap, 0);

   $self->{backgroundpm} = $pixmap;
   $self->{backgroundpb} = $pixbuf;

   $edge = int ($edge * TRAD_SIZE_B / TRAD_SIZE_W);
   $ofs  = int ($edge * 0.5);

   {
      # shared vars for the stone drawing function
      my $shadow = $edge * SHADOW;
      my $pb;
      my @area;
      my @areai;
      my %stack;

      my $put_stack = sub {
         my ($x, $y, $dx, $dy, $ox, $oy) = @_;

         my $mark = $self->{board}{board}[$x-1][$y-1];

         if ($mark & ~MARK_LABEL) {
            my $stack = $stack{$mark} ||= $self->draw_stack ($mark, $edge);

            $stack->[($x ^ $y) % @$stack]
                  ->composite ($pb,
                               $ox, $oy,
                               $areai[2] + $dx - $ox, $areai[3] + $dy - $oy,
                               $dx + $ox, $dy + $oy,
                               1, 1, 'nearest', 255);
         }
      };

      $self->{draw_stone} = sub {
         my ($x, $y) = @_;

         @area  = ($kx[$x] - $ofs, $ky[$y] - $ofs,
                      $edge + $shadow, $edge + $shadow);
         @areai = ((ceil $area[0]), (ceil $area[1]),
                      (int $area[2]), (int $area[3])); # area, integer
         
         $pb = new_pixbuf @areai[2,3];
         $self->{backgroundpb}->copy_area (@areai, $pb, 0, 0);

         $put_stack->($x-1, $y, $kx[$x-1] - $kx[$x], 0, 0, 0) if $x > 1;
         $put_stack->($x, $y-1, 0, $ky[$y-1] - $ky[$y], 0, 0) if $y > 1;
         $put_stack->($x , $y , 0, 0);
         $put_stack->($x+1, $y, 0, 0, $kx[$x+1] - $kx[$x], 0) if $x < $size;
         $put_stack->($x, $y+1, 0, 0, 0, $ky[$y+1] - $ky[$y]) if $y < $size;

         # speed none, normal, max
         $self->{backgroundpm}->draw_pixbuf ($self->style->black_gc, $pb,
                                  0, 0, @areai, 'max', 0, 0);

         # labels are handled here because they are quite rare
         # (and we can't draw text into pixbufs easily)
         my $mark = $self->{board}{board}[$x-1][$y-1];

         if ($mark & MARK_LABEL) {
            my $white = $mark & (MARK_W | MARK_GRAY_W) ? 0 : 0xffffff00;

            if ($white) {
               $self->center_text ($self->{backgroundpm}, 0,
                                   $areai[0] + $ofs * 1.1, $areai[1] + $ofs * 1.1,
                                   $ofs * 0.7, $self->{board}{label}[$x-1][$y-1]);
            }
            $self->center_text ($self->{backgroundpm}, $white,
                                $areai[0] + $ofs, $areai[1] + $ofs,
                                $ofs * 0.7, $self->{board}{label}[$x-1][$y-1]);
         }

         undef $pb;
         
         [@areai];
      };
   }
}

# create a stack of stones, possibly in various versions
sub draw_stack {
   my ($self, $mark, $size) = @_;

   my @stack;
   my $csize = ceil $size;
   my $shadow = $size * SHADOW;

   for my $stone ($mark & MARK_W ? @::white_img : @::black_img) {
      my $base = new_pixbuf +(ceil $size + $shadow) x2, 1, 0x00000000;

      # zeroeth the shadow
      if (~$mark & MARK_GRAYED and $mark & (MARK_B | MARK_W)) {
         $::shadow_img->composite (
            $base, $shadow, $shadow, $csize, $csize, $shadow, $shadow,
            $size / $::shadow_img->get_width, $size / $::shadow_img->get_height,
            'bilinear', 128
         );
      }

      for ([MARK_B, $mark & MARK_GRAYED ?  96 : 255, 1],
           [MARK_W, $mark & MARK_GRAYED ? 160 : 255, TRAD_SIZE_W / TRAD_SIZE_B]) {
         my ($mask, $alpha, $scale) = @$_;
         if ($mark & $mask) {
            $stone->composite (
               $base, 0, 0, $csize, $csize, ($size * (1 - $scale) * 0.5 ) x2,
               $size * $scale / $stone->get_width, $size * $scale / $stone->get_height,
               'bilinear', $alpha
            );
         }
      }

      # then the small stones
      for ([MARK_SMALL_B, $::black_img[$rand % @::black_img]],
           [MARK_SMALL_W, $::white_img[$rand % @::white_img]]) {
         my ($mask, $img) = @$_;
         if ($mark & $mask) {
            $img->composite (
               $base, (int $size / 4) x2, (ceil $size / 2 + 1) x2, ($size / 4) x2,
               $size / $img->get_width / 2, $size / $img->get_height / 2,
               'bilinear', 255
            );
         }
      }

      # and lastly any markers
      my $dark_bg = ! ! ($mark & (MARK_B | MARK_GRAY_B));

      for ([MARK_CIRCLE,   $::circle_img[$dark_bg]],
           [MARK_TRIANGLE, $::triangle_img[$dark_bg]],
           [MARK_SQUARE,   $::square_img[$dark_bg]],
           [MARK_KO,       $::square_img[$dark_bg]]) {
        my ($mask, $img) = @$_;
        if ($mark & $mask) {
           $img->composite (
              $base, 0, 0, $size, $size, 0, 0,
              $size / $img->get_width, $size / $img->get_height,
              'bilinear', 176
           );
        }
      }

      push @stack, $base;
   }

   \@stack;
}

sub draw_board {
   my ($self, $new, $dopaint) = @_;

   ($self->{board}, my $old) = ($new, $self->{board});

   my $draw_stone = $self->{draw_stone};

   if ($self->{backgroundpb}) {
      my @areas;

      my $size1 = $self->{size} - 1;

      for my $x (0 .. $size1) {
         my $old = $old->{board}[$x];
         my $new = $new->{board}[$x];

         for my $y (0 .. $size1) {
            push @areas, $draw_stone->($x+1, $y+1)
               if $old->[$y] != $new->[$y];
         }
      }

      if ($dopaint && @areas) {
         # a single full clear_area is way faster than many single calls here
         # the "cut-off" point is quite arbitrary
         if (@areas > 64) {
            # update a single rectangle only
            my $rect = new Gtk2::Gdk::Rectangle @{pop @areas};
            $rect = $rect->union (new Gtk2::Gdk::Rectangle @$_) for @areas;
            $self->{window}->clear_area ($rect->values);
         } else {
            # update all the affected rectangles
            $self->{window}->clear_area (@$_) for @areas;
         }
      }
   }
}

sub cursor {
   my ($self, $show) = @_;

   return unless exists $self->{cursorpos}
                     && $self->{cursor}
                     && $self->{backgroundpb};

   my ($x, $y) = @{$self->{cursorpos}};

   my $mark = $self->{board}{board}[$x][$y];

   $mark = $self->{cursor}->($mark, $x, $y) if $show;

   local $self->{board}{board}[$x][$y] = $mark;
   $self->{window}->clear_area (@{ $self->{draw_stone}->($x + 1, $y + 1) });
}

sub motion {
   my ($self) = @_;

   return unless $self->{backgroundpb};

   my $window = $self->{canvas}->window;
   my (undef, $x, $y, undef) = $window->get_pointer;

   my $size = $self->{size};

   my $x = int (($x - $self->{kx}[0]) * $size / ($self->{kx}[$size] - $self->{kx}[0]) + 0.5) - 1;
   my $y = int (($y - $self->{ky}[0]) * $size / ($self->{ky}[$size] - $self->{ky}[0]) + 0.5) - 1;

   my $pos = $self->{cursorpos};
   if ($x != $pos->[0] || $y != $pos->[1]) {

      $self->cursor (0);

      if ($x >= 0 && $x < $size
          && $y >= 0 && $y < $size) {
         $self->{cursorpos} = [$x, $y];
         $self->cursor (1);
      } else {
         delete $self->{cursorpos};
      }
   }
}

sub do_button_press {
   my ($self, $button, $x, $y) = @_;
}

sub do_button_release {
   my ($self, $button, $x, $y) = @_;
}

sub button {
   my ($self, $type, $event) = @_;

   $self->motion;

   if ($self->{cursorpos}) {
      $self->signal_emit ("button-$type", $event->button, @{ $self->{cursorpos} });
   }
}

1;

