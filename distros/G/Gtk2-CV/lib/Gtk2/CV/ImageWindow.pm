=head1 NAME

Gtk2::CV::ImageWindow - a window widget displaying an image or other media

=head1 SYNOPSIS

  use Gtk2::CV::ImageWindow;

=head1 DESCRIPTION

=head2 METHODS

=over 4

=cut

package Gtk2::CV::ImageWindow;

use common::sense;
use Gtk2;
use Gtk2::Gdk::Keysyms;

use Gtk2::CV;
use Gtk2::CV::PrintDialog;

use List::Util qw(min max);

use Scalar::Util;
use POSIX ();
use FileHandle ();
use Errno ();
use Fcntl ();
use Socket ();

my $title_image;

use Glib::Object::Subclass
   Gtk2::Window::,
   properties => [
      Glib::ParamSpec->scalar ("path", "Pathname", "The image pathname", [qw(writable readable)]),
   ],
   signals => {
      image_changed        => { flags => [qw/run-first/], return_type => undef, param_types => [] },
      button3_press_event  => { flags => [qw/run-first/], return_type => undef, param_types => [] },

      button_press_event   => sub { $_[0]->do_button_press (1, $_[1]) },
      button_release_event => sub { $_[0]->do_button_press (0, $_[1]) },
      motion_notify_event  => \&motion_notify_event,
      show                 => sub {
         $_[0]->realize_image;
         $_[0]->signal_chain_from_overridden;
      },
   };

our $SET_ASPECT;

sub INIT_INSTANCE {
   my ($self) = @_;

   $self->push_composite_child;

   $self->double_buffered (0);

   $self->set_role ("image window");

   $self->signal_connect (destroy => sub { $self->kill_player });
   $self->signal_connect (realize => sub { $_[0]->do_realize; 0 });
   $self->signal_connect (map_event => sub { $_[0]->check_screen_size; $_[0]->auto_position (($_[0]->allocation->values)[2,3]) });
   $self->signal_connect (expose_event => sub {
      # in most cases, we get no expose events, except when our _own_ popups
      # obscure some part of the window. se we have to do lots of unneessary refreshes :(
      $self->{window}->clear_area ($_[1]->area->values);
      $self->draw_drag_rect ($_[1]->area);
      1 
   });
   $self->signal_connect (configure_event => sub { $_[0]->do_configure ($_[1]); 0 });
   $self->signal_connect (key_press_event => sub { $_[0]->handle_key ($_[1]->keyval, $_[1]->state) });

   $self->{frame_extents_property}         = Gtk2::Gdk::Atom->intern ("_NET_FRAME_EXTENTS", 0);
   $self->{request_frame_extents_property} = Gtk2::Gdk::Atom->intern ("_NET_REQUEST_FRAME_EXTENTS", 0);

   $self->signal_connect (property_notify_event => sub {
      return unless $_[0]{frame_extents_property} == $_[1]->atom;

      $self->update_properties;

      0
   });

   $self->add_events ([qw(key_press_mask focus-change-mask button_press_mask property_change_mask
                          button_release_mask pointer-motion-hint-mask pointer-motion-mask)]);
   $self->can_focus (1);
   $self->set_size_request (0, 0);
   #$self->set_resize_mode ("immediate");

   $self->{interp} = 'bilinear';

   $self->pop_composite_child;

   $self->clear_image;
}

sub SET_PROPERTY { 
   my ($self, $pspec, $newval) = @_;

   $pspec = $pspec->get_name;
   
   if ($pspec eq "path") {
      $self->load_image ($newval);
   } else {
      $self->{$pspec} = $newval;
   }
}

sub do_image_changed {
   my ($self) = @_;
}

sub kill_player {
   my ($self) = @_;

   if ($self->{player_pid} > 0) {

      if ($self->{mplayer_fh}) {
         local $SIG{PIPE} = 'IGNORE';
         print {$self->{mplayer_fh}} "quit\n";
         delete $self->{mplayer_fh};
      } else {
         kill INT  => $self->{player_pid};
         kill TERM => $self->{player_pid};
      }
      waitpid delete $self->{player_pid}, 0;
      (delete $self->{mplayer_box})->destroy if $self->{mplayer_box};
   }
}

sub set_subimage {
   my ($self, $image) = @_;

   $self->force_redraw;

   $self->{subimage} = $image;

   $self->{iw} = $image->get_width;
   $self->{ih} = $image->get_height;

   if ($self->{iw} && $self->{ih}) {
      $self->auto_resize;
   } else {
      $self->clear_image;
   }
}

=item $img->set_image ($gdk_pixbuf[, $type])

Replace the currently-viewed image by the given pixbuf.

=cut

sub set_image {
   my ($self, $image, $type) = @_;

   $self->{type}        = $type;
   $self->{image}       = $image;
   $self->{tran_rotate} = 0;
   $self->{path}        = undef;

   $self->set_subimage ($image);
}

=item $img->clear_image

Removes the current image (usually replacing it by the default image).

=cut

sub clear_image {
   my ($self) = @_;

   $self->kill_player;

   delete $self->{image};
   delete $self->{subimage};
   delete $self->{tran_rotate};
   delete $self->{path};

   if ($self->{window} && $self->{window}->is_visible) {
      $self->realize_image;
   }
}

sub realize_image {
   my ($self) = @_;

   return if $self->{image};

   $title_image ||= Gtk2::CV::require_image "cv.png";
   $self->set_image ($title_image);
   Scalar::Util::weaken $title_image;
}

=item $img->load_image ($path)

Tries to load the given file (if it is an image), or embeds mplayer (if
mplayer supports it).

=cut

my %othertypes = (
   "Microsoft ASF"  => "video/x-asf",
   "RealMedia file" => "video/x-rm",
   "Matroska data"  => "video/x-ogg",
   "Ogg data, OGM video (XviD)" => "video/x-ogg",
   "Ogg data, OGM video (DivX 5)" => "video/x-ogg",
   "RIFF (little-endian) data, wrapped MPEG-1 (CDXA)" => "video/mpeg",
);

my %exttypes = (
   mpg  => "video/mpeg",
   mpeg => "video/mpeg",
   ogm  => "video/x-ogg",
);

#sub gstreamer_setup {
#   my ($self, $path) = @_;
#
#   require GStreamer;
#   GStreamer->init;
#
#   my $bin = GStreamer::ElementFactory->make (playbin => "CV")
#      or return;
#
#   $bin->set (uri => (Glib::filename_to_uri $path, "localhost"), async => 0);
#   $bin->get_bus->add_watch (sub {
#      my ($bus, $msg) = @_;
#
#      return unless $msg->src == $bin;
#
#      my $type = $msg->type;
#
##      warn $type;
#      if ($type eq "error") {
#         warn $msg->error;
#      } elsif ($type eq "segment-done") {
#         $bin->seek (1, "time", "segment", set => 0, end => 0);
#      }
#
#      1
#   });
#
#   $bin->set_state ("paused");
#   $bin->sync_state; # perl cannot do non-blocking gstreamer stuff yet
#   my $dur = new GStreamer::Query::Duration "time";
#   $bin->query ($dur) or return;
#   warn join ":", $dur->duration;
#   $bin->seek (1, "time", "segment", set => 0, end => 0);
#   $bin->set_state ("playing");
#
#
#   my $image = new Gtk2::Gdk::Pixbuf "rgb", 0, 8, 64, 48;
#   $image->fill ("\0\0\0");
#
#   $image
#}

sub load_image {
   my ($self, $path) = @_;

   $self->kill_player;
   $self->force_redraw;

   my $image;
   my $type = Gtk2::CV::magic_mime $path;

   if ($type =~ /^application\//) {
      my $magic = Gtk2::CV::magic $path;
      $type = $othertypes{$magic}
         if exists $othertypes{$magic};
   }

   if (!length $type && $path =~ /\.([^.]+)$/) {
      $type = $exttypes{lc $1};
   }

   $type =~ s/;.*//; # remove ; charset= etc.

   $@ = "generic file display error";

   if ($type eq "application/octet-stream" or $type =~ /^text\//) {
      $@ = "unrecognised file format";
      # should, but can't

   } elsif ($type eq "image/jpeg") {
      $image = Gtk2::CV::load_jpeg $path;

   } elsif ($type eq "image/jp2") { # jpeg2000 hack
      open my $pnm, "-|:raw", "jasper", "--input", $path, "--output-format", "pnm"
         or die "error running jasper (jpeg2000): $!";
      my $loader = new_with_type Gtk2::Gdk::PixbufLoader "pnm";
      local $/; $loader->write (<$pnm>);
      $loader->close;
      $image = $loader->get_pixbuf;

   } elsif ($type eq "application/pdf") {
      # hack, sorry, unsupported, should use mimetools etc.
      system "xpdf \Q$path\E &";

   } elsif ($type =~ /^image\//) {
      open my $fh, "<", $path
         or die "$path: $!";
      my $loader = new Gtk2::Gdk::PixbufLoader;
      local $/; $loader->write (<$fh>);
      $loader->close;
      $image = $loader->get_pixbuf;

   } elsif ($type =~ /^(audio\/|application\/ogg$)/) {
      if (1 || exists $ENV{CV_AUDIO_PLAYER}) {
         $self->{player_pid} = fork;

         if ($self->{player_pid} == 0) {
#            open STDIN , "</dev/null";
#            open STDOUT, ">/dev/null";
#            open STDERR, ">&2";

            my $player = $ENV{CV_AUDIO_PLAYER} || "play";
            $path = "./$path" if $path =~ /^-/;
            exec "$player \Q$path";
            POSIX::_exit 0;
         }
      } else {
         $image = $self->gstreamer_setup ($path);
      }

   } elsif ($type =~ /^(?:video|application)\//) {
      $path = "./$path" if $path =~ /^-/;

      # try video
      my $mplayer = qx{LC_ALL=C exec mplayer </dev/null 2>/dev/null -sub /dev/null -sub-fuzziness 0 -cache-min 0 -input nodefault-bindings:conf=/dev/null -identify -vo null -ao null -frames 0 \Q$path};

      my $w = $mplayer =~ /^ID_VIDEO_WIDTH=(\d+)$/sm ? $1 : undef;
      my $h = $mplayer =~ /^ID_VIDEO_HEIGHT=(\d+)$/sm ? $1 : undef;

      if ($w && $h) {
         if ($mplayer =~ /^ID_VIDEO_ASPECT=([0-9\.]+)$/sm && $1 > 0) {
            $w = POSIX::ceil $w * $1 * ($h / $w); # correct aspect ratio, assume square pixels
         } else {
            # no idea what to do, mplayer's aspect factors seem to be random
            #$w = POSIX::ceil $w * 1.50 * ($h / $w); # correct aspect ratio, assume square pixels
            #$w = POSIX::ceil $w * 1.33;
         }

         $type = "video";
         $image = new Gtk2::Gdk::Pixbuf "rgb", 0, 8, $w, $h;
         $image->fill ("\0\0\0");

         # d'oh, we need to do that because realize() doesn't reliably cause
         # the window to have the correct size
         $self->show;

         # add a couple of windows just for mplayer's sake
         my $box = $self->{mplayer_box} = new Gtk2::EventBox;
         $box->set_above_child (1);
         $box->set_visible_window (0);
         $box->set_events ([]);
         $box->can_focus (0);

         my $window = new Gtk2::DrawingArea;
         $box->add ($window);
         $self->add ($box);
         $box->show_all;
         $window->realize;

         $self->{mplayer_window} = $window;

         my $xid = $window->window->get_xid;

         socketpair my $sfh, my $mfh, Socket::AF_UNIX (), Socket::SOCK_STREAM (), 0;
         $self->{mplayer_fh} = $mfh;
         $mfh->autoflush (1);
         fcntl $mfh, Fcntl::F_SETFD (), Fcntl::FD_CLOEXEC ();
         fcntl $mfh, Fcntl::F_SETFL (), Fcntl::O_NONBLOCK ();

         $self->{player_pid} = fork;

         if ($self->{player_pid} == 0) {
            $ENV{LC_ALL} = "C";

            open STDIN, "<&" . fileno $sfh;
            open STDOUT, ">&" . fileno $sfh;
            #open STDOUT, ">/dev/null";
            open STDERR, ">/dev/null";

            exec "mplayer", qw(-slave -nofs -nokeepaspect -input nodefault-bindings:conf=/dev/null -zoom -fixed-vo -quiet -loop 0),
                            -wid => $xid, $path;
            POSIX::_exit 0;
         }

         close $sfh;

         print $mfh "get_file_name\n";

         my $input;
         add_watch Glib::IO fileno $mfh, in => sub {
            my $len = sysread $mfh, $input, 128, length $input;

            if ($len > 0) {
               while ($input =~ s/^(.*)\n//) {
                  my $line = $1;

                  if ($line =~ /ANS_FILENAME=/) {
                     # presumably, everything is set-up now
                     $self->update_mplayer_window;
                  }
               }
            } elsif (defined $len or $! != Errno::EAGAIN) {
               return 0;
            }

            1
         };
      } else {
         $@ = "mplayer doesn't recognize this '$type' file";
         # probably audio, or a real error
      }

   } else {
      $@ = "unrecognized file format '$type'";
   }

   if (!$image) {
      warn "$@";

      $type = "error";
      $image = Gtk2::CV::require_image "error.png";
   }

   if ($image) {
      $self->set_image ($image, $type);
      $self->{path} = $path;
      $self->set_title ("CV: $path");
   } else {
      $self->clear_image;
   }
}

sub reload {
   my ($self) = @_;

   $self->load_image ($self->{path}) if defined $self->{path};
}

sub check_screen_size {
   my ($self) = @_;

   my ($left, $right, $top, $bottom) = @{ $self->{frame_extents} || [] };

   my $sw = $self->{screen_width}  - ($left + $right);
   my $sh = $self->{screen_height} - ($top + $bottom);

   if ($self->{sw} != $sw || $self->{sh} != $sh) {
      ($self->{sw},  $self->{sh})  = ($sw, $sh);
      ($self->{rsw}, $self->{rsh}) = ($sw, $sh);
      $self->auto_resize if $self->{image};
   }
}

sub update_properties {
   my ($self) = @_;

   (undef, undef, my @data) = $_[0]->{window}->property_get (
      $_[0]{frame_extents_property}, 
      Gtk2::Gdk::Atom->intern ("CARDINAL", 0),
      0, 4*4, 0);
   # left, right, top, bottom
   $self->{frame_extents} = \@data;

   $self->check_screen_size;
}

sub request_frame_extents {
   my ($self) = @_;

   return if $self->{frame_extents};
   return unless Gtk2::CV::gdk_net_wm_supports $self->{request_frame_extents_property};

   # TODO
   # send clientmessage
}

sub do_realize {
   my ($self) = @_;

   $self->{window} = $self->window;

   $self->{drag_gc} = Gtk2::Gdk::GC->new ($self->{window});
   $self->{drag_gc}->set_function ('xor');
   $self->{drag_gc}->set_rgb_foreground (new Gtk2::Gdk::Color 0x8000, 0x8000, 0x8000);
   $self->{drag_gc}->set_line_attributes (1, 'solid', 'round', 'miter');

   $self->{screen_width}  = $self->{window}->get_screen->get_width;
   $self->{screen_height} = $self->{window}->get_screen->get_height;

   $self->realize_image;
   $self->request_frame_extents;

   $self->check_screen_size;

   0
}

sub draw_drag_rect {
   my ($self, $area) = @_;

   my $d = $self->{drag_info}
      or return;

   my $x1 = min @$d[0,2];
   my $y1 = min @$d[1,3];

   my $x2 = max @$d[0,2];
   my $y2 = max @$d[1,3];

   $_ = $self->{sx} * int .5 + $_ / $self->{sx} for ($x1, $x2);
   $_ = $self->{sy} * int .5 + $_ / $self->{sy} for ($y1, $y2);

   $self->{drag_gc}->set_clip_rectangle ($area)
      if $area;

   $self->{window}->draw_rectangle ($self->{drag_gc}, 0,
                                    $x1, $y1, $x2 - $x1, $y2 - $y1);

   # workaround for Gtk2-bug, arg should be undef
   $self->{drag_gc}->set_clip_region ($self->{window}->get_clip_region)
      if $area;
}

sub do_button_press {
   my ($self, $press, $event) = @_;

   if ($event->button == 3) {
      $self->signal_emit ("button3_press_event") if $press;
   } else {
      if ($press) {
         $self->{drag_info} = [ ($event->x, $event->y) x 2 ];
         $self->draw_drag_rect;
      } elsif ($self->{drag_info}) {
         $self->draw_drag_rect;

         my $d = delete $self->{drag_info};

         my ($x1, $y1, $x2, $y2) = (
            (min @$d[0,2]) / $self->{sx},
            (min @$d[1,3]) / $self->{sy},
            (max @$d[0,2]) / $self->{sx},
            (max @$d[1,3]) / $self->{sy},
         );

         return unless ($x2-$x1) > 8 && ($y2-$y1) > 8;

         $self->crop ($x1, $y1, $x2, $y2);
      } else {
         return 0;
      }
   }

   1
}

sub motion_notify_event {
   my ($self, $event) = @_;

   return unless $self->{drag_info};

   my ($x, $y, $state);

   if ($event->is_hint) {
      (undef, $x, $y, $state) = $event->window->get_pointer;
   } else {
      $x = $event->x;
      $y = $event->y;
      $state = $event->state;
   }
   $x = max 0, min $self->{dw}, $event->x;
   $y = max 0, min $self->{dh}, $event->y;

   # erase last
   $self->draw_drag_rect;

   # draw next
   @{$self->{drag_info}}[2,3] = ($x, $y);
   $self->draw_drag_rect;

   1
}

sub auto_position {
   my ($self, $w, $h) = @_;

   if ($self->{window}) {
      my ($x, $y) = $self->get_position;
      my $nx = max 0, min $self->{rsw} - $w, $x;
      my $ny = max 0, min $self->{rsh} - $h, $y;
      $self->move ($nx, $ny) if $nx != $x || $ny != $y;
   }
}

sub auto_resize {
   my ($self) = @_;

   if ($self->{maxpect}
       || $self->{iw} > $self->{sw}
       || $self->{ih} > $self->{sh}) {
      $self->resize_maxpect;
   } else {
      $self->resize ($self->{iw}, $self->{ih});
   }
}

=item $img->resize_maxpect

Resize the image so it is maximally large.

=cut

sub resize_maxpect {
   my ($self) = @_;

   my ($w, $h) = (int ($self->{iw} * $self->{sh} / $self->{ih}),
                  int ($self->{sh}));
   ($w, $h) = ($self->{sw}, $self->{ih} * $self->{sw} / $self->{iw}) if $w > $self->{sw};

   $self->resize ($w, $h);
}

=item $img->resize ($width, $height)

Resize the image window to the given size.

=cut

sub resize {
   my ($self, $w, $h) = @_;
   
   return unless $self->{window};

   my $w = max (16, min ($self->{rsw}, $w));
   my $h = max (16, min ($self->{rsh}, $h));

   $self->{dw} = $w;
   $self->{dh} = $h;

   if ($Gtk2::CV::ImageWindow::SET_ASPECT) {
      Gtk2::CV::gdk_window_clear_hints ($self->{window});
      $self->{window}->get_screen->get_display->flush;
   }

   $self->auto_position ($w, $h);
   $self->{window}->resize ($w, $h);

   if ($Gtk2::CV::ImageWindow::SET_ASPECT) {
      my $minaspect = $w / $h;
      my $maxaspect = $w / $h;

      my $hints = new Gtk2::Gdk::Geometry;
      $hints->max_aspect ($maxaspect);
      $hints->min_aspect ($minaspect);
      $self->set_geometry_hints ($self, $hints, [qw/aspect/]);
      $self->{window}->get_screen->get_display->flush;
   }

   $self->redraw;
}

=item $img->uncrop

Undo any cropping; Show the full image.

=cut

sub uncrop {
   my ($self) = @_;

   $self->set_subimage ($self->{image});
}

=item $img->crop ($x1, $y1, $x2, $y2)

Crop the image to the specified rectangle.

=cut

sub crop {
   my ($self, $x1, $y1, $x2, $y2) = @_;

   my $w = max ($x2 - $x1, 1);
   my $h = max ($y2 - $y1, 1);

   $self->set_subimage (
      $self->{subimage}->new_subpixbuf ($x1, $y1, $w, $h)
   );
}

sub update_mplayer_window {
   my ($self) = @_;

   # force a resize of the mplayer window, otherwise it doesn't receive
   # a configureevent :/
   $self->{mplayer_window}->window->resize (1, 1),
   $self->{mplayer_window}->window->resize ($self->{w}, $self->{h})
      if $self->{mplayer_window}
         && $self->{mplayer_window}->window;
}

sub do_configure {
   my ($self, $event) = @_;

   my $window = $self->window;

   my ($sw, $sh) = ($self->{sw}, $self->{sh});

   my ($x, $y) = ($event->x    , $event->y     );
   my ($w, $h) = ($event->width, $event->height);

   $self->{w} = $w;
   $self->{h} = $h;

   $self->update_mplayer_window;

   return unless $self->{subimage};

   $w = max (16, $w);
   $h = max (16, $h);

   return if $self->{dw} == $w && $self->{dh} == $h;

   $self->{dw} = $w;
   $self->{dh} = $h;

   $self->schedule_redraw;
}

sub handle_key {
   my ($self, $key, $state) = @_;

   local $SIG{PIPE} = 'IGNORE'; # for mplayer_fh

   if ($state * "control-mask") {
      if ($key == $Gtk2::Gdk::Keysyms{p}) {
         new Gtk2::CV::PrintDialog pixbuf => $self->{subimage}, aspect => $self->{dw} / $self->{dh};

      } elsif ($key == $Gtk2::Gdk::Keysyms{m}) {
         $self->{maxpect} = !$self->{maxpect};
         $self->auto_resize;

      } elsif ($key == $Gtk2::Gdk::Keysyms{M}) {
         if ($self->{rsw} == $self->{sw} && $self->{rsh} == $self->{sh}) {
            ($self->{sw}, $self->{sh}) = ($self->{dw},  $self->{dh});
         } else {
            ($self->{sw}, $self->{sh}) = ($self->{rsw}, $self->{rsh});
         }

      } elsif ($key == $Gtk2::Gdk::Keysyms{e}) {
         if (fork == 0) {
            exec $ENV{CV_EDITOR} || "gimp", $self->{path};
            exit;
         }

      } else {
         return 0;
      }

   } else {
      if ($key == $Gtk2::Gdk::Keysyms{less}) {
         $self->resize ($self->{dw} * 0.5, $self->{dh} * 0.5);

      } elsif ($key == $Gtk2::Gdk::Keysyms{greater}) {
         $self->resize ($self->{dw} * 2, $self->{dh} * 2);

      } elsif ($key == $Gtk2::Gdk::Keysyms{comma}) {
         $self->resize ($self->{dw} * 0.9, $self->{dh} * 0.9);

      } elsif ($key == $Gtk2::Gdk::Keysyms{period}) {
         $self->resize ($self->{dw} * 1.1, $self->{dh} * 1.1);

      } elsif ($key == $Gtk2::Gdk::Keysyms{n}) {
         $self->auto_resize;

      } elsif ($key == $Gtk2::Gdk::Keysyms{m}) {
         $self->resize ($self->{sw}, $self->{sh});

      } elsif ($key == $Gtk2::Gdk::Keysyms{M}) {
         $self->resize_maxpect;

      } elsif ($key == $Gtk2::Gdk::Keysyms{u}) {
         $self->uncrop;

      } elsif ($key == $Gtk2::Gdk::Keysyms{r}) {
         $self->{interp} = 'nearest';
         $self->force_redraw; $self->redraw;

      } elsif ($key == $Gtk2::Gdk::Keysyms{s}) {
         $self->{interp} = 'bilinear';
         $self->force_redraw; $self->redraw;

      } elsif ($key == $Gtk2::Gdk::Keysyms{S}) {
         $self->{interp} = 'hyper';
         $self->force_redraw; $self->redraw;

      } elsif ($key == $Gtk2::Gdk::Keysyms{t}) {
         $self->set_subimage (Gtk2::CV::rotate $self->{subimage}, 270);
         $self->{tran_rotate} += 90;

      } elsif ($key == $Gtk2::Gdk::Keysyms{T}) {
         $self->set_subimage (Gtk2::CV::rotate $self->{subimage},  90);
         $self->{tran_rotate} -= 90;

      } elsif ($key == $Gtk2::Gdk::Keysyms{a}) {
         $self->{path}
            or die "can only 'a'pply disk-based images";

         $self->{type} eq "image/jpeg"
            or die "image has type '$self->{type}', but I can only 'a'pply jpeg images";
         
         my $rot = $self->{tran_rotate} %= 360;

         $rot = $rot ==   0 ? undef
              : $rot ==  90 ? -9
              : $rot == 180 ? -1
              : $rot == 270 ? -2
              : die "can only rotate by 0, 90, 180 and 270 degrees";

         if ($rot) {
            system "exiftran", "-i", $rot, $self->{path}
               and die "exiftran failed: $?";
         }

      } elsif ($key == $Gtk2::Gdk::Keysyms{Escape}
               && $self->{drag_info}) {
         # cancel a crop
         $self->draw_drag_rect;

         delete $self->{drag_info};

      # extra mplayer controls
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Right}) {
         print {$self->{mplayer_fh}} "seek +10\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Left}) {
         print {$self->{mplayer_fh}} "seek -10\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Up}) {
         print {$self->{mplayer_fh}} "seek +60\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Down}) {
         print {$self->{mplayer_fh}} "seek -60\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Page_Up}) {
         print {$self->{mplayer_fh}} "seek +600\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Page_Down}) {
         print {$self->{mplayer_fh}} "seek -600\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{o}) {
         print {$self->{mplayer_fh}} "osd\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{p}) {
         print {$self->{mplayer_fh}} "pause\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Escape}) {
         print {$self->{mplayer_fh}} "quit\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{9}) {
         print {$self->{mplayer_fh}} "volume -1\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{0}) {
         print {$self->{mplayer_fh}} "volume 1\n";
#      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{f}) {
#         print {$self->{mplayer_fh}} "vo_fullscreen\n";

      } else {

         return 0;
      }
   }

   1
}

sub schedule_redraw {
   my ($self) = @_;

   $self->{window}->process_updates (1);
   $self->{window}->get_screen->get_display->sync;
   Gtk2->main_iteration while Gtk2->events_pending;

   $self->redraw;
}

sub force_redraw {
   my ($self) = @_;

   $self->{dw_} = -1;
}

sub redraw {
   my ($self) = @_;

   return unless $self->{window} && $self->{window}->is_visible;

   # delay resizing iff we expect the wm to set frame extents later
   return if !$self->{frame_extents}
             && Gtk2::CV::gdk_net_wm_supports $self->{frame_extents_property};

   # delay if redraw pending
   return if $self->{refresh};

   # skip if no work to do
   return if $self->{dw_} == $self->{dw}
          && $self->{dh_} == $self->{dh};

   $self->{window}->set_back_pixmap (undef, 0);

   ($self->{dw_}, $self->{dh_}) = ($self->{dw}, $self->{dh});

   my $pb = $self->{subimage}
      or return;

   my $pm = new Gtk2::Gdk::Pixmap $self->{window}, $self->{dw}, $self->{dh}, -1;

   if ($self->{iw} != $self->{dw} or $self->{ih} != $self->{dh}) {
      $self->{sx} = $self->{dw} / $self->{iw};
      $self->{sy} = $self->{dh} / $self->{ih};
      $pb = new Gtk2::Gdk::Pixbuf 'rgb', $pb->get_has_alpha, 8, $self->{dw}, $self->{dh};
      $self->{subimage}->scale ($pb, 0, 0, $self->{dw}, $self->{dh},
                                0, 0,
                                $self->{sx}, $self->{sy},
                                $self->{interp});
   } else {
      $self->{sx} =
      $self->{sy} = 1;
   }

   $pm->draw_pixbuf ($self->style->white_gc,
                     Gtk2::CV::dealpha $pb,
                     0, 0, 0, 0, $self->{dw}, $self->{dh},
                     "max", 0, 0);

   $self->{window}->set_back_pixmap ($pm);
   $self->{window}->clear_area (0, 0, $self->{dw}, $self->{dh});

   $self->draw_drag_rect;

   $self->{window}->process_updates (1);
   $self->{window}->get_screen->get_display->sync;
}

=back

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=cut

1

