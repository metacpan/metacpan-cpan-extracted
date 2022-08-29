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

use JSON::XS ();

my $title_image;

# should go to utility module
sub dir_is_movie($) {
   -f "$_[0]/VIDEO_TS/VIDEO_TS.IFO"		and return "dvd";
   -d "$_[0]/BDMV/STREAM/."			and return "br";

   undef
}

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
   $self->{maxpect} = 1;

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

      if ($self->{mpv_fh}) {
         local $SIG{PIPE} = 'IGNORE';
         print {$self->{mpv_fh}} "quit\n";
         delete $self->{mpv_fh};
      } else {
         kill INT  => $self->{player_pid};
         kill TERM => $self->{player_pid};
      }
      waitpid delete $self->{player_pid}, 0;
      (delete $self->{mpv_box})->destroy if $self->{mpv_box};
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
   $self->{path}        = undef;
   $self->{tran_rotate} = $self->{load_rotate};

   $image =  Gtk2::CV::rotate $image, -$self->{load_rotate}
      if $self->{load_rotate};

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

Tries to load the given file (if it is an image), or embeds mpv (if
mpv supports it).

=cut

my %othertypes = (
   "Microsoft ASF"  => "video/x-asf",
   "RealMedia file" => "video/x-rm",
   "Matroska data"  => "video/x-ogg",
   "Ogg data, OGM video (XviD)" => "video/x-ogg",
   "Ogg data, OGM video (DivX 5)" => "video/x-ogg",
   "RIFF (little-endian) data, wrapped MPEG-1 (CDXA)" => "video/mpeg",
   "ISO Media"      => "video/x-mp4",
   "MPEG transport stream data" => "video/mpeg",
);

my %exttypes = (
   mp2  => "audio/mpeg",
   mp3  => "audio/mpeg",
   flac => "audio/x-flac",
   ogg  => "audio/x-ogg",
   mpc  => "audio/x-monkeyaudio",
   mpg  => "video/mpeg",
   mpeg => "video/mpeg",
   ogm  => "video/x-ogg",
   mkv  => "video/x-matroska",
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

   my ($image, $type);

   eval {#d#
      $self->kill_player;
      $self->force_redraw;

      my $moviedir = dir_is_movie $path;

      # magic/file is no longer very reliable
      if (open my $fh, "<:raw", $path) {
         if (sysread $fh, my $buf, 1024) { # 64 for everybody, except gif, which needs ~1kb
            unless (defined ($type = Gtk2::CV::filetype $buf)) {
               if ($buf =~ /^....ftypavif/) {
                  $type = "image/avif";
               } elsif ($buf =~ /^\x00+\z/) { # possibly iso9660 or udf
                  $type = "video/iso-bluray"; #d# just more commno for me nowadays
               }
               #elsif ($buf =~ /^\xff\xd8\xff\xe0\x00.JFIF\x00\x01[\x00\x01\x02]/) { $type = "image/jpeg"; # not the only possible format
            }
         }
      }

      $type ||= Gtk2::CV::magic_mime $path;

      if ($type =~ /^application\//) {
         my $magic = Gtk2::CV::magic $path;
         $type = $othertypes{$magic}
            if exists $othertypes{$magic};

         if ($type =~ /^application\//) {
            my $ffmpeg = qx{ffprobe -v quiet -show_format -of json -- \Q$path};

            # ffmpeg doesn't properly encode json
            $ffmpeg = eval { JSON::XS->new->latin1->decode ($ffmpeg) };

            if ($ffmpeg->{format}{format_name} =~ /^image/) {
               $type = "image/ffmpeg-$ffmpeg->{format}{format_name}";
            } elsif (length $ffmpeg->{format}{format_name}) {
               $type = "video/ffmpeg-$ffmpeg->{format}{format_name}";
            }
         }
      }

      if ((!$type or $type =~ /^application\/octet-stream/) && $path =~ /\.([^.]+)$/) {
         $type = $exttypes{lc $1};
      }

      $type =~ s/;.*//; # remove ; charset= etc.

      $@ = "generic file display error";

      if (!$type or $type =~ /^text\//) {
         $@ = "unrecognised file format";
         # should, but can't

      } elsif ($type eq "image/jpeg") {
         $image = Gtk2::CV::load_jpeg $path;

      } elsif ($type eq "image/jxl") {
         $image = Gtk2::CV::load_jxl $path;

      } elsif ($type eq "image/webp") {
         $image = Gtk2::CV::load_webp $path;

      } elsif ($type eq "image/jp2") { # jpeg2000 hack
         open my $pnm, "-|:raw", "jasper", "--input", $path, "--output-format", "pnm"
            or die "error running jasper (jpeg2000): $!";
         my $loader = new_with_type Gtk2::Gdk::PixbufLoader "pnm";
         local $/; $loader->write (<$pnm>);
         $loader->close;
         $image = $loader->get_pixbuf;

      } elsif ($type eq "application/pdf") {
         # hack, sorry, unsupported, should use mimetools etc.
         system "mupdf \Q$path\E &";

      } elsif ($type =~ /^image\//) {
         open my $fh, "<", $path
            or die "$path: $!";

         # avif fails autodetection
         my $loader =
            $type eq "image/avif"
               ? new_with_type Gtk2::Gdk::PixbufLoader "heif/avif"
               : new           Gtk2::Gdk::PixbufLoader;

         local $/; $loader->write (<$fh>);
         $loader->close;
         $image = $loader->get_pixbuf;

      } elsif (0 && $type =~ /^(audio\/|application\/ogg$)/) {
         if (1 || exists $ENV{CV_AUDIO_PLAYER}) {
            $self->{player_pid} = fork;

            if ($self->{player_pid} == 0) {
#            open STDIN , "</dev/null";
#            open STDOUT, ">/dev/null";
#            open STDERR, ">&2";

               my $player = $ENV{CV_AUDIO_PLAYER} || $Gtk2::CV::MPV;
               $path = "./$path" if $path =~ /^-/;
               exec "$player \Q$path";
               POSIX::_exit 0;
            }
         } else {
            $image = $self->gstreamer_setup ($path);
         }

      } elsif ($type =~ /^(?:video|application)\// || $moviedir || $type =~ /^(audio\/|application\/ogg$)/) {
         $path = "./$path" if $path =~ /^-/;

         # try video
#         our $EXECER;
#         $EXECER ||= AnyEvent::Fork
#            ->new
#            ->eval ('
#               $ENV{LC_ALL} = "C";
#               open STDIN , "</dev/null";
#               sub run {
#                  my ($fh, $path) = @_;
#                  open STDOUT, ">&" . fileno $fh or die;
#                  open STDERR, ">&1" or die;
#                  exec qw(mplayer2 -sub /dev/null -sub-fuzziness 0 -cache-min 0 -input nodefault-bindings:conf=/dev/null -identify -vo null -ao null -frames 0), $path;
#                  POSIX::_exit 0;
#               }
#            ');
#
#         pipe my $pr, my $pw
#            or die "pipe: $!";
#
#         $EXECER->fork->send_fh ($pw)->send_arg ($path)->run ("run");

         my ($w, $h);

         {
            no integer;

            my $ffmpeg_protocol = $type eq "video/iso-bluray" ? "bluray" : "file";

            # use ffmpeg's ffprobe to detect the video
            # TODO: should just load it into mpv and use that
            my $ffmpeg = qx{ffprobe -v quiet -show_streams -of json -- $ffmpeg_protocol:\Q$path};

            # ffmpeg doesn't properly encode json
            $ffmpeg = eval { JSON::XS->new->latin1->decode ($ffmpeg) };

            for (@{ $ffmpeg->{streams} }) {
               if ($_->{codec_type} eq "video" && !$_->{disposition}{attached_pic}) {
                  $w = $_->{width};
                  $h = $_->{height};

                  # apply display matrix rotation side data
                  if (my ($dm) = grep $_->{side_data_type} eq "Display Matrix", @{ $_->{side_data_list} }) {
                     if ((int $dm->{rotation} / 90) & 1) {
                        ($w, $h) = ($h, $w);
                     }
                  }

                  if ($_->{sample_aspect_ratio} =~ /^(\d+):(\d+)$/ && $1 && $2) {
                     $w = POSIX::ceil $w * ($1 / $2);
                  }

                  if ($_->{display_aspect_ratio} =~ /^(\d+):(\d+)$/ && $1 && $2) {
                     $w = POSIX::ceil $h * ($1 / $2);
                  }

                  last;
               }
            }

            # hack/TODO, ffmpeg does not support dvds
            if ($moviedir && !$w) {
               ($w, $h) = (1280, 720);
            }
         }

         my @extra_mpv_args;
         unless ($w && $h) {
            # assume audio visualisation
            $w = 592;
            $h = 333;
            push @extra_mpv_args,
               "--force-window",

               # visualisers by Muhammad Faiz (https://sourceforge.net/p/smplayer/feature-requests/638/)
               # showcqt
               "--lavfi-complex=[aid1] asplit [ao], afifo, showcqt=fps=60:size=1600x900:count=2:bar_g=2:sono_g=4:sono_v=9:fontcolor='st(0, (midi(f)-53.5)/12); st(1, 0.5 - 0.5 * cos(PI*ld(0))); r(1-ld(1)) + b(ld(1))':tc=0.33:tlength='st(0,0.17); 384*tc / (384 / ld(0) + tc*f /(1-ld(0))) + 384*tc / (tc*f / ld(0) + 384 /(1-ld(0)))', format=yuv420p [vo]",
               # showspectrum
               #"--lavfi-complex=[aid1] asplit [ao], afifo, showspectrum=s=1366x256:orientation=horizontal:win_func=nuttall, scale=1366:768, setsar=1/1 [vo]",
            ;
         }

         if ($w && $h) {
            $image = new Gtk2::Gdk::Pixbuf "rgb", 0, 8, $w, $h;
            $image->fill ("\0\0\0");

            # d'oh, we need to do that because realize() doesn't reliably cause
            # the window to have the correct size
            $self->show;

            # add a couple of windows just for mpv's sake
            my $box = $self->{mpv_box} = new Gtk2::EventBox;
            $box->set_above_child (1);
            $box->set_visible_window (0);
            $box->set_events ([]);
            $box->can_focus (0);

            my $window = new Gtk2::DrawingArea;
            $box->add ($window);
            $self->add ($box);
            $box->show_all;
            $window->realize;

            $self->{mpv_window} = $window;

            my $xid = $window->window->get_xid;

            socketpair my $sfh, my $mfh, Socket::AF_UNIX (), Socket::SOCK_STREAM (), 0;
            $self->{mpv_fh} = $mfh;
            $mfh->autoflush (1);
            fcntl $mfh, Fcntl::F_SETFD (), Fcntl::FD_CLOEXEC ();
            fcntl $mfh, Fcntl::F_SETFL (), Fcntl::O_NONBLOCK ();

            $self->{player_pid} = fork;

            if ($self->{player_pid} == 0) {
               $ENV{LC_ALL} = "POSIX";

               my @rotate = (
                  [],
                  ["--video-rotate=90"],
                  ["--video-rotate=180"],
                  ["--video-rotate=270"],
                  # mplayer needs this:
                  #[],
                  #["-vf-add", "rotate=0"],
                  #["-vf-add", "flip", "-vf-add", "mirror"],
                  #["-vf-add", "rotate=2"],
               );

               my @mpv_args;

               @mpv_args = (
                  qw(
                     --really-quiet
                     --no-terminal --no-input-terminal --no-input-default-bindings
                     --no-input-cursor --input-conf=/dev/null
                     --sub-auto=all
                     --autoload-files=yes
                     --input-vo-keyboard=no --loop-file=inf
                  ),

                  @{ $rotate[$self->{load_rotate} / 90] },
               );

               if ($type eq "video/gif") {
                  push @mpv_args, "--autoload-files=no";
               }

               push @mpv_args, @extra_mpv_args;

               $Gtk2::CV::mpv_list_options //= qx<$Gtk2::CV::MPV --list-options>;

               if ($Gtk2::CV::mpv_list_options =~ /\s--input-ipc-client\s/m) {
                  push @mpv_args, "--input-ipc-client=fd://" . fileno $sfh;
               } else {
                  # we always assume --input-file, as list-options doesn't list it even if it is there
                  push @mpv_args, "--input-file=fd://" . fileno $sfh;
               }

               #open STDERR, ">/dev/null";

               my @movie_args = ("--", $path);

               if ($moviedir) {
                  if ($moviedir eq "br") {
                     @movie_args = ("--bluray-device=$path", "bd://");
                  } elsif ($moviedir eq "dvd") {
                     @movie_args = ("--dvd-device=$path", "dvd://");
                  }
               } elsif ($type eq "video/iso-bluray") {
                  @movie_args = ("--bluray-device=$path", "bd://");
               }

               open STDIN, "</dev/null";
               open STDOUT, ">/dev/null";
               fcntl $sfh, Fcntl::F_SETFD (), 0;

               exec $Gtk2::CV::MPV, @mpv_args, -wid => $xid, @movie_args;
               POSIX::_exit 0;
            }

            close $sfh;

            print $mfh "enable_events all\n";
            print $mfh "get_file_name\n";

            my $input;
            add_watch Glib::IO fileno $mfh, in => sub {
               my $len = sysread $mfh, $input, 128, length $input;

               if ($len > 0) {
                  while ($input =~ s/^(.*)\n//) {
                     my $line = $1;

                     if ($line =~ /^\{/) {
                        $line = eval { JSON::XS::decode_json $line };

                        if ($line->{event} eq "video-reconfig") {
                           $self->update_mpv_window;
                        }
                     }
                  }
               } elsif (defined $len or $! != Errno::EAGAIN) {
                  return 0;
               }

               1
            };
         } else {
            $@ = "mpv doesn't recognize this '$type' file";
            # probably audio, or a real error
         }

      } else {
         $@ = "unrecognized file format '$type'";
      }
   };#d#
   warn "$@" if $@;#d#

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
   $self->{drag_gc}->set_rgb_foreground (new Gtk2::Gdk::Color 0xffff, 0xffff, 0xffff);
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

sub update_mpv_window {
   my ($self) = @_;

   # force a resize of the mpv window, otherwise it doesn't receive
   # a configureevent :/
   $self->{mpv_window}->window->resize (1, 1),
   $self->{mpv_window}->window->resize ($self->{w}, $self->{h})
      if $self->{mpv_window}
         && $self->{mpv_window}->window;
}

sub do_configure {
   my ($self, $event) = @_;

   my $window = $self->window;

   my ($sw, $sh) = ($self->{sw}, $self->{sh});

   my ($x, $y) = ($event->x    , $event->y     );
   my ($w, $h) = ($event->width, $event->height);

   $self->{w} = $w;
   $self->{h} = $h;

   $self->update_mpv_window;

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

   local $SIG{PIPE} = 'IGNORE'; # for mpv_fh

   my $volume = "add ao-volume %s2";

   $state *= Gtk2::Accelerator->get_default_mod_mask;

   $state -= ["shift-mask"];

   if ($state == ["control-mask"]) {
      if ($key == $Gtk2::Gdk::Keysyms{p} || $key == $Gtk2::Gdk::Keysyms{P}) {
         new Gtk2::CV::PrintDialog
            pixbuf => $self->{subimage},
            aspect => $self->{dw} / $self->{dh},
            autook => $key == $Gtk2::Gdk::Keysyms{P}
         ;

      } elsif ($key == $Gtk2::Gdk::Keysyms{m}) {
         $self->{maxpect} = !$self->{maxpect};
         $self->auto_resize;

      } elsif ($key == $Gtk2::Gdk::Keysyms{M}) {
         if ($self->{rsw} == $self->{sw} && $self->{rsh} == $self->{sh}) {
            ($self->{sw}, $self->{sh}) = ($self->{dw},  $self->{dh});
         } else {
            ($self->{sw}, $self->{sh}) = ($self->{rsw}, $self->{rsh});
         }

      } elsif ($key == $Gtk2::Gdk::Keysyms{T}) {
         $self->{load_rotate} = $self->{tran_rotate};

      } elsif ($key == $Gtk2::Gdk::Keysyms{e}) {
         if (fork == 0) {
            exec $ENV{CV_EDITOR} || "gimp", $self->{path};
            exit;
         }

      } else {
         return 0;
      }

   } elsif ($state == []) {
      if ($key == $Gtk2::Gdk::Keysyms{less}) {
         $self->resize ($self->{dw} * 0.5, $self->{dh} * 0.5);

      } elsif ($key == $Gtk2::Gdk::Keysyms{greater}) {
         $self->resize ($self->{dw} * 2, $self->{dh} * 2);

      } elsif ($key == $Gtk2::Gdk::Keysyms{comma}) {
         $self->resize ($self->{dw} / 1.1 + 0.5, $self->{dh} / 1.1 + 0.5);

      } elsif ($key == $Gtk2::Gdk::Keysyms{period}) {
         $self->resize ($self->{dw} * 1.1      , $self->{dh} * 1.1);

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

      } elsif ($key == $Gtk2::Gdk::Keysyms{t}) {
         my $r = $::REVERSE_ROTATION ? +90 : -90;
         $self->set_subimage (Gtk2::CV::rotate $self->{subimage}, $r);
         ($self->{tran_rotate} += 360 - $r) %= 360;
         printf {$self->{mpv_fh}} "set video-rotate %d\n", $self->{tran_rotate}
            if $self->{mpv_fh};

      } elsif ($key == $Gtk2::Gdk::Keysyms{T}) {
         my $r = $::REVERSE_ROTATION ? -90 : +90;
         $self->set_subimage (Gtk2::CV::rotate $self->{subimage}, $r);
         ($self->{tran_rotate} += 360 - $r) %= 360;
         printf {$self->{mpv_fh}} "set video-rotate %d\n", $self->{tran_rotate}
            if $self->{mpv_fh};

      } elsif ($key == $Gtk2::Gdk::Keysyms{a}) {
         $self->{path}
            or die "can only 'a'pply disk-based images";

         $self->{type} eq "image/jpeg"
            or die "image has type '$self->{type}', but I can only 'a'pply jpeg images";
         
         my $rot = $self->{tran_rotate};

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

      # extra mpv controls
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Right}) {
         print {$self->{mpv_fh}} "seek +10\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Left}) {
         print {$self->{mpv_fh}} "seek -10\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Up}) {
         print {$self->{mpv_fh}} "seek +60\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Down}) {
         print {$self->{mpv_fh}} "seek -60\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Page_Up}) {
         print {$self->{mpv_fh}} "seek +600\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Page_Down}) {
         print {$self->{mpv_fh}} "seek -600\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{numbersign}) {
         print {$self->{mpv_fh}} "cycle audio\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{j}) {
         print {$self->{mpv_fh}} "cycle sub\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{o}) {
         print {$self->{mpv_fh}} "no-osd cycle-values osd-level 2 3 0 1\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{p}) {
         print {$self->{mpv_fh}} "cycle pause\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{Escape}) {
         print {$self->{mpv_fh}} "quit\n";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{9}) {
         printf {$self->{mpv_fh}} "$volume\n", "-";
      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{0}) {
         printf {$self->{mpv_fh}} "$volume\n", "+";
#      } elsif ($self->{player_pid} && $key == $Gtk2::Gdk::Keysyms{f}) {
#         print {$self->{mpv_fh}} "vo_fullscreen\n";

      } else {

         return 0;
      }
   } else {
      return 0;
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

