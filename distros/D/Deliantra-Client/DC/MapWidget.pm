package DC::MapWidget;

use common::sense;

use List::Util qw(min max);

use DC;
use DC::OpenGL;
use DC::UI;
use DC::Macro;

our @ISA = DC::UI::Base::;

our @TEX_HIDDEN = map {
   new_from_resource DC::Texture # MUST be POT
        "hidden-$_.png", mipmap => 1, wrap => 1
   } 0, 1, 2;

my $magicmap_tex =
      new_from_resource DC::Texture "magicmap.png",
         mipmap => 1, wrap => 0, internalformat => GL_ALPHA;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      z         => -1,
      can_focus => 1,
      tilesize  => 32,
      @_
   );

   $self
}

sub add_command {
   my ($self, $command, $tooltip, $widget, $cb) = @_;

   (my $data = $command) =~ s/\\//g;

   $tooltip =~ s/^\s+//;
   $tooltip = "<big>$data</big>\n\n$tooltip";
   $tooltip =~ s/\s+$//;

   $::COMPLETER->{command}{$command} = [$data, $tooltip, $widget, $cb, ++$self->{command_id}];
}

sub clr_commands {
   my ($self) = @_;

   %{$::COMPLETER->{command}} = ();

   $::COMPLETER->hide
      if $::COMPLETER;
}

sub server_login {
   my ($server) = @_;

   ::stop_game ();
   local $::PROFILE->{host} = $server;
   ::start_game ();
}

sub editor_invoke {
   my $editsup = $::CONN && $::CONN->{editor_support}
      or return;

   DC::background {
      print "preparing editor startup...\n";

      my $server = $editsup->{gameserver} || "default";
      $server =~ s/([^a-zA-Z0-9_\-])/sprintf "=%x=", ord $1/ge;

      local $ENV{CROSSFIRE_MAPDIR} = my $mapdir = "$Deliantra::VARDIR/map.$server"; mkdir $mapdir;
      local $ENV{CROSSFIRE_LIBDIR} = my $libdir = "$Deliantra::VARDIR/lib.$server"; mkdir $libdir;

      print "map directory is $mapdir\n";
      print "lib directory is $libdir\n";

      my $ua = DC::lwp_useragent;

      for my $file (qw(archetypes crossfire.0)) {
         my $url = "$editsup->{lib_root}$file";
         print "mirroring $url...\n";
         DC::lwp_check $ua->mirror ($url, "$libdir/$file");
         printf "%s size %d octets\n", $file, -s "$libdir/$file";
      }

      if (1) { # upload a map
         my $mapname = $::CONN->{map_info}[0];

         my $mappath = "$mapdir/$mapname";

         -e $mappath and die "$mappath already exists\n";

         print "getting map revision for $mapname...\n";

         # try to get the most recent head revision, what a hack,
         # this should have been returned while downloading *sigh*
         my $log = (DC::lwp_check $ua->get ("$editsup->{cvs_root}/$mapname?view=log&logsort=rev"))->decoded_content;

         if ($log =~ /\?rev=(\d+\.\d+)"/) {
            my $rev = $1;

            print "downloading revision $rev...\n";

            my $map = (DC::lwp_check $ua->get ("$editsup->{cvs_root}/$mapname?rev=$rev"))->decoded_content;

            my $meta = {
               %$editsup,
               path     => $mapname,
               revision => $rev,
               cf_login => $::PROFILE->{user},
            };

            require File::Basename;
            require File::Path;

            File::Path::mkpath (File::Basename::dirname ($mappath));
            open my $fh, ">:raw:perlio", "$mappath.meta"
               or die "$mappath.meta: $!\n";
            print $fh DC::encode_json $meta;
            close $fh;
            open my $fh, ">:raw:perlio:utf8", $mappath
               or die "$mappath: $!\n";
            print $fh $map;
            close $fh;

            print "saved as $mappath\n";

            print "invoking editor...\n";
            exec "/root/s2/gce $mappath";#d#

            # now upload it
#           require HTTP::Request::Common;
#
#           my $res = $ua->post (
#              $ENV{CFPLUS_UPLOAD},
#              Content_Type => 'multipart/form-data',
#              Content      => [
#                 path        => $mapname,
#                 mapdir      => $ENV{CROSSFIRE_MAPDIR},
#                 map         => $map,
#                 revision    => $rev,
#                 cf_login    => $ENV{CFPLUS_LOGIN},
#                 cf_password => $ENV{CFPLUS_PASSWORD},
#                 comment     => "",
#              ]
#           );
#
#           if ($res->is_error) {
#              # fatal condition
#              warn $res->status_line;
#           } else {
#              # script replies are marked as {{..}}
#              my @msgs = $res->decoded_content =~ m/\{\{(.*?)\}\}/g;
#              warn map "$_\n", @msgs;
#           }
         } else {
            die "viewvc parse error, unable to detect revision\n";
         }
      }
   }
}

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   if ($ev->{button} == 1) {
      $self->grab_focus;
      return unless $::CONN && $self->{ctilesize};

      my $x = $self->{dx} + DC::floor +($ev->{x} - $self->{sx0}) / $self->{ctilesize};
      my $y = $self->{dy} + DC::floor +($ev->{y} - $self->{sy0}) / $self->{ctilesize};

      $x -= DC::floor $::MAP->w * 0.5;
      $y -= DC::floor $::MAP->h * 0.5;

      if ($::CONN) {
         $::CONN->lookat ($x, $y)
      }

   } elsif ($ev->{button} == 2) {
      $self->grab_focus;
      return unless $::CONN;
      
      my ($ox, $oy) = ($ev->{x}, $ev->{y});
      my ($bw, $bh) = ($::CFG->{map_shift_x}, $::CFG->{map_shift_y});

      $self->{motion} = sub {
         my ($ev, $x, $y) = @_;

         ($x, $y) = ($ev->{x}, $ev->{y});

         $::CFG->{map_shift_x} = $bw + $x - $ox;
         $::CFG->{map_shift_y} = $bh + $y - $oy;

         $self->update;
      };
   } elsif ($ev->{button} == 3) {
      my @items = (
            ["Help Browser…\tF1", sub { $::HELP_WINDOW->toggle_visibility }],
            ["Statistics\tF2",    sub { ::toggle_player_page ($::STATS_PAGE) }],
            ["Skills\tF3",        sub { ::toggle_player_page ($::SKILL_PAGE) }],
            ["Spells…\tF4",       sub { ::toggle_player_page ($::SPELL_PAGE) }],
            ["Inventory…\tF5",    sub { ::toggle_player_page ($::INVENTORY_PAGE) }],
            ["Setup… \tF9",       sub { $::SETUP_DIALOG->toggle_visibility }],
#            ["Server Messages…",  sub { $::MESSAGE_WINDOW->toggle_visibility }],
      );

      if ($::CONN && $::CONN->{editor_support}) {
#         push @items, [
#            "Edit this map <span size='xx-small'>(" . (DC::asxml $::CONN->{map_info}[0]) . ")</span>",
#            \&editor_invoke,
#         ];

         for my $type (@{ $::CONN->{editor_support}{servertypes} }) {
            $::CONN->{editor_support}{servertype} ne $type
               or next;
            my $server = $::CONN->{editor_support}{"${type}server"}
               or next;

            push @items, [
               "Login on $type server <span size='xx-small'>(" . (DC::asxml $server) . ")</span>",
               sub { server_login $server },
            ];
         }
      }

      push @items,
         ["Quit",
            sub {
               if ($::CONN) {
                  &::open_quit_dialog;
               } else {
                  exit;
               }
            }
         ],
      ;

      (new DC::UI::Menu
         items => \@items,
      )->popup ($ev);
   }

   1
}

sub invoke_button_up {
   my ($self, $ev, $x, $y) = @_;

   delete $self->{motion};

   1
}

sub invoke_mouse_motion {
   my ($self, $ev, $x, $y) = @_;

   if ($self->{motion}) {
      $self->{motion}->($ev, $x, $y);
   } else {
      return 0;
   }

   1
}

sub size_request {
   my ($self) = @_;

   (
      $self->{tilesize} * DC::ceil $::WIDTH  / $self->{tilesize},
      $self->{tilesize} * DC::ceil $::HEIGHT / $self->{tilesize},
   )
}

sub update {
   my ($self) = @_;

   $self->{need_update} = 1;
   $self->SUPER::update;
}

my %DIR = (
   ( "," . DC::SDLK_KP5      ), [0, "stay fire"],
   ( "," . DC::SDLK_KP8      ), [1, "north"],
   ( "," . DC::SDLK_KP9      ), [2, "northeast"],
   ( "," . DC::SDLK_KP6      ), [3, "east"],
   ( "," . DC::SDLK_KP3      ), [4, "southeast"],
   ( "," . DC::SDLK_KP2      ), [5, "south"],
   ( "," . DC::SDLK_KP1      ), [6, "southwest"],
   ( "," . DC::SDLK_KP4      ), [7, "west"],
   ( "," . DC::SDLK_KP7      ), [8, "northwest"],

   ( "," . DC::SDLK_PAGEUP   ), [2, "northeast"],
   ( "," . DC::SDLK_PAGEDOWN ), [4, "southeast"],
   ( "," . DC::SDLK_END      ), [6, "southwest"],
   ( "," . DC::SDLK_HOME     ), [8, "northwest"],

   ( "," . DC::SDLK_UP       ), [1, "north"],
   ("1," . DC::SDLK_UP       ), [2, "northeast"],
   ( "," . DC::SDLK_RIGHT    ), [3, "east"],
   ("1," . DC::SDLK_RIGHT    ), [4, "southeast"],
   ( "," . DC::SDLK_DOWN     ), [5, "south"],
   ("1," . DC::SDLK_DOWN     ), [6, "southwest"],
   ( "," . DC::SDLK_LEFT     ), [7, "west"],
   ("1," . DC::SDLK_LEFT     ), [8, "northwest"],
);

sub invoke_key_down {
   my ($self, $ev) = @_;

   my $mod = $ev->{mod};
   my $sym = $ev->{sym};
   my $uni = $ev->{unicode};

   $mod &= DC::KMOD_CTRL | DC::KMOD_ALT | DC::KMOD_META | DC::KMOD_SHIFT;

   # ignore repeated keypresses
   return if $self->{last_mod} == $mod && $self->{last_sym} == $sym;
   $self->{last_mod} = $mod;
   $self->{last_sym} = $sym;

   my $dir = $DIR{ (!!($mod & (DC::KMOD_ALT | DC::KMOD_META))) . ",$sym" };

   if ($::CONN && $dir) {
      if ($mod & DC::KMOD_SHIFT) {
         $self->{shft}++;
         if ($dir->[0] != $self->{fire_dir}) {
            $::CONN->user_send ("fire $dir->[0]");
         }
         $self->{fire_dir} = $dir->[0];
      } elsif ($mod & DC::KMOD_CTRL) {
         $self->{ctrl}++;
         $::CONN->user_send ("run $dir->[0]");
      } else {
         $::CONN->user_send ("$dir->[1]");
      }

      return 1;
   }

   0
}

sub invoke_key_up {
   my ($self, $ev) = @_;

   my $res = 0;
   my $mod = $ev->{mod};
   my $sym = $ev->{sym};

   delete $self->{last_mod};
   delete $self->{last_sym};

   if ($::CFG->{shift_fire_stop}) {
      if (!($mod & DC::KMOD_SHIFT) && delete $self->{shft}) {
         $::CONN->user_send ("fire_stop");
         delete $self->{fire_dir};
         $res = 1;
      }
   } else {
      my $dir = $DIR{ (!!($mod & (DC::KMOD_ALT | DC::KMOD_META))) . ",$sym" };

      if ($dir && delete $self->{shft}) {
         $::CONN->user_send ("fire_stop");
         delete $self->{fire_dir};
         $res = 1;
      } elsif (($sym == DC::SDLK_LSHIFT || $sym == DC::SDLK_RSHIFT)
               && delete $self->{shft}) { # XXX: is RSHIFT ok?
         $::CONN->user_send ("fire_stop");
         delete $self->{fire_dir};
         $res = 1;
      }
   }

   if (!($mod & DC::KMOD_CTRL) && delete $self->{ctrl}) {
      $::CONN->user_send ("run_stop");
      $res = 1;
   }

   $res
}

sub invoke_visibility_change {
   my ($self) = @_;

   $self->refresh_hook;

   0
}

sub set_tilesize {
   my ($self, $tilesize) = @_;

   $self->{tilesize} = $tilesize;
}

sub scroll {
   my ($self, $dx, $dy) = @_;

   $self->movement_update;

   $self->{sdx} += $dx * $self->{tilesize}; # smooth displacement
   $self->{sdy} += $dy * $self->{tilesize};

   # save old fow texture, if applicable
   $self->{prev_fow_texture} = $::CFG->{smooth_transitions} && $self->{fow_texture};
   $self->{lfdx} = $dx;
   $self->{lfdy} = $dy;
   $self->{lmdx} = $self->{dx};
   $self->{lmdy} = $self->{dy};

   $::MAP->scroll ($dx, $dy);
}

sub set_magicmap {
   my ($self, $w, $h, $x, $y, $data) = @_;

   $x -= $::MAP->ox + 1 + int 0.5 * $::MAP->w;
   $y -= $::MAP->oy + 1 + int 0.5 * $::MAP->h;

   $self->{magicmap} = [$x, $y, $w, $h, $data];

   $self->update;
}

sub movement_update {
   my ($self) = @_;

   if ($::CFG->{smooth_movement}) {
      if ($self->{sdx} || $self->{sdy}) {
         my $diff = EV::time - ($self->{last_update} || $::LAST_REFRESH);
         my $spd  = $::CONN->{stat}{DC::Protocol::CS_STAT_SPEED};

         # the minimum time for a single tile movement
         my $mintime = DC::Protocol::TICK * DC::ceil 1 / ($spd * DC::Protocol::TICK || 1);

         $spd *= $self->{tilesize};

         # jump if "impossibly high" speed
         if (
            (max abs $self->{sdx}, abs $self->{sdy})
            > $spd * $mintime * 2.1
         ) {
            #warn "jump ", (max abs $self->{sdx}, abs $self->{sdy}), " ", $spd * $mintime * 2.1;#d#
            $self->{sdx} = $self->{sdy} = 0;
         } else {
            $spd *= $diff * 1.0001; # 1.0001 so that we don't accumulate rounding errors the wrong direction

            my $dx = $self->{sdx} < 0 ? -$spd : $spd;
            my $dy = $self->{sdy} < 0 ? -$spd : $spd;

            if ($self->{sdx} * ($self->{sdx} - $dx) <= 0) { $self->{sdx} = 0 } else { $self->{sdx} -= $dx }
            if ($self->{sdy} * ($self->{sdy} - $dy) <= 0) { $self->{sdy} = 0 } else { $self->{sdy} -= $dy }
         }

         $self->update;
      }
   } else {
      $self->{sdx} = $self->{sdy} = 0;
   }

   $self->{last_update} = EV::time;
}

sub refresh_hook {
   my ($self) = @_;

   if ($::MAP && $::CONN) {
      if (delete $self->{need_update}) {
         $self->movement_update;

         my $tilesize = $self->{ctilesize} = (int $self->{tilesize} * $::CFG->{map_scale}) || 1;

         my $sdx_t = DC::ceil $self->{sdx} / $tilesize;
         my $sdy_t = DC::ceil $self->{sdy} / $tilesize;

         # width/height of map, in tiles
         my $sw = $self->{sw} = 2 + DC::ceil $self->{w} / $tilesize;
         my $sh = $self->{sh} = 2 + DC::ceil $self->{h} / $tilesize;

         # the map displacement, in tiles
         my $sx = DC::ceil $::CFG->{map_shift_x} / $tilesize + $sdx_t;
         my $sy = DC::ceil $::CFG->{map_shift_y} / $tilesize + $sdy_t;

         # the upper left "visible" corner, in pixels
         my $sx0 = $self->{sx0} = $::CFG->{map_shift_x} - $sx * $tilesize;
         my $sy0 = $self->{sy0} = $::CFG->{map_shift_y} - $sy * $tilesize;

         my $dx = $self->{dx} = DC::ceil 0.5 * ($::MAP->w - $sw) - $sx;
         my $dy = $self->{dy} = DC::ceil 0.5 * ($::MAP->h - $sh) - $sy;

         if ($::CFG->{fow_enable}) {
            # draw_fow_texture REQUIRES the fow texture to stay the same size.
            my ($w, $h, $data) = $::MAP->fow_texture ($dx, $dy, $sw, $sh);

            $self->{fow_texture} = new DC::Texture
               w              => $w,
               h              => $h,
               data           => $data,
               internalformat => GL_ALPHA,
               format         => GL_ALPHA;
         } else {
            delete $self->{fow_texture};
         }

         glNewList ($self->{list} ||= glGenList);

         glPushMatrix;
         glTranslate $sx0, $sy0;
         glScale $::CFG->{map_scale}, $::CFG->{map_scale};
         glTranslate DC::ceil $self->{sdx}, DC::ceil $self->{sdy};

         $::MAP->draw ($dx, $dy, $sw, $sh,
                       $self->{tilesize},
                       $::CONN->{player}{tag},
                       -$self->{sdx}, -$self->{sdy});

         glScale $self->{tilesize}, $self->{tilesize};

         if (my $tex = $self->{fow_texture}) {
            my @prev_fow_params;

            if ($DC::OpenGL::GL_MULTITEX && $self->{prev_fow_texture}) {
               my $d1 = DC::distance $self->{sdx}, $self->{sdy};
               my $d2 = (DC::distance $self->{lfdx}, $self->{lfdy}) * $tilesize;

               if ($d1 * $d2) {
                  @prev_fow_params = (
                     (min 1, $d1 / $d2),
                     $self->{lmdx} - $dx - $self->{lfdx},
                     $self->{lmdy} - $dy - $self->{lfdy},
                     @{$self->{prev_fow_texture}}{qw(name data)}
                  );
               }
            }

            DC::Texture::draw_fow_texture
               $::CFG->{fow_intensity},
               $TEX_HIDDEN[$::CFG->{fow_texture}]{name},
               @{$self->{fow_texture}}{qw(name data s t w h)},
               @prev_fow_params;
         }

         if ($self->{magicmap}) {
            my ($x, $y, $w, $h, $data) = @{ $self->{magicmap} };

            $x += $::MAP->ox + $self->{dx};
            $y += $::MAP->oy + $self->{dy};

            glTranslate - $x - 1, - $y - 1;
            glBindTexture GL_TEXTURE_2D, $magicmap_tex->{name};
            $::MAP->draw_magicmap ($w, $h, $data);
         }

         glPopMatrix;
         glEndList;
      }
   } else {
      delete $self->{last_fow_texture};
      delete $self->{fow_texture};

      glDeleteList delete $self->{list}
         if $self->{list};
   }
}

sub draw {
   my ($self) = @_;

   $self->{root}->on_post_alloc (prepare => sub { $self->refresh_hook });

   return unless $self->{list};

   my $focused = $DC::UI::FOCUS == $self
                 || $DC::UI::FOCUS == $::COMPLETER->{entry};

   return
      unless $focused || !$::FAST;

   glCallList $self->{list};

   # TNT2 emulates logops in software (or worse :)
   unless ($focused) {
      glColor_premultiply 0, 0, 1, 0.25;
      glEnable GL_BLEND;
      glBlendFunc GL_ONE, GL_ONE_MINUS_SRC_ALPHA;
      glBegin GL_QUADS;
      glVertex 0, 0;
      glVertex 0, $::HEIGHT;
      glVertex $::WIDTH, $::HEIGHT;
      glVertex $::WIDTH, 0;
      glEnd;
      glDisable GL_BLEND;
   }
}

sub DESTROY {
   my $self = shift;

   glDeleteList $self->{list};

   $self->SUPER::DESTROY;
}

package DC::MapWidget::MapMap;

use common::sense;

our @ISA = DC::UI::Base::;

use Time::HiRes qw(time);
use DC::OpenGL;

sub size_request {
   ($::HEIGHT * 0.2, $::HEIGHT * 0.2)
}

sub refresh_hook {
   my ($self) = @_;

   if ($::MAP && $self->{texture_atime} < time) {
      my ($w, $h) = @$self{qw(w h)};

      return unless $w && $h;

      my $sw = int $::WIDTH  / ($::MAPWIDGET->{tilesize} * $::CFG->{map_scale}) + 0.99;
      my $sh = int $::HEIGHT / ($::MAPWIDGET->{tilesize} * $::CFG->{map_scale}) + 0.99;

      my $ox = 0.5 * ($w - $sw);
      my $oy = 0.5 * ($h - $sh);

      my $sx = int $::CFG->{map_shift_x} / $::MAPWIDGET->{tilesize};
      my $sy = int $::CFG->{map_shift_y} / $::MAPWIDGET->{tilesize};

      #TODO: map scale is completely borked

      my $x0 = int $ox - $sx + 0.5;
      my $y0 = int $oy - $sy + 0.5;

      $self->{sw} = $sw;
      $self->{sh} = $sh;

      $self->{x0} = $x0;
      $self->{y0} = $y0;

      $self->{texture_atime} = time + 1/3;

      $self->{texture} =
         new DC::Texture
            w    => $w,
            h    => $h,
            data => $::MAP->mapmap (-$ox, -$oy, $w, $h),
            type => $DC::GL_VERSION >= 1.2 ? GL_UNSIGNED_INT_8_8_8_8_REV : GL_UNSIGNED_BYTE;
   }
}

sub invoke_visibility_change {
   my ($self) = @_;

   $self->refresh_hook;

   0
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   $self->update;

   1
}

sub update {
   my ($self) = @_;

   delete $self->{texture_atime};
   $self->SUPER::update;
}

sub _draw {
   my ($self) = @_;

   $self->{root}->on_post_alloc (texture => sub { $self->refresh_hook });

   $self->{texture} or return;

   glEnable GL_BLEND;
   glBlendFunc GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA;
   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;

   $self->{texture}->draw_quad (0, 0);

   glDisable GL_TEXTURE_2D;

   glTranslate 0.375, 0.375;

   glColor 1, 1, 0, 1;
   glBegin GL_LINE_LOOP;
   glVertex $self->{x0}              , $self->{y0}              ;
   glVertex $self->{x0}              , $self->{y0} + $self->{sh};
   glVertex $self->{x0} + $self->{sw}, $self->{y0} + $self->{sh};
   glVertex $self->{x0} + $self->{sw}, $self->{y0}              ;
   glEnd;
   
   glDisable GL_BLEND;
}

package DC::MapWidget::Command;

use common::sense;

use DC::OpenGL;

our @ISA = DC::UI::Frame::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      bg => [0, 0, 0, 0.8],
      @_,
   );

   $self->add ($self->{vbox} = new DC::UI::VBox);

   $self->{label} = [
      map
         DC::UI::Label->new (
            align         => 0,
            can_hover     => 1,
            can_events    => 1,
            tooltip_width => 0.33,
            fontsize      => $_,
         ), (0.8) x 16
   ];

   $self->{entry} = new DC::UI::Entry
      on_changed => sub {
         $self->update_labels;
         0
      },
      on_button_down => sub {
         my ($entry, $ev, $x, $y) = @_;

         if ($ev->{button} == 3) {
            (new DC::UI::Menu
               items => [
                  ["bind <i>" . (DC::asxml $self->{select}) . "</i> to a key"
                   => sub { DC::Macro::quick_macro [$self->{select}], sub { $entry->grab_focus } }]
               ],
            )->popup ($ev);
            return 1;
         }
         0
      },
      on_key_down => sub {
         my ($entry, $ev) = @_;

         my $self = $entry->{parent}{parent};

         if ($ev->{sym} == 13) {
            if (exists $self->{select}) {
               $self->{last_command} = $self->{select};
               $::CONN->user_send ($self->{select});

               unshift @{$self->{history}}, $self->{entry}->get_text;
               $self->{hist_ptr} = 0;

               $self->hide;
            }
         } elsif ($ev->{sym} == 27) {
            $self->{hist_ptr} = 0;
            $self->hide;
         } elsif ($ev->{sym} == DC::SDLK_DOWN) {
            if ($self->{hist_ptr} > 1) {
               $self->{hist_ptr}--;
               $self->{entry}->set_text ($self->{history}->[$self->{hist_ptr} - 1]);
            } elsif ($self->{hist_ptr} > 0) {
               $self->{hist_ptr}--;
               $self->{entry}->set_text ($self->{hist_saveback});
            } else {
               ++$self->{select_offset}
                  if $self->{select_offset} < $#{ $self->{last_match} || [] };
            }
            $self->update_labels;
         } elsif ($ev->{sym} == DC::SDLK_UP) {
            if ($self->{select_offset}) {
               --$self->{select_offset}
            } else {
               unless ($self->{hist_ptr}) {
                  $self->{hist_saveback} = $self->{entry}->get_text;
               }
               if ($self->{hist_ptr} <= $#{$self->{history}}) {
                  $self->{hist_ptr}++;
               }
               $self->{entry}->set_text ($self->{history}->[$self->{hist_ptr} - 1])
                  if exists $self->{history}->[$self->{hist_ptr} - 1];
            }
            $self->update_labels;
         } else {
            return 0;
         }

         1
      }
   ;

   $self->{vbox}->add (
      $self->{entry},
      @{$self->{label}},
   );

   $self
}

sub set_prefix {
   my ($self, $prefix) = @_;

   $self->{entry}->set_text ($prefix);
   $self->show;
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   $self->move_abs (($::WIDTH - $w) * 0.5, ($::HEIGHT - $h) * 0.6, 10);

   $self->SUPER::invoke_size_allocate ($w, $h)
}

sub show {
   my ($self) = @_;

   $self->SUPER::show;
   $self->{entry}->grab_focus;
}

sub hide {
   my ($self) = @_;

   $self->{hist_ptr} = 0;

   $self->SUPER::hide;
   $self->{entry}->set_text ("");
}

sub inject_key_down {
   my ($self, $ev) = @_;

   $self->{entry}->grab_focus;
   $self->{entry}->emit (key_down => $ev);
}

sub update_labels {
   my ($self) = @_;

   my $text = $self->{entry}->get_text;

   length $text
      or return $self->hide;

   if ($text ne $self->{last_search}) {
      my @match;

      if ($text =~ /^(.*?)\s+$/) {
         my ($cmd, $arg) = $text =~ /^\s*([^[:space:]]*)(.*)$/;
         @match = ([[$cmd,'(appended whitespace suppresses completion)'],$text]);
      } else {
         # @match is [command, penalty, command with arguments] until sort

         my ($cmd, $arg) = $text =~ /^\s*([^[:space:]]*)(.*)$/;

         my $regexp_abbrev = do {
            my ($beg, @chr) = split //, lc $cmd;

            # the following regex is used to match our "completion entry"
            # to an actual command - the parentheses match kind of "overhead"
            # - the more characters the parentheses match, the less attractive
            # is the match.
            my $regexp = "^\Q$beg\E"
                       . join "", map "(?:.*?[ \\\\]\Q$_\E|(.*?)\Q$_\E)", @chr;
            qr<$regexp>
         };

         my $regexp_partial = do {
            my $regexp = "^\Q$text\E(.*)";
            qr<$regexp>
         };

         for (keys %{$self->{command}}) {
            my @scores;

            # 1. Complete command [with args]
            #    command is a prefix of the text
            #    score is length of complete command matched
            #    e.g. "invoke summon pet monster bat"
            #         "invoke" "summon pet monster bat" = 6
            #         "invoke summon pet monster" "bat" = 25
            if ($text =~ /^\Q$_\E(.*)/) {
               push @scores, [$_, length $_, $text];
            }

            # 2. Partial command
            #    text is a prefix of the full command
            #    score is the length of the input text
            #    e.g. "invoke s"
            #         "invoke small fireball" = 8
            #         "invoke summon pet monster" = 8

            if ($_ =~ $regexp_partial) {
               push @scores, [$_, length $text, $_];
            }

            # 3. Abbreviation match
            #    attempts to use first word of text as an abbreviated command
            #    score is length of word + 1 - 3 per non-word-initial character

            if (my @penalty = $_ =~ $regexp_abbrev) {
               push @scores, [$_, (length $cmd) + 1 - (length join "", map "::$_", grep defined, @penalty), "$_$arg"];
            }

            # Pick the best option for this command
            push @match, (sort {
                             $b->[1] <=> $a->[1]
                          } @scores)[0];
         }

         # @match is now [command object, command with arguments]
         @match = map [$self->{command}{$_->[0]}, $_->[2]],
                     sort {
                        $b->[1] <=> $a->[1]
                           or $self->{command}{$a->[0]}[4] <=> $self->{command}{$b->[0]}[4]
                           or (length $b->[0]) <=> (length $a->[0])
                     } @match;
      }

      $self->{last_search} = $text;
      $self->{last_match} = \@match;

      $self->{select_offset} = 0;
   }

   my @labels = @{ $self->{label} };
   my @matches = @{ $self->{last_match} || [] };

   if ($self->{select_offset}) {
      splice @matches, 0, $self->{select_offset}, ();

      my $label = shift @labels;
      $label->set_text ("...");
      $label->set_tooltip ("Use Cursor-Up to view previous matches");
   }

   for my $label (@labels) {
      $label->{fg} = [1, 1, 1, 1];
      $label->{bg} = [0, 0, 0, 0];
   }

   if (@matches) {
      $self->{select} = "$matches[0][1]";

      $labels[0]->{fg} = [0, 0, 0, 1];
      $labels[0]->{bg} = [1, 1, 1, 0.8];
   } else {
      $self->{select} = "$text";
   }

   for my $match (@matches) {
      my $label = shift @labels;

      if (@labels) {
         $label->set_text ("$match->[1]");
         $label->set_tooltip ("$match->[0][1]");
      } else {
         $label->set_text ("...");
         $label->set_tooltip ("Use Cursor-Down to view more matches");
         last;
      }
   }

   for my $label (@labels) {
      $label->set_text ("");
      $label->set_tooltip ("");
   }

   $self->update;
}

sub _draw {
   my ($self) = @_;

   # hack
   local $DC::UI::FOCUS = $self->{entry};

   $self->SUPER::_draw;
}

1

