package Games::Minesweeper;

# http://txt.hello-penguin.com/6c206c05b150b767d55feb966a7654f6.txt
BEGIN  { $ENV{PERL_DL_NONLAZY} = 0; }

use strict;
use SDL ();
use SDL::Mixer ();
use Gtk2 ();
use Gtk2::SimpleMenu ();
use AnyEvent ();
use File::HomeDir ();

use Data::Dumper;

our $VERSION = "0.5";
our $custom_fix = 0;

=head1 NAME

Games::Minesweeper - another Minesweeper clone...

=cut

###################################################################################
# do things only needed for single-binary version (par)
BEGIN {
   if (%PAR::LibCache) {
      @INC = grep ref, @INC; # weed out all paths except pars loader refs

      my $root = $ENV{PAR_TEMP};

      while (my ($filename, $zip) = each %PAR::LibCache) {
         for ($zip->memberNames) {
            next unless /^root\/(.*)/;
            $zip->extractMember ($_, "$root/$1")
               unless -e "$root/$1";
         }
      }

      unshift @INC, $root;
   }
}

BEGIN {
   $ENV{GTK_RC_FILES} = "$ENV{PAR_TEMP}/share/themes/MS-Windows/gtk-2.0/gtkrc"
      if %PAR::LibCache && $^O eq "MSWin32";
}

unshift @INC, $ENV{PAR_TEMP};
###################################################################################


$SIG{CHLD} = 'IGNORE';

my $frame;
my $watcher;
my ($l, $d, $w);
my ($mine, $mine_red, $mine_wrong, $mine_hidden, $mine_flag, @m);
my ($smiley_img, $smiley_happy_img, $smiley_ohno_img, $smiley_stress_img);
my ($smiley);
my ($field_width, $field_height, $field_mines) = (9, 9, 10);
my ($tile_width, $tile_height) = (16, 16);
my @mine_field;
my ($mine_count, $open);
my $audio = 0;
my $mc;
my $game_over = 0;
my $menu;

sub save_prefs () {
   my $hd = my_home File::HomeDir;
   my $rcfile = "$hd/.minesweeperrc\0";
   my $fh;
   open $fh, ">", $rcfile
      or do { warn "can't create $rcfile: $!\n"; return; };
   print $fh "$field_width $field_height $field_mines $audio\n";
}

sub load_prefs () {
   my $hd = my_home File::HomeDir;
   my $rcfile = "$hd/.minesweeperrc\0";
   my $fh;
   open $fh, "<", $rcfile
      or do { warn "can't open $rcfile: $!"; return; };
   my $line = <$fh>;
   if(my ($w,$h, $m, $a) = $line =~ m/^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
      $audio = !!$a;
      $menu->get_widget ('/Game/Audio')->set_active ($audio);
      $w = 9 if $w < 9;
      $h = 9 if $h < 9;
      $m = 3 if $m < 3;
      ($field_width, $field_height, $field_mines) = ($w, $h, $m);
      {
       local $custom_fix = 1;
        $menu->get_widget ('/Game/Custom...')->set_active (1); #d#
      }

      $menu->get_widget ('/Game/Beginner')->set_active (1)     if $w ==  9 && $h ==  9 && $m == 10;
      $menu->get_widget ('/Game/Intermediate')->set_active (1) if $w == 16 && $h == 16 && $m == 40;
      $menu->get_widget ('/Game/Expert')->set_active (1)       if $w == 30 && $h == 16 && $m == 99;
   }
}

sub IS_MINE    () { 1 }
sub IS_OPEN    () { 2 }
sub IS_FLAGGED () { 4 }

sub init_field() {
   @mine_field = ();
   for my $x (0..$field_width-1) {
      for my $y (0..$field_height-1) {
         $mine_field[$x][$y] = 0;
      }
   }
   my $cnt = 0;
   while($cnt < $field_mines) {
      my $x = int rand ($field_width);
      my $y = int rand ($field_height);
      if (!$mine_field[$x][$y]) {
         $mine_field[$x][$y] = IS_MINE;
         $cnt++;
      }
   }
}

##
##   123   x->
##   4*5   y
##   678   |
##
sub count_mines ($$) {
   my ($x, $y) = @_;
   my $cnt = 0;
   $cnt += $mine_field[$x-1][$y-1] & IS_MINE if $x > 0 && $y > 0;                               # 1
   $cnt += $mine_field[$x][$y-1]   & IS_MINE if $y > 0;                                         # 2
   $cnt += $mine_field[$x+1][$y-1] & IS_MINE if $x < $field_width -1 && $y >0;                  # 3
   $cnt += $mine_field[$x-1][$y]   & IS_MINE if $x >0;                                          # 4
   $cnt += $mine_field[$x+1][$y]   & IS_MINE if $x < $field_width - 1;                          # 5
   $cnt += $mine_field[$x-1][$y+1] & IS_MINE if $x > 0 && $y < $field_height -1;                # 6
   $cnt += $mine_field[$x][$y+1]   & IS_MINE if $y < $field_height -1;                          # 7
   $cnt += $mine_field[$x+1][$y+1] & IS_MINE if $x < $field_width - 1 && $y < $field_height -1; # 8
   $cnt;
}

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

my %sound;
my $mixer;

sub init_sound() {
    $mixer = eval { SDL::Mixer->new(-frequency => 44100, -channels => 2, -size => 1024); };
    if ($@) {
        warn "init_sound: $@";
        $audio = 0;
    }
}

sub load_sounds () {
   init_sound;
   return unless $audio;
   for (qw/mouse_press mouse_release game_over win/) {
      my $file;
      $file = findfile "Games/Minesweeper/sounds/$_.wav"
         or die "findfile $file failed:  $!";
      $sound{$_} = new SDL::Sound ($file);
   }
}

sub play ($) {
  my $snd = shift;
  load_sounds unless exists $sound{$snd};
  $mixer->play_channel(-1, $sound{$snd}, 0);
}


sub about_dialog () {
  show_about_dialog Gtk2 ($w, "program-name" => 'Minesweeper',
                              authors => [ 'Stefan Traby', ],
                              license   => "This package is distributed under the same license as perl itself, i.e.\n".
                                           "either the Artistic License (COPYING.Artistic) or the GPLv2 (COPYING.GNU).",
                              copyright => "(c) 2008 by St.Traby <stefan\@hello-penguin.com>",
                              website   => 'http://oesiman.de',
                              version   => "v$VERSION",
                              comments  => "SDL version",
                              artists   => [ "Andreas Zehender" ],
  );
  1;
}
 

sub custom_dialog () {
     return if $custom_fix;
     my $q = [ [ "Height:", $field_height ],
               [ "Width:", $field_width ],
               [ "Mines:", $field_mines ],
             ];
    my $dialog = new Gtk2::Dialog("Customize", $w, 'modal', 'gtk-cancel' => 'cancel', OK => 'ok');
       $dialog->set_default_response ('ok');
    my @e;
    for my $i (0..2) {
        my $hb = new Gtk2::HBox; 
        my $l  = new Gtk2::Label ($q->[$i][0]);
        $e[$i] = new Gtk2::Entry;
        $e[$i]->set_text ($q->[$i][1]);
        $hb->add ($l);
        $hb->add ($e[$i]);
        $dialog->vbox->add ($hb);
    }
    $dialog->show_all;
    my $response = $dialog->run;
    $dialog->destroy;
    return 1 unless $response eq "ok";
    my ($h, $w, $m) = map +($e[$_]->get_text), (0..2);

    return if $h < 9 || $w < 9 || $m > $h*$w-10;
    ($field_width, $field_height, $field_mines) = ($w, $h, $m);
    restart();
}


sub full_expose() {
      my $update_rect = new Gtk2::Gdk::Rectangle (0, 0, $field_width*$tile_width, $field_height*$tile_height);
      $d->window->invalidate_rect ($update_rect, 0);
}

sub draw_xy($$$;$) {
   my ($x, $y, $img, $expose) = @_;
   $img->copy_area(0, 0, $tile_width, $tile_height, $frame, $x*$tile_width, $y*$tile_height);
   if ($expose) {
      my $update_rect = new Gtk2::Gdk::Rectangle ($x*$tile_width, $y*$tile_height, $tile_width, $tile_height);
      $d->window->invalidate_rect ($update_rect, 0);
   }
}

sub open_all() {
   for my $x (0..$field_width-1) {
      for my $y (0..$field_height-1) {
         my $f = $mine_field[$x][$y];
         next unless $f;

         if ($f & IS_MINE) {
            if ($f & IS_FLAGGED) {
               draw_xy ($x, $y, $mine_flag, 0)
            } else { # mine not flagged 
               if ($f & IS_OPEN) {
                  draw_xy ($x, $y, $mine_red, 0);
               } else {
                  draw_xy ($x, $y, $mine, 0)
               }
            }
         } else { # not a mine but open or flagged
            draw_xy ($x, $y, $mine_wrong, 0) if $f & IS_FLAGGED;
         }
      }
   }
   full_expose;
}


sub cleanup_cb {
   undef $watcher;
}

my $timer = 0;
sub timeout () {
      $l->set_text(sprintf "%.4d ", ++$timer);
      1;
}

sub stop_timer () {
   undef $watcher;
   $timer;
}

sub start_timer () {
   $timer = 0;
   $watcher = AnyEvent->timer (after => 1.0, interval => 1, cb => sub { timeout; });
}

sub update_mine_count() {
   $mc->set_text ( sprintf " %.3d", $mine_count);
}

sub expose_cb {
   my ($w, $e) = @_;
   #warn "expose: ".$e->area->x." ". $e->area->y." ".$e->area->width." ".$e->area->height;
   $frame->render_to_drawable ($w->window,  $w->style->black_gc,
                               $e->area->x, $e->area->y, 
                               $e->area->x, $e->area->y, 
                               $e->area->width, $e->area->height, 
                               'normal',
                               $e->area->x, $e->area->y);
   1;
}


sub around(&$$;$) {
   my ($func, $x, $y, $data) = @_;
   my $ret;
   $ret  = $func->($x-1, $y-1, $data)  if $x > 0 && $y > 0; 
   $ret |= $func->($x,   $y-1, $data)  if $y > 0;
   $ret |= $func->($x+1, $y-1, $data)  if $x < $field_width -1 && $y >0;
   $ret |= $func->($x-1, $y,   $data)  if $x >0;
   $ret |= $func->($x+1, $y,   $data)  if $x < $field_width - 1;
   $ret |= $func->($x-1, $y+1, $data)  if $x > 0 && $y < $field_height -1;
   $ret |= $func->($x,   $y+1, $data)  if $y < $field_height -1;
   $ret |= $func->($x+1, $y+1, $data)  if $x < $field_width - 1 && $y < $field_height -1;
   $ret;
}

my @event;
my @undo;

sub button_press_cb {
   return 1 if $game_over;
   my ($w, $e) = @_;
   play("mouse_press") if $audio;
   my ($x, $y, $b) = (int $e->x / $tile_width, int $e->y / $tile_height, $e->button);
   $event[$b] = [ $x, $y ];
   #warn "press x=$x y=$y b=$b mc=".count_mines($x, $y)."is_mine=".($mine_field[$x][$y] & IS_MINE)."\n";
   if($b == 3) {
     return 1 if $mine_field[$x][$y] & IS_OPEN;
     if ($mine_field[$x][$y] & IS_FLAGGED) {
        $mine_field[$x][$y] &= ~IS_FLAGGED;
        $mine_count++;
        draw_xy ($x, $y, $mine_hidden, 1);
     } else {
        $mine_field[$x][$y] |= IS_FLAGGED;
        $mine_count--;
        draw_xy ($x, $y, $mine_flag, 1);
     }
     update_mine_count;     

   } elsif ($b == 2) {
     $smiley->set_image ($smiley_stress_img);
     @undo = ();
     return 1 unless $mine_field[$x][$y] & IS_OPEN;
     around ( sub {
                  my ($x, $y) = @_;
                  if ($mine_field[$x][$y] < 2) { # empty or nonflagged
                     draw_xy ($x, $y, $m[0], 1);
                     push @undo, sub { draw_xy ($x, $y, $mine_hidden, 1); };
                  }
              }, $x, $y);
   } elsif ($b == 1) {
      return 1 if $mine_field[$x][$y] & (IS_OPEN | IS_FLAGGED);
      $smiley->set_image ($smiley_stress_img);
      draw_xy ($x, $y, $m[0], 1);
      if (!$watcher && $mine_field[$x][$y] & IS_MINE) { # first open field is not mine...
         for(;;) {
            my $nx = int rand ($field_width);
            my $ny = int rand ($field_height);
            if (!$mine_field[$nx][$ny]) {
                $mine_field[$nx][$ny] = IS_MINE;
                $mine_field[$x][$y] = 0;
                last;
            }
         }
      }
   }
   $watcher || start_timer;
   1;
}



my %visited;

sub deep_open2($$);

sub deep_open2 ($$) {
    my ($x, $y) = @_;
    $visited{$x,$y} = 1;
    my $cnt = count_mines ($x, $y);
    if (!$mine_field[$x][$y]) { # don't touch open fields and set mines...
       $mine_field[$x][$y] = IS_OPEN;
       draw_xy ($x, $y, $m[$cnt], 1);
       $open++;
    }
    return if $cnt;
    deep_open2 ($x+1, $y) if !$visited{$x+1,$y} && $x < $field_width -1;
    deep_open2 ($x, $y+1) if !$visited{$x,$y+1} && $y < $field_height -1;
    deep_open2 ($x-1, $y) if !$visited{$x-1,$y} && $x > 0;
    deep_open2 ($x, $y-1) if !$visited{$x,$y-1} && $y > 0;
}

sub deep_open ($$) {
   my ($x, $y) = @_;
   %visited = ();
   deep_open2 ($x, $y);

}

sub button_release_cb {
   return 1 if $game_over;
   my ($w, $e) = @_;
   my ($x,$y, $b) = (int $e->x / $tile_width, int $e->y / $tile_height, $e->button);
   #warn "release x=$x y=$y b=$b\n";

   play("mouse_release") if $audio;

# check if its the same tile else return...
   if ($x != $event[$b][0] || $y != $event[$b][1]) {
      draw_xy ($event[$b][0], $event[$b][1], $mine_hidden, 1) if $b == 1 && !$mine_field[$event[$b][0]][$event[$b][1]];
      if ($b == 2) {
        $_->() for(@undo);
      }
      $smiley->set_image ($smiley_img);
      return 1;
   }

   if ($b == 1) {
      if ($mine_field[$x][$y] & IS_MINE) {
         $mine_field[$x][$y] |= IS_OPEN;
         stop_timer;
         $game_over = 1;
         $smiley->set_image ($smiley_ohno_img);
         play ("game_over") if $audio;
         open_all;
         return 1;
      }
      deep_open ($x, $y);
      $smiley->set_image ($smiley_img);
   } elsif ($b == 2) {
      return 1 unless @undo;
      my $err = around (sub {
                            my ($x, $y) = @_;
                            my $m  = $mine_field[$x][$y];
                            return 0 unless $m;
                            if ($m & IS_MINE) {
                               return 0 if $m & IS_FLAGGED;
                               return 1;
                            } else {
                               return 1 if $m & IS_FLAGGED;
                               return 0;
                            }
                        }, $x, $y
                );
     if ($err) {
        around (sub { $mine_field[$_[0]][$_[1]] |= IS_OPEN; }, $x, $y);
        stop_timer;
        $game_over = 1;
        $smiley->set_image ($smiley_ohno_img);
        play ("game_over") if $audio;
        open_all;
        return 1;
     } else {
        around (sub { deep_open ($_[0], $_[1]) }, $x, $y);
     }

   } elsif ($b == 3) {
   }
   # check if solved...
   if ($open == $field_width*$field_height-$field_mines) {
      # we are finished, maybe not all mines are open.
      for my $x (0..$field_width-1) {
         for my $y (0..$field_height-1) {
            $mine_field[$x][$y] |= IS_FLAGGED if $mine_field[$x][$y] & IS_MINE;
         }
      }
      stop_timer;
      $mine_count = 0;
      update_mine_count;     
      play ('win') if $audio;
      open_all;
      $smiley->set_image ($smiley_happy_img);
      $game_over = 1;
      return 1;
   }

   $watcher or start_timer;
   1;
}

sub load_image {
   my $path = findfile $_[0];
   new_from_file Gtk2::Image $path
      or die "$path: $!";
}

sub load_pixbuf {
   my $path = findfile $_[0];
   new_from_file Gtk2::Gdk::Pixbuf $path
      or die "$path: $!";
}

sub load_images {
   $mine        =       load_pixbuf "Games/Minesweeper/images/mine.png";
   $mine_wrong  =       load_pixbuf "Games/Minesweeper/images/mine-wrong.png";
   $mine_hidden =       load_pixbuf "Games/Minesweeper/images/mine-hidden.png";
   $mine_flag   =       load_pixbuf "Games/Minesweeper/images/mine-flag.png";
   $mine_red    =       load_pixbuf "Games/Minesweeper/images/mine-red.png";
   @m           = map +(load_pixbuf "Games/Minesweeper/images/mine-$_.png"), (0..8);

   $smiley_img        = load_image "Games/Minesweeper/images/smile.png";
   $smiley_happy_img  = load_image "Games/Minesweeper/images/smile_happy.png";
   $smiley_ohno_img   = load_image "Games/Minesweeper/images/smile_ohno.png";
   $smiley_stress_img = load_image "Games/Minesweeper/images/smile_stress.png";
}


sub restart () {
   stop_timer;
   $l->set_text ('0000 ');
   init_field;
   my ($bw, $bh) = ($field_width*$tile_width, $field_height*$tile_height);
   $d->set_size_request($bw, $bh);
   $frame = Gtk2::Gdk::Pixbuf->new ('rgb', 1, 8, $bw, $bh);
   for my $x (0..$field_width-1) {
      for my $y (0..$field_height-1) {
         draw_xy ($x, $y, $mine_hidden, 0);
      } 
   }
   full_expose;
   $mine_count = $field_mines;
   update_mine_count;
   $open = 0;
   $smiley->set_image ($smiley_img);
   $game_over = 0;
   1;
}

sub new_minesweeper () {
   $mine or load_images;
   $w = Gtk2::Window->new ('toplevel');
   $w->set_resizable (0);
   my $v =  new Gtk2::VBox;
   my $f1 = new Gtk2::Frame;
   my $f2 = new Gtk2::Frame;
   $d = new Gtk2::DrawingArea;
   $smiley = new Gtk2::Button;
   #$smiley->set_relief ('none');
   #$smiley->set_alignment (0.5, 0.5);
   $smiley->set_image ($smiley_img);

   my $menu_tree = [ 
           _Game => {
                 item_type => '<Branch>',
                 children => [
                    _New  => { callback => sub { restart; },
                               accelerator => 'F2',
                         },
                         Separator => { item_type => '<Separator>',
                         },
                         _Beginner  => {  callback => sub { return unless $menu->get_widget ("/Game/Beginner")->get_active;
                                                            ($field_width, $field_height, $field_mines) = (9, 9, 10); restart; },
                                          item_type => '<RadioItem>',
                                          groupid => 1,
                         },
                         _Intermediate  => { callback => sub { return unless $menu->get_widget ("/Game/Intermediate")->get_active;
                                                               ($field_width, $field_height, $field_mines) = (16, 16, 40); restart; },
                                             item_type => '<RadioItem>',
                                             groupid => 1,
                         },
                         _Expert  => { callback => sub { return unless $menu->get_widget ("/Game/Expert")->get_active;
                                                         ($field_width, $field_height, $field_mines) = (30, 16, 99); restart; },
                                       item_type => '<RadioItem>',
                                       groupid => 1,
                         },
                         '_Custom...' => { callback => sub { return unless $menu->get_widget ("/Game/Custom...")->get_active;
                                                             custom_dialog; },
                                           item_type => '<RadioItem>',
                                           groupid => 1,
                         },
                         Separator => { item_type => '<Separator>',
                         },
                         _Audio => { callback =>  sub { $audio = 0 + $menu->get_widget ('/Game/Audio')->get_active; },
                                     item_type => '<CheckItem>', 
                         },
                         Separator => { item_type => '<Separator>',
                         },
                         E_xit => { callback => sub { save_prefs; main_quit Gtk2; },
                                    accelerator => '<Alt>X',
                         },
                 ],
           },
           "_?" => { 
                 item_type => '<Branch>',
                 children => [
                     _About => { callback => sub { about_dialog; },
                                 accelerator => 'F1',
                               }
                 ],
           },
         ]; 

      $menu = new Gtk2::SimpleMenu (menu_tree => $menu_tree,
                                );
      $l = new Gtk2::Label ('0000 ');
      $mc = new Gtk2::Label (' 000');
      $smiley->signal_connect (clicked => sub { restart; });
      $d->set_events ([ 'button_release_mask', 'button_press_mask', ]); #'pointer_motion_mask' ]);
      $d->signal_connect (expose_event => \&expose_cb);
      $d->signal_connect (button_press_event => \&button_press_cb);
      $d->signal_connect (button_release_event => \&button_release_cb);
      $f2->set_border_width(5);
      my $fixbox = new Gtk2::HBox;
      my $fix1 = new Gtk2::Frame;
      my $fix2 = new Gtk2::Frame;
      $fix1->set_shadow_type ('none');
      $fix1->set_border_width (0);
      $fix2->set_shadow_type ('none');
      $fix2->set_border_width (0);
      $fixbox->pack_start ($fix1, 1, 1, 1);
      $f2->add ($d);
      $fixbox->pack_start ($f2, 0, 0, 0);
      $fixbox->pack_start ($fix2, 1, 1, 1);
      my $vb = new Gtk2::VBox;
      my $hb = new Gtk2::HBox;
      $hb->pack_start ($mc, 0, 0, 0);
      $hb->pack_start ($smiley, 1, 0, 0);
      $hb->pack_end ($l, 0, 0, 0);
      $vb->add ($hb);
      $vb->pack_start ($fixbox, 1, 0, 0);
      $f1->add ($vb);
      $v->add ($menu->{widget});
      $w->add_accel_group ($menu->{accel_group});
      $v->pack_start ($f1, 1, 0, 0);
      $w->add ($v);
      $w->signal_connect( destroy => sub { save_prefs; main_quit Gtk2; });
      $w->signal_connect( destroy => \&cleanup_cb);
      $d->realize;
      load_prefs;
      restart;
      $w;
}
1;
