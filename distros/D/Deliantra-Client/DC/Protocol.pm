package DC::Protocol;

use common::sense;

use Guard ();

use Deliantra::Protocol::Constants;

use DC;
use DC::DB;
use DC::UI;
use DC::Pod;
use DC::Macro;
use DC::Item;

use base 'Deliantra::Protocol::Base';

our $TEX_DIALOGUE = new_from_resource DC::Texture
         "dialogue.png", minify => 1, mipmap => 1;

our $TEX_NOFACE = new_from_resource DC::Texture
        "noface.png", minify => 1, mipmap => 1, wrap => 1;

sub MIN_TEXTURE_UNUSED() { 1 }#d#

sub new {
   my ($class, %arg) = @_;

   my $self = $class->SUPER::new (%arg,
      setup_req => {
         extmap => 1,
         excmd  => 1,
         widget => 2,
         %{$arg{setup_req} || {}},
      },
   );

   $self->{map_widget}->clr_commands;

   my @cmd_help = map {
      $_->[DC::Pod::N_KW][0] =~ /^(\S+) (?:\s+ \( ([^\)]*) \) )?/x
         or die "unparseable command help: $_->[DC::Pod::N_KW][0]";

      my $cmd = $1;
      my @args = split /\|/, $2;
      @args = (".*") unless @args;

      my (undef, @par) = DC::Pod::section_of $_;
      my $text = DC::Pod::as_label @par;

      $_ = $_ eq ".*" ? "" : " $_"
         for @args;

      map ["$cmd$_", $text],
         sort { (length $a) <=> (length $b) }
            @args
   } sort { $a->[DC::Pod::N_PAR] <=> $b->[DC::Pod::N_PAR] }
          DC::Pod::find command => "*";

   $self->{json_coder}
      ->convert_blessed
      ->filter_json_single_key_object ("\fw" => sub {
         $self->{widget}{$_[0]}
      })
      ->filter_json_single_key_object ("\fc" => sub {
         my ($id) = @_;
         sub {
            $self->send_exti_msg (w_e => $id, @_);
         }
      });

   # destroy widgets on logout
   $self->{on_stop_game_guard} = $self->{map_widget}{root}->connect (stop_game => sub {
      for my $ws (values %{delete $self->{widgetset} || {}}) {
         $_->destroy
            for values %{delete $ws->{w} || {}};
      }

      delete $self->{items};
      $::INV->clear;
      $::INVR->clear;
      $::INVR_HB->clear;
      $::FLOORBOX->clear;
   });

   $self->{map_widget}->add_command (@$_)
      for @cmd_help;

   {
      $self->{dialogue} = my $tex = $TEX_DIALOGUE;
      $self->{map}->set_texture (1, @$tex{qw(name w h s t)}, @{$tex->{minified}});
   }

   {
      $self->{noface} = my $tex = $TEX_NOFACE;
      $self->{map}->set_texture (2, @$tex{qw(name w h s t)}, @{$tex->{minified}});
   }

#   $self->{expire_count} = DC::DB::FIRST_TILE_ID; # minimum non-fixed tile id
#   $self->{expire_w} = EV::timer 1, 1, sub {
#      my $count = (int @{ $self->{texture} } / MIN_TEXTURE_UNUSED) || 1;
# 
#      for ($self->{map}->expire_textures ($self->{expire_count}, $count)) {
#         warn DC::SvREFCNT $self->{texture}[$_];
#         $self->{texture}[$_]->unload;
#         warn "expire texture $_\n";#d#
#      }
# 
#      ($self->{expire_count} += $count) < @{ $self->{texture} }
#         or $self->{expire_count} = DC::DB::FIRST_TILE_ID;
#      warn "count is $count\n";#d#
#   };

   $self->{open_container} = 0;

   # per server
   $self->{mapcache} = "mapcache_$self->{host}_$self->{port}";

   $self
}

sub update_fx_want {
   my ($self) = @_;

   $self->send_exti_msg (fx_want => {
      3 => !!$::CFG->{bgm_enable},   # FT_MUSIC
      5 => !!$::CFG->{audio_enable}, # FT_SOUND
      6 => 1,                        # FT_RSRC
   });
}

sub ext_capabilities {
   my ($self, %cap) = @_;

   $self->update_fx_want;

   $self->send_exti_req (resource => "exp_table", sub {
      my ($exp_table) = @_;

      $self->register_face_handler ($exp_table, sub {
         my ($face) = @_;

         $self->{exp_table} = $self->{json_coder}->decode (delete $face->{data});
         $_->() for values %{ $self->{on_exp_update} || {} };
      });

      ()
   });

   if (my $ts = $cap{tileset}) {
      if (my ($default) = grep $_->[2] & 1, @$ts) {
         $self->{tileset} = $default;
         $self->{tilesize} = $default->[3];
         $self->setup_req (tileset => $default->[0]);

         my $w = int $self->{mapw} * 32 / $self->{tilesize};
         my $h = int $self->{maph} * 32 / $self->{tilesize};

         $self->setup_req (mapsize => "${w}x${h}");
      }
   }
}

sub ext_ambient_music {
   my ($self, $songs) = @_;
   &::audio_music_set_ambient ($songs);
}

#############################################################################

sub widget_associate {
   my ($self, $ws, $id, $widget) = @_;

   $widget ||= new DC::UI::Bin;

   $widget->{s_id} = $id;
   $self->{widget}{$id} = $widget;

   if ($ws) {
      $widget->{s_ws} = $ws;
      $self->{widgetset}{$ws}{w}{$id} = $widget;
   }

   $widget->connect (on_destroy => sub {
      my ($widget) = @_;

      delete $self->{widget}{$widget->{s_id}};
      delete $self->{widgetset}{$widget->{s_ws}}{$widget->{s_id}}
         if exists $widget->{s_ws};
   });
}

# widgetset new
sub ext_ws_n {
   my ($self, $id) = @_;

   $self->{widgetset}{$id} = {
      w => {},
   };
}

# widgetset destroy
sub ext_ws_d {
   my ($self, $id) = @_;

   my $ws = delete $self->{widgetset}{$id}
      or return;

   $_->destroy
      for values %{$ws->{w}};
}

# widgetset create
sub ext_ws_c {
   my ($self, $ws, $id, $class, $args) = @_;

   $self->widget_associate (
      $ws, $id => scalar eval {
         local $SIG{__DIE__};
         "DC::UI::$class"->new (%$args)
      }
   );
}

# widgetset create template
sub ext_ws_ct {
   my ($self, $ws, $type, $template, $done_cb, $cfg) = @_;

   $done_cb ||= sub { };

   my $parse_list; $parse_list = sub {
      my ($list) = @_;
      my @w;

      while (@$list) {
         my ($class, $args) = splice @$list, 0, 2;
         my $name = delete $args->{s_id};
         my $cl   = delete $args->{s_cl};
         my $cfg  = delete $cfg->{$name};
         my $id   = delete $cfg->{id};
         my $w    = eval { "DC::UI::$class"->new (%$args, %{ $cfg || {} }) }
                       or next;

         $self->widget_associate ($ws, $id, $w)
            if $id;

         $w->add ($parse_list->($cl))
            if $cl;

         push @w, $w;
      }

      @w
   };

   # either array reference, or face #
   if ($type eq "inline") {
      $done_cb->();
      $parse_list->($template);
   } elsif ($type eq "face") {
      my $handler; $handler = $self->register_face_handler ($template, sub {
         my ($face) = @_;

         undef $handler;
         $done_cb->();
         $parse_list->($self->{json_coder}->decode ($face->{data}));
      });
   } else {
      $done_cb->(0);
   }
}

# widgetset associate
sub ext_ws_a {
   my ($self, %ass) = @_;

   # everything that has a name, wether conceivably useful or not
   my %wkw = (
      root           => $DC::UI::ROOT,
      tooltip        => $DC::UI::TOOLTIP,

      mapwidget      => $::MAPWIDGET,
      menubar        => $::MENUBAR,
      menupopup      => $::MENUPOPUP,
      pickup_enable  => $::PICKUP_ENABLE,
      buttonbar      => $::BUTTONBAR,
      metaserver     => $::METASERVER,
      buttonbar      => $::BUTTONBAR,
      login_button   => $::LOGIN_BUTTON,
      quit_dialog    => $::QUIT_DIALOG,
      host_entry     => $::HOST_ENTRY,
      metaserver     => $::METASERVER,
      server_info    => $::SERVER_INFO,

      setup_dialog   => $::SETUP_DIALOG,
      setup_notebook => $::SETUP_NOTEBOOK,
      setup_server   => $::SETUP_SERVER,
      setup_keyboard => $::SETUP_KEYBOARD,

      pl_notebook    => $::PL_NOTEBOOK,
      pl_window      => $::PL_WINDOW,
      inventory_page => $::INVENTORY_PAGE,
      stats_page     => $::STATS_PAGE,
      skill_page     => $::SKILL_PAGE,
      spell_page     => $::SPELL_PAGE,
      spell_list     => $::SPELL_LIST,

      floorbox       => $::FLOORBOX,
      help_window    => $::HELP_WINDOW,
      message_window => $::MESSAGE_WINDOW,
      message_dist   => $::MESSAGE_DIST,
      statusbox      => $::STATUSBOX,

      inv            => $::INV,
      invr           => $::INVR,
      invr_hb        => $::INVR_HB,
   );

   while (my ($id, $name) = each %ass) {
      $self->widget_associate (undef, $id => $wkw{$name});
   }
}

# widget call
sub ext_w_c {
   my ($self, $id, $rcb, $method, @args) = @_;

   my $w = $self->{widget}{$id}
      or return;

   if ($rcb) {
      $rcb->($w->$method (@args));
   } else {
      $w->$method (@args);
   }
}

# widget set
sub ext_w_s {
   my ($self, $id, $attr) = @_;

   my $w = $self->{widget}{$id}
      or return;

   for (my $i = 0; $i < $#$attr; $i += 2) {
      my ($member, $value) = @$attr[$i, $i+1];
      if (defined $value) {
         $w->{$member} = $value;
      } else {
         delete $w->{$member};
      }
      $w->{parent}->realloc if $member =~ /^c_/ && $w->{visible};
   }
}

# widget get
sub ext_w_g {
   my ($self, $id, $rid, @attr) = @_;

   my $w = $self->{widget}{$id}
      or return;

   $self->send_exti_msg (w_e => $rid, map $w->{$_}, @attr);
}

# message window
sub ext_channel_info {
   my ($self, $info) = @_;
   $self->{channels}->{$info->{id}} = $info;
   $::MESSAGE_DIST->add_channel ($info);
}

#############################################################################

sub logprint {
   my ($self, @a) = @_;

   DC::DB::logprint "$Deliantra::VARDIR/log.$self->{host}" => (join "", @a), sub { };
}

sub _stat_numdiff {
   my ($self, $name, $old, $new) = @_;

   my $diff = $new - $old;

   $diff = 0.01 * int $diff * 100;

   0.1 >= abs $diff ? ()
      : $diff < 0 ? "$name$diff" : "$name+$diff"
}

sub _stat_skillmaskdiff {
   my ($self, $name, $old, $new) = @_;

   my $diff = $old ^ $new
      or return;

   my @diff = map
                 {
                    $diff & $_
                       ?  (($new & $_ ? "+" : "-") . $self->{spell_paths}{$_})
                       : ()
                 }
              sort { $a <=> $b } keys %{$self->{spell_paths}};

   "\u$name: " . (join ", ", @diff)
}

# all stats that are chacked against changes
my @statchange = (
   [&CS_STAT_STR          => \&_stat_numdiff, "Str"],
   [&CS_STAT_INT          => \&_stat_numdiff, "Int"],
   [&CS_STAT_WIS          => \&_stat_numdiff, "Wis"],
   [&CS_STAT_DEX          => \&_stat_numdiff, "Dex"],
   [&CS_STAT_CON          => \&_stat_numdiff, "Con"],
   [&CS_STAT_CHA          => \&_stat_numdiff, "Cha"],
   [&CS_STAT_POW          => \&_stat_numdiff, "Pow"],
   [&CS_STAT_WC           => \&_stat_numdiff, "Wc"],
   [&CS_STAT_AC           => \&_stat_numdiff, "Ac"],
   [&CS_STAT_DAM          => \&_stat_numdiff, "Dam"],
   [&CS_STAT_SPEED        => \&_stat_numdiff, "Speed"],
   [&CS_STAT_WEAP_SP      => \&_stat_numdiff, "WSp"],
   [&CS_STAT_MAXHP        => \&_stat_numdiff, "HP"],
   [&CS_STAT_MAXSP        => \&_stat_numdiff, "Mana"],
   [&CS_STAT_MAXGRACE     => \&_stat_numdiff, "Grace"],
   [&CS_STAT_WEIGHT_LIM   => \&_stat_numdiff, "Weight"],
   [&CS_STAT_SPELL_ATTUNE => \&_stat_skillmaskdiff, "attuned"],
   [&CS_STAT_SPELL_REPEL  => \&_stat_skillmaskdiff, "repelled"],
   [&CS_STAT_SPELL_DENY   => \&_stat_skillmaskdiff, "denied"],
   [&CS_STAT_RES_PHYS     => \&_stat_numdiff, "phys"],
   [&CS_STAT_RES_MAG      => \&_stat_numdiff, "magic"],
   [&CS_STAT_RES_FIRE     => \&_stat_numdiff, "fire"],
   [&CS_STAT_RES_ELEC     => \&_stat_numdiff, "electricity"],
   [&CS_STAT_RES_COLD     => \&_stat_numdiff, "cold"],
   [&CS_STAT_RES_CONF     => \&_stat_numdiff, "confusion"],
   [&CS_STAT_RES_ACID     => \&_stat_numdiff, "acid"],
   [&CS_STAT_RES_DRAIN    => \&_stat_numdiff, "drain"],
   [&CS_STAT_RES_GHOSTHIT => \&_stat_numdiff, "ghosthit"],
   [&CS_STAT_RES_POISON   => \&_stat_numdiff, "poison"],
   [&CS_STAT_RES_SLOW     => \&_stat_numdiff, "slow"],
   [&CS_STAT_RES_PARA     => \&_stat_numdiff, "paralyse"],
   [&CS_STAT_TURN_UNDEAD  => \&_stat_numdiff, "turnundead"],
   [&CS_STAT_RES_FEAR     => \&_stat_numdiff, "fear"],
   [&CS_STAT_RES_DEPLETE  => \&_stat_numdiff, "depletion"],
   [&CS_STAT_RES_DEATH    => \&_stat_numdiff, "death"],
   [&CS_STAT_RES_HOLYWORD => \&_stat_numdiff, "godpower"],
   [&CS_STAT_RES_BLIND    => \&_stat_numdiff, "blind"],
);

sub stats_update {
   my ($self, $stats) = @_;

   my $prev = $self->{prev_stats} || { };

   if (my @diffs =
          (
             ($stats->{+CS_STAT_EXP64} > $prev->{+CS_STAT_EXP64} ? ($stats->{+CS_STAT_EXP64} - $prev->{+CS_STAT_EXP64}) . " experience gained" : ()),
             map {
                $stats->{$_} && $prev->{$_} 
                   && $stats->{$_}[1] > $prev->{$_}[1] ? "($self->{skill_info}{$_}+" . ($stats->{$_}[1] - $prev->{$_}[1]) . ")" : ()
             } sort { $a <=> $b } keys %{$self->{skill_info}}
          )
   ) {
      my $msg = join " ", @diffs;
      $self->{statusbox}->add ($msg, group => "experience $msg", fg => [0.5, 1, 0.5, 0.8], timeout => 5);
   }

   if (
      my @diffs = map $_->[1]->($self, $_->[2], $prev->{$_->[0]}, $stats->{$_->[0]}), @statchange
   ) {
      my $msg = "<b>stat change</b>: " . (join " ", map "($_)", @diffs);
      $self->{statusbox}->add ($msg, group => "stat $msg", fg => [0.8, 1, 0.2, 1], timeout => 20);
   }

   $self->update_stats_window ($stats, $prev);

   $self->{prev_stats} = { %$stats };
}

my %RES_TBL = (
   phys  => CS_STAT_RES_PHYS,
   magic => CS_STAT_RES_MAG,
   fire  => CS_STAT_RES_FIRE,
   elec  => CS_STAT_RES_ELEC,
   cold  => CS_STAT_RES_COLD,
   conf  => CS_STAT_RES_CONF,
   acid  => CS_STAT_RES_ACID,
   drain => CS_STAT_RES_DRAIN,
   ghit  => CS_STAT_RES_GHOSTHIT,
   pois  => CS_STAT_RES_POISON,
   slow  => CS_STAT_RES_SLOW,
   para  => CS_STAT_RES_PARA,
   tund  => CS_STAT_TURN_UNDEAD,
   fear  => CS_STAT_RES_FEAR,
   depl  => CS_STAT_RES_DEPLETE,
   deat  => CS_STAT_RES_DEATH,
   holyw => CS_STAT_RES_HOLYWORD,
   blind => CS_STAT_RES_BLIND,
);

sub update_stats_window {
   my ($self, $stats, $prev) = @_;

   # I love text protocols...

   my $hp   = $stats->{+CS_STAT_HP} * 1;
   my $hp_m = $stats->{+CS_STAT_MAXHP} * 1;
   my $sp   = $stats->{+CS_STAT_SP} * 1;
   my $sp_m = $stats->{+CS_STAT_MAXSP} * 1;
   my $fo   = $stats->{+CS_STAT_FOOD} * 1;
   my $fo_m = 999;
   my $gr   = $stats->{+CS_STAT_GRACE} * 1;
   my $gr_m = $stats->{+CS_STAT_MAXGRACE} * 1;

   $::GAUGES->{hp}      ->set_value ($hp, $hp_m);
   $::GAUGES->{mana}    ->set_value ($sp, $sp_m);
   $::GAUGES->{food}    ->set_value ($fo, $fo_m);
   $::GAUGES->{grace}   ->set_value ($gr, $gr_m);
   $::GAUGES->{exp}     ->set_label ("Exp: " . (::formsep ($stats->{+CS_STAT_EXP64}))#d#
                                     . " (lvl " . ($stats->{+CS_STAT_LEVEL} * 1) . ")");
   $::GAUGES->{exp}     ->set_value ($stats->{+CS_STAT_LEVEL}, $stats->{+CS_STAT_EXP64});
   $::GAUGES->{range}   ->set_text ($stats->{+CS_STAT_RANGE});
   my $title = $stats->{+CS_STAT_TITLE};
   $title =~ s/^Player: //;
   $::STATWIDS->{title} ->set_text ("Title: " . $title);

   $::STATWIDS->{st_str} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_STR});
   $::STATWIDS->{st_dex} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_DEX});
   $::STATWIDS->{st_con} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_CON});
   $::STATWIDS->{st_int} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_INT});
   $::STATWIDS->{st_wis} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_WIS});
   $::STATWIDS->{st_pow} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_POW});
   $::STATWIDS->{st_cha} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_CHA});
   $::STATWIDS->{st_wc}  ->set_text (sprintf "%d"  , $stats->{+CS_STAT_WC});
   $::STATWIDS->{st_ac}  ->set_text (sprintf "%d"  , $stats->{+CS_STAT_AC});
   $::STATWIDS->{st_dam} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_DAM});
   $::STATWIDS->{st_arm} ->set_text (sprintf "%d"  , $stats->{+CS_STAT_RES_PHYS});
   $::STATWIDS->{st_spd} ->set_text (sprintf "%.1f", $stats->{+CS_STAT_SPEED});
   $::STATWIDS->{st_wspd}->set_text (sprintf "%.1f", $stats->{+CS_STAT_WEAP_SP});
 
   $self->update_weight;

   $::STATWIDS->{"res_$_"}->set_text (sprintf "%d%%", $stats->{$RES_TBL{$_}})
      for keys %RES_TBL;

   my $sktbl = $::STATWIDS->{skill_tbl};
   my @skills = keys %{ $self->{skill_info} };

   my @order = sort { $stats->{$b->[0]}[1] <=> $stats->{$a->[0]}[1] or $a->[1] cmp $b->[1] }
               map [$_, $self->{skill_info}{$_}],
               grep exists $stats->{$_},
               @skills;
  
   if ($self->{stat_order} ne join ",", map $_->[0], @order) {
      $self->{stat_order} = join ",", map $_->[0], @order;

      $sktbl->clear;

      my $sw = $self->{skillwid}{""} ||= [
         0, 0, (new DC::UI::Label text => "Experience", align => 1),
         1, 0, (new DC::UI::Label text => "Lvl.", align => 1),
         2, 0, (new DC::UI::Label text => "Progress"),
         3, 0, (new DC::UI::Label text => "Skill", expand => 1, align => 0),
         4, 0, (new DC::UI::Label text => "Experience", align => 1),
         5, 0, (new DC::UI::Label text => "Lvl.", align => 1),
         6, 0, (new DC::UI::Label text => "Progress"),
         7, 0, (new DC::UI::Label text => "Skill", expand => 1, align => 0),
      ];

      my @add = @$sw;

      my $TOOLTIP_ALL = "\n\n<small>Left click - ready skill\nMiddle click - use skill\nRight click - further options</small>";

      my @TOOLTIP_LVL  = (tooltip => "<b>Level</b>. The level of the skill.$TOOLTIP_ALL", can_events => 1, can_hover => 1);
      my @TOOLTIP_EXP  = (tooltip => "<b>Experience</b>. The experience points you have in this skill.$TOOLTIP_ALL", can_events => 1, can_hover => 1);

      my ($x, $y) = (0, 1);
      for (@order) {
         my ($idx, $name) = @$_;

         my $spell_cb = sub {
            my ($widget, $ev) = @_;

            if ($ev->{button} == 1) {
               $::CONN->user_send ("ready_skill $name");
            } elsif ($ev->{button} == 2) {
               $::CONN->user_send ("use_skill $name");
            } elsif ($ev->{button} == 3) {
               my $shortname = DC::shorten $name, 14;
               (new DC::UI::Menu
                  items => [
                     ["bind <i>ready_skill $shortname</i> to a key" => sub { DC::Macro::quick_macro ["ready_skill $name"] }],
                     ["bind <i>use_skill $shortname</i> to a key"   => sub { DC::Macro::quick_macro ["use_skill $name"]   }],
                  ],
               )->popup ($ev);
            } else {
               return 0;
            }

            1
         };

         my $sw = $self->{skillwid}{$idx} ||= [
            # exp
            (new DC::UI::Label
             align => 1, font => $::FONT_FIXED, fg => [1, 1, 0], on_button_down => $spell_cb, @TOOLTIP_EXP),

            # level
            (new DC::UI::Label
             text => "0", align => 1, font => $::FONT_FIXED, fg => [0, 1, 0], padding_x => 4, on_button_down => $spell_cb, @TOOLTIP_LVL),

            # progress
            (new DC::UI::ExperienceProgress),

            # label
            (new DC::UI::Label text => $name, on_button_down => $spell_cb, align => 0,
             can_events => 1, can_hover => 1, tooltip => (DC::Pod::section_label skill_description => $name) . $TOOLTIP_ALL),
         ];

         push @add,
            $x * 4 + 0, $y, $sw->[0],
            $x * 4 + 1, $y, $sw->[1],
            $x * 4 + 2, $y, $sw->[2],
            $x * 4 + 3, $y, $sw->[3],
         ;

         $x++ and ($x, $y) = (0, $y + 1);
      }

      $sktbl->add_at (@add);
   }

   for (@order) {
      my ($idx, $name) = @$_;
      my $val = $stats->{$idx};

      next if $prev->{$idx}[1] eq $val->[1];

      my $sw = $self->{skillwid}{$idx};
      $sw->[0]->set_text (::formsep ($val->[1]));
      $sw->[1]->set_text ($val->[0] * 1);
      $sw->[2]->set_value (@$val);

      $::GAUGES->{skillexp}->set_label ("$name %d%%");
      $::GAUGES->{skillexp}->set_value (@$val);
   }
}

sub user_send {
   my ($self, $command) = @_;

   $self->{record}->($command)
      if $self->{record};

   $self->logprint ("send: ", $command);
   $self->send_command ($command);
}

sub record {
   my ($self, $cb) = @_;

   $self->{record} = $cb;
}

sub map_scroll {
   my ($self, $dx, $dy) = @_;

   $self->{map_widget}->scroll ($dx, $dy);
}

sub feed_map1a {
   my ($self, $data) = @_;

   my $missing = $self->{map}->map1a_update ($data, $self->{setup}{extmap});
   my $delay;

   for my $tile (@$missing) {
      next if $self->{delay}{$tile};

      $delay = 1;

      if (my $tex = $self->{texture}[$tile]) {
         $tex->upload;
      } else {
         $self->{delay}{$tile} = 1;

         # we assume the face is in-flight and will eventually arrive
         push @{$self->{tile_cb}{$tile}}, sub {
            delete $self->{delay}{$tile};
            $_[0]->upload;
         };
      }
   }

   if ($delay) {
      # delay the map drawing a tiny bit in the hope of getting the missing tiles fetched
      EV::once undef, 0, 0.03, sub {
         $self->{map_widget}->update
            if $self->{map_widget};
      };
   } else {
      $self->{map_widget}->update;
   }
}

sub magicmap {
   my ($self, $w, $h, $x, $y, $data) = @_;

   $self->{map_widget}->set_magicmap ($w, $h, $x, $y, $data);
}

sub flush_map {
   my ($self) = @_;

   return unless $self->{map_info};

   for my $map_info (values %{ $self->{map_cache} || {} }) {
      my ($hash, $rdata, $x, $y, $w, $h) = @$map_info;

      my $data = $self->{map}->get_rect ($x, $y, $w, $h);

      if ($data ne $$rdata) {
         $map_info->[1] = \$data;
         my $cdata = Compress::LZF::compress $data;
         DC::DB::put $self->{mapcache} => $hash => $cdata, sub { };
      }
   }
}

sub map_clear {
   my ($self) = @_;

   $self->flush_map;
   delete $self->{map_info};
   delete $self->{neigh_map};

   $self->{map}->clear;
   delete $self->{map_widget}{magicmap};
}

sub bg_fetch {
   my ($self) = @_;

   my $tile;
   
   do {
      $tile = pop @{$self->{bg_fetch}}
         or return;
   } while $self->{texture}[$tile];

   DC::DB::get tilecache => $tile, sub {
      my ($data) = @_;

      return unless $self->{map}; # stop when destroyed

      if (defined $data) {
         $self->have_tile ($tile, $data);
         $self->{texture}[$tile]->upload;
      }

      $self->bg_fetch;
   };
}

sub load_map($$$$$$) {
   my ($self, $hash, $x, $y, $w, $h) = @_;

   my $map_info = $self->{map_cache}{$hash} = [$hash, \"", $x, $y, $w, $h];

   my $cb = sub {
      $map_info->[1] = \$_[0];

      my $inprogress = @{ $self->{bg_fetch} || [] };
      unshift @{ $self->{bg_fetch} }, $self->{map}->set_rect ($x, $y, $_[0]);
      $self->bg_fetch unless $inprogress;
   };

   if (my $map_info = $self->{map_cache_old}{$hash}) {
      $cb->(${ $map_info->[1] });
   } else {
      my $gen = $self->{map_change_gen};

      DC::DB::get $self->{mapcache} => $hash, sub {
         return unless $gen == $self->{map_change_gen};
         return unless defined $_[0];
         $cb->(Compress::LZF::decompress $_[0]);
      };
   }
}

# hardcode /world/world_xxx_xxx map names, the savings are enourmous,
# (server resources, latency, bandwidth), so this hack is warranted.
# the right fix is to make real tiled maps with an overview file
sub send_mapinfo {
   my ($self, $data, $cb) = @_;

   if ($self->{map_info}[0] =~ m%^/world/world_(\d\d\d)_(\d\d\d)$%) {
      my ($wx, $wy) = ($1, $2);

      if ($data =~ /^spatial ([1-4]+)$/) {
         my @dx = (0, 0, 1, 0, -1);
         my @dy = (0, -1, 0, 1, 0);
         my ($dx, $dy);

         for (split //, $1) {
            $dx += $dx[$_];
            $dy += $dy[$_];
         }

         $cb->(spatial => 15,
            $self->{map_info}[1] - $self->{map}->ox + $dx * 50,
            $self->{map_info}[2] - $self->{map}->oy + $dy * 50,
            50, 50,
            sprintf "/world/world_%03d_%03d", $wx + $dx, $wy + $dy
         );

         return;
      }
   }

   $self->SUPER::send_mapinfo ($data, $cb);
}

# this method does a "flood fill" into every tile direction
# it assumes that tiles are arranged in a rectangular grid,
# i.e. a map is the same as the left of the right map etc.
# failure to comply is harmless and results in display errors
# at worst.
sub flood_fill {
   my ($self, $block, $gx, $gy, $path, $hash, $flags) = @_;

   # the server does not allow map paths > 6
   return if 7 <= length $path;

   my ($x0, $y0, $x1, $y1) = @{$self->{neigh_rect}};

   for (
      [1, 3,  0, -1],
      [2, 4,  1,  0],
      [3, 1,  0,  1],
      [4, 2, -1,  0],
   ) {
      my ($tile, $tile2, $dx, $dy) = @$_;

      next if $block & (1 << $tile);
      my $block = $block | (1 << $tile2);

      my $gx = $gx + $dx;
      my $gy = $gy + $dy;

      next unless $flags & (1 << ($tile - 1));
      next if $self->{neigh_grid}{$gx, $gy}++;

      my $neigh = $self->{neigh_map}{$hash} ||= [];
      if (my $info = $neigh->[$tile]) {
         my ($flags, $x, $y, $w, $h, $hash) = @$info;

         $self->flood_fill ($block, $gx, $gy, "$path$tile", $hash, $flags)
            if $x >= $x0 && $x + $w < $x1 && $y >= $y0  && $y + $h < $y1;

      } else {
         my $gen = $self->{map_change_gen};
         $self->send_mapinfo ("spatial $path$tile", sub {
            return unless $gen == $self->{map_change_gen};

            my ($mode, $flags, $x, $y, $w, $h, $hash) = @_;

            return if $mode ne "spatial";

            $x += $self->{map}->ox;
            $y += $self->{map}->oy;

            $self->load_map ($hash, $x, $y, $w, $h)
               unless $self->{neigh_map}{$hash}[5]++;#d#

            $neigh->[$tile] = [$flags, $x, $y, $w, $h, $hash];

            $self->flood_fill ($block, $gx, $gy, "$path$tile", $hash, $flags)
               if $x >= $x0 && $x + $w < $x1 && $y >= $y0  && $y + $h < $y1;
         });
      }
   }
}

sub map_change {
   my ($self, $mode, $flags, $x, $y, $w, $h, $hash) = @_;

   $self->flush_map;

   ++$self->{map_change_gen};
   $self->{map_cache_old} = delete $self->{map_cache};

   my ($ox, $oy) = ($::MAP->ox, $::MAP->oy);

   my $mapmapw = $self->{mapmap}->{w};
   my $mapmaph = $self->{mapmap}->{h};

   $self->{neigh_rect} = [
      $ox - $mapmapw * 0.5,      $oy - $mapmapw * 0.5,
      $ox + $mapmapw * 0.5 + $w, $oy + $mapmapw * 0.5 + $h,
   ];
   
   delete $self->{neigh_grid};

   $x += $ox;
   $y += $oy;

   $self->{map_info} = [$hash, $x, $y, $w, $h];

   (my $map = $hash) =~ s/^.*?\/([^\/]+)$/\1/;
   $::STATWIDS->{map}->set_text ("Map: " . $map);

   $self->load_map ($hash, $x, $y, $w, $h);
   $self->flood_fill (0, 0, 0, "", $hash, $flags);
}

sub face_find {
   my ($self, $facenum, $face, $cb) = @_;

   if ($face->{type} == 0) { # FT_FACE
      my $id = DC::DB::get_tile_id_sync $face->{name};

      $face->{id} = $id;
      $self->{map}->set_tileid ($facenum => $id);

      DC::DB::get tilecache => $id, $cb;

   } elsif ($face->{type} & 1) { # with metadata
      DC::DB::get res_meta => $face->{name}, $cb;

   } else { # no metadata
      DC::DB::get res_data => $face->{name}, $cb;
   }
}

sub face_update {
   my ($self, $facenum, $face, $changed) = @_;

   if ($face->{type} == 0) {
      # image, FT_FACE
      DC::DB::put tilecache => $face->{id} => $face->{data}, sub { }
         if $changed;

      $self->have_tile ($face->{id}, delete $face->{data});

   } elsif ($face->{type} & 1) {
      # split metadata case, FT_MUSIC, FT_SOUND
      if ($changed) { # new data
         my ($meta, $data) = unpack "(w/a*)*", $face->{data};
         $face->{data} = $meta;

         # rely on strict ordering here and also on later fetch
         DC::DB::put res_data => $face->{name} => $data, sub { };
         DC::DB::put res_meta => $face->{name} => $meta, sub { };
      }

      $face->{data} = $self->{json_coder}->decode ($face->{data});
      ::add_license ($face);
      ::message ({ markup => DC::asxml "downloaded resource '$face->{data}{name}', type $face->{type}." })
         if $changed;

      if ($face->{type} == 3) { # FT_MUSIC
         &::audio_music_push ($facenum);
      } elsif ($face->{type} == 5) { # FT_SOUND
         &::audio_sound_push ($facenum);
      }

   } else {
      # flat resource case, FT_RSRC
      DC::DB::put res_data => $face->{name} => $face->{data}, sub { }
         if $changed;
   }

   if (my $cbs = $self->{face_cb}{$facenum}) {
      $_->($face, $changed) for @$cbs;
   }
}

sub smooth_update {
   my ($self, $facenum, $face) = @_;

   $self->{map}->set_smooth ($facenum, $face->{smoothface}, $face->{smoothlevel});
}

sub have_tile {
   my ($self, $tile, $data) = @_;

   return unless $self->{map};

   my $tex = $self->{texture}[$tile] ||=
      new DC::Texture
         tile => $tile,
         image => $data, delete_image => 1,
         minify => 1;

   if (my $cbs = delete $self->{tile_cb}{$tile}) {
      $_->($tex) for @$cbs;
   }
}

# call in non-void context registers a temporary
# hook with handle, otherwise its permanent
sub on_face_change {
   my ($self, $num, $cb) = @_;

   push @{$self->{face_cb}{$num}}, $cb;

   defined wantarray
      ? Guard::guard {
           @{$self->{face_cb}{$num}}
              = grep $_ != $cb,
                   @{$self->{face_cb}{$num}};
        }
      : ()
}

# call in non-void context registers a temporary
# hook with handle, otherwise its permanent
sub register_face_handler {
   my ($self, $num, $cb) = @_;

   return unless $num;

   # invoke if available right now
   $cb->($self->{face}[$num], 0)
      unless exists $self->{face}[$num]{loading};

   # future changes
   $self->on_face_change ($num => $cb)
}

sub sound_play {
   my ($self, $type, $face, $dx, $dy, $vol) = @_;

   &::audio_sound_play ($face, $dx, $dy, $vol)
      unless $type & 1; # odd types are silent for future expansion
}

my $LAST_QUERY; # server is stupid, stupid, stupid

sub query {
   my ($self, $flags, $prompt) = @_;

   $prompt = $LAST_QUERY unless length $prompt;
   $LAST_QUERY = $prompt;

   $self->{query}-> ($self, $flags, $prompt);
}

sub sanitise_xml($) {
   local $_ = shift;

   # we now weed out all tags we do not support
   s{ <(?! /?i> | /?u> | /?b> | /?big | /?small | /?s | /?tt | fg\ | /fg>)
   }{
      "&lt;"
   }gex;

   # now all entities
   s/&(?!amp;|lt;|gt;|apos;|quot;|#[0-9]+;|#x[0-9a-fA-F]+;)/&amp;/g;

   # handle some elements
   s/<fg name='([^']*)'>(.*?)<\/fg>/<span foreground='$1'>$2<\/span>/gs;
   s/<fg name="([^"]*)">(.*?)<\/fg>/<span foreground="$1">$2<\/span>/gs;

   s/\s+$//;

   $_
}

our %NAME_TO_COLOR = (
   black	=>  0,
   white	=>  1,
   darkblue	=>  2,
   red	        =>  3,
   orange	=>  4,
   lightblue	=>  5,
   darkorange	=>  6,
   green	=>  7,
   darkgreen	=>  8,
   grey         =>  9,
   brown	=> 10,
   yellow	=> 11,
   tan          => 12,
);

our @CF_COLOR = (
   [1.00, 1.00, 1.00], #[0.00, 0.00, 0.00],
   [1.00, 1.00, 1.00],
   [0.50, 0.50, 1.00], #[0.00, 0.00, 0.55]
   [1.00, 0.00, 0.00],
   [1.00, 0.54, 0.00],
   [0.11, 0.56, 1.00],
   [0.93, 0.46, 0.00],
   [0.18, 0.54, 0.34],
   [0.56, 0.73, 0.56],
   [0.80, 0.80, 0.80],
   [0.75, 0.61, 0.20],
   [0.99, 0.77, 0.26],
   [0.74, 0.65, 0.41],
);

sub msg {
   my ($self, $color, $type, $text, @extra) = @_;

   $text = sanitise_xml $text;

   if (my $cb = $self->{cb_msg}{$type}) {
      $_->($self, $color, $type, $text, @extra) for values %$cb;
   } elsif ($type =~ /^(?:chargen-race-title|chargen-race-description)$/) {
      $type =~ s/-/_/g;
      $self->{$type} = $text;
   } else {
      $self->logprint ("msg: ", $text);
      return if $color < 0; # negative color == ignore if not understood

      my $fg = $CF_COLOR[$color & NDI_COLOR_MASK] || [1, 0, 0];

      ## try to create single paragraphs of multiple lines sent by the server
      # no longer neecssary with TRT servers
      #$text =~ s/(?<=\S)\n(?=\w)/ /g;

      ::message ({
         fg     => $fg,
         markup => $text,
         type   => $type,
         extra  => [@extra],
         color_flags => $color, #d# ugly, kill
      });

#      $color &= ~NDI_CLEAR; # only clear once for multiline messages
#      # actually, this is an ugly design. _we_ should control the channels,
#      # not some random other widget, as the channels are clearly protocol-specific.
#      # then we could also react to flags such as CLEAR without resorting to
#      # hacks such as color_flags, above.

      $self->{statusbox}->add ($text,
         group        => $text,
         fg           => $fg,
         timeout      => $color >= 2 ? 180 : 10,
         tooltip_font => $::FONT_FIXED,
      ) if $type eq "info";
   }
}

sub spell_add {
   my ($self, $spell) = @_;

   # try to create single paragraphs out of the multiple lines sent by the server
   $spell->{message} =~ s/(?<=\S)\n(?=\w)/ /g;
   $spell->{message} =~ s/\n+$//;
   $spell->{message} ||= "Server did not provide a description for this spell.";

   $::SPELL_LIST->add_spell ($spell);

   $self->{map_widget}->add_command ("invoke $spell->{name}", DC::asxml $spell->{message});
   $self->{map_widget}->add_command ("cast $spell->{name}", DC::asxml $spell->{message});
}

sub spell_delete {
   my ($self, $spell) = @_;

   $::SPELL_LIST->remove_spell ($spell);
}

sub setup {
   my ($self, $setup) = @_;

   $self->{map_widget}->set_tilesize ($self->{tilesize});
   $::MAP->resize ($self->{mapw}, $self->{maph});
}

sub addme_success {
   my ($self) = @_;

   my %skill_help;

   for my $node (DC::Pod::find skill_description => "*") {
      my (undef, @par) = DC::Pod::section_of $node;
      $skill_help{$node->[DC::Pod::N_KW][0]} = DC::Pod::as_label @par;
   };
 
   for my $skill (values %{$self->{skill_info}}) {
      $self->{map_widget}->add_command ("ready_skill $skill",
                                        (DC::asxml "Ready the skill '$skill'\n\n")
                                        . $skill_help{$skill});
      $self->{map_widget}->add_command ("use_skill $skill",
                                        (DC::asxml "Immediately use the skill '$skill'\n\n")
                                        . $skill_help{$skill});
   }
}

sub eof {
   my ($self) = @_;

   $self->{map_widget}->clr_commands;

   ::stop_game ();
}

sub update_floorbox {
   $DC::UI::ROOT->on_refresh ($::FLOORBOX => sub {
      return unless $::CONN;

      $::FLOORBOX->clear;

      my @add;

      my $row;
      for (sort { $b->{count} <=> $a->{count} } values %{ $::CONN->{container}{$::CONN->{open_container} || 0} }) {
         next if $_->{tag} & 0x80000000;
         if ($row < 6) {
            local $_->{face_widget}; # hack to force recreation of widget
            local $_->{desc_widget}; # hack to force recreation of widget
            DC::Item::update_widgets $_;

            push @add,
               0, $row, $_->{face_widget},
               1, $row, $_->{desc_widget};

            $row++;
         } else {
            push @add, 1, $row, new DC::UI::Button
               text        => "More...",
               on_activate => sub { ::toggle_player_page ($::INVENTORY_PAGE); 0 },
            ;
            last;
         }
      }
      if ($::CONN->{open_container}) {
         push @add, 1, $row++, new DC::UI::Button
            text        => "Close container",
            on_activate => sub { $::CONN->send ("apply $::CONN->{open_container}") }
         ;
      }

      $::FLOORBOX->add_at (@add);
   });

   $::WANT_REFRESH = 1;
}

sub set_opencont {
   my ($conn, $tag, $name) = @_;
   $conn->{open_container} = $tag;
   update_floorbox;

   $::INVR_HB->clear;
   $::INVR_HB->add (new DC::UI::Label expand => 1, text => $name);

   if ($tag != 0) { # Floor isn't closable, is it?
      $::INVR_HB->add (new DC::UI::Button
         text     => "Close container",
         tooltip  => "Close the currently open container (if one is open)",
         on_activate => sub {
            $::CONN->send ("apply $tag") # $::CONN->{open_container}")
               if $tag != 0;
            0
         },
      );
   }

   $::INVR->set_items ($conn->{container}{$tag});
}

sub update_containers {
   my ($self) = @_;

   $DC::UI::ROOT->on_refresh ("update_containers_$self" => sub {
      my $todo = delete $self->{update_container}
         or return;

      for my $tag (keys %$todo) {
         update_floorbox if $tag == 0 or $tag == $self->{open_container};
         if ($tag == 0) {
            $::INVR->set_items ($self->{container}{0})
               if $tag == $self->{open_container};
         } elsif ($tag == $self->{player}{tag}) {
            $::INV->set_items ($self->{container}{$tag})
         } else {
            $::INVR->set_items ($self->{container}{$tag})
               if $tag == $self->{open_container};
         }
      }
   });
}

sub container_add {
   my ($self, $tag, $items) = @_;

   $self->{update_container}{$tag}++;
   $self->update_containers;
}

sub container_clear {
   my ($self, $tag) = @_;

   $self->{update_container}{$tag}++;
   $self->update_containers;
}

sub item_delete {
   my ($self, @items) = @_;

   $self->{update_container}{$_->{container}}++
      for @items;
   
   $self->update_containers;
}

sub item_update {
   my ($self, $item) = @_;

   #print "item_update: $item->{tag} in $item->{container} pt($self->{player}{tag}) oc($::CONN->{open_container}) f($item->{flags})\n";

   DC::Item::update_widgets $item;
   
   if ($item->{tag} == $::CONN->{open_container} && not ($item->{flags} & F_OPEN)) {
      set_opencont ($::CONN, 0, "Floor");

   } elsif ($item->{flags} & F_OPEN) {
      set_opencont ($::CONN, $item->{tag}, DC::Item::desc_string $item);

   } else {
      $self->{update_container}{$item->{container}}++;
      $self->update_containers;
   }
}

sub player_update {
   my ($self, $player) = @_;

   $self->update_weight;
}

sub update_weight {
   my ($self) = @_;

   my $weight = .001 * $self->{player}{weight};
   my $limit  = .001 * $self->{stat}{+CS_STAT_WEIGHT_LIM};

   $::STATWIDS->{weight}->set_text (sprintf "Weight: %.1fkg", $weight);
   $::STATWIDS->{m_weight}->set_text (sprintf "Max Weight: %.1fkg", $limit);
   $::STATWIDS->{i_weight}->set_text (sprintf "%.1f/%.1fkg", $weight, $limit);
}

sub update_server_info {
   my ($self) = @_;

   my @yesno = ("<span foreground='red'>no</span>", "<span foreground='green'>yes</span>");

   my $version = JSON::XS->new->encode ($self->{s_version});

   $::SERVER_INFO->set_markup (
      "server <tt>$self->{host}:$self->{port}</tt>\n"
    . "protocol version <tt>$version</tt>\n"
    . "minimap support $yesno[$self->{setup}{mapinfocmd} > 0]\n"
    . "extended command support $yesno[$self->{setup}{extcmd} > 0]\n"
    . "examine command support $yesno[$self->{setup}{excmd} > 0]\n"
    . "editing support $yesno[!!$self->{editor_support}]\n"
    . "map attributes $yesno[$self->{setup}{extmap} > 0]\n"
    . "big image protocol support $yesno[$self->{setup}{fxix} > 0]\n"
    . "client support $yesno[$self->{cfplus_ext} > 0]"
      . ($self->{cfplus_ext} > 0 ? ", version $self->{cfplus_ext}" : "") ."\n"
    . "map size $self->{mapw}×$self->{maph}\n"
   );

}

sub logged_in {
   my ($self) = @_;

   $self->send_ext_req (cfplus_support => version => 2, sub {
      my (%msg) = @_;

      $self->{cfplus_ext} = $msg{version};
      $self->update_server_info;

      if ($self->{cfplus_ext} >= 2) {
         $self->send_ext_req ("editor_support", sub {
            $self->{editor_support} = { @_ };
            $self->update_server_info;

            0
         });
      }

      0
   });

   $self->update_server_info;

   $self->send_command ("output-rate $::CFG->{output_rate}") if $::CFG->{output_rate} > 0;
   $self->send_pickup ($::CFG->{pickup});
}

sub lookat {
   my ($self, $x, $y) = @_;

   if ($self->{cfplus_ext}) {
      $self->send_ext_req (lookat => $x, $y, sub {
         my (%msg) = @_;

         if (exists $msg{npc_dialog}) {
            # start npc chat dialog
            $self->{npc_dialog} = new DC::NPCDialog::
               token => $msg{npc_dialog},
               title => "$msg{npc_dialog}[0] (NPC)",
               conn  => $self,
            ;
         }
      });
   }

   $self->send ("lookat $x $y");
}

sub destroy {
   my ($self) = @_;

   (delete $self->{npc_dialog})->destroy
      if $self->{npc_dialog};

   $self->SUPER::destroy;

   %$self = ();
}

package DC::NPCDialog;

our @ISA = 'DC::UI::Toplevel';

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      x       => 'center',
      y       => 'center',
      name    => "npc_dialog",
      force_w => $::WIDTH * 0.7,
      force_h => $::HEIGHT * 0.7,
      title   => "NPC Dialog",
      kw      => { hi => 0, yes => 0, no => 0 },
      has_close_button => 1,
      @_,
   );

   DC::weaken (my $this = $self);

   $self->connect (delete => sub { $this->destroy; 1 });

   # better use a pane...
   $self->add (my $hbox = new DC::UI::HBox);
   $hbox->add ($self->{textview} = new DC::UI::TextScroller expand => 1);

   $hbox->add (my $vbox = new DC::UI::VBox);

   $vbox->add (new DC::UI::Label text => "Message Entry:");
   $vbox->add ($self->{entry} = new DC::UI::Entry
      tooltip     => "#npc_message_entry",
      on_activate => sub {
         my ($entry, $text) = @_;

         return unless $text =~ /\S/;

         $entry->set_text ("");
         $this->send ($text);

         0
      },
   );

   $vbox->add ($self->{options} = new DC::UI::VBox);

   $self->{bye_button} = new DC::UI::Button
      text        => "Bye (close)",
      tooltip     => "Use this button to end talking to the NPC. This also closes the dialog window.",
      on_activate => sub { $this->destroy; 1 },
   ;

   $self->update_options;

   $self->{id} = "npc-channel-" . $self->{conn}->token;
   $self->{conn}->connect_ext ($self->{id} => sub {
      $this->feed (@_) if $this;
   });

   $self->{conn}->send_ext_msg (npc_dialog_begin => $self->{id}, $self->{token});

   $self->{entry}->grab_focus;

   $self->{textview}->add_paragraph ({
      fg     => [1, 1, 0, 1],
      markup => "<small>[starting conversation with <b>$self->{title}</b>]</small>\n\n",
   });

   $self->show;
   $self
};

sub update_options {
   my ($self) = @_;

   DC::weaken $self;

   $self->{options}->clear;
   $self->{options}->add ($self->{bye_button});

   for my $kw (sort keys %{ $self->{kw} }) {
      $self->{options}->add (new DC::UI::Button
         text => $kw,
         on_activate => sub {
            $self->send ($kw);
            0
         },
      );
   }
}

sub feed {
   my ($self, $type, @arg) = @_;

   DC::weaken $self;

   if ($type eq "update") {
      my (%info) = @arg;

      $self->{kw}{$_} = 1 for @{$info{add_topics} || []};
      $self->{kw}{$_} = 0 for @{$info{del_topics} || []};
      
      if (exists $info{msg}) {
         my $text = "\n" . DC::Protocol::sanitise_xml $info{msg};
         my $match = join "|", map "\\b\Q$_\E\\b", sort { (length $b) <=> (length $a) } keys %{ $self->{kw} };
         my @link;
         $text =~ s{
            ($match)
         }{
            my $kw = $1;

            push @link, new DC::UI::Label
               markup     => "<span foreground='#c0c0ff' underline='single'>$kw</span>",
               can_hover  => 1,
               can_events => 1,
               padding_x  => 0,
               padding_y  => 0,
               on_button_up => sub {
                  $self->send ($kw);
               };

            "\x{fffc}"
         }giex;
         
         $self->{textview}->add_paragraph ({ markup => $text, widget => \@link });
         $self->{textview}->scroll_to_bottom;
      }

      $self->update_options;
   } else {
      $self->destroy;
   }

   1
}

sub send {
   my ($self, $msg) = @_;

   $self->{textview}->add_paragraph ({
      markup =>
         "\n<span foreground='#ffff00'><b>"
         . (DC::asxml $msg)
         . "</b></span>"
   });
   $self->{textview}->scroll_to_bottom;

   $self->{conn}->send_ext_msg (npc_dialog_tell => $self->{id}, $msg);
}

sub destroy {
   my ($self) = @_;

   #Carp::cluck "debug\n";#d# #todo# enable: destroy gets called twice because scalar keys {} is 1

   if ($self->{conn}) {
      $self->{conn}->send_ext_msg (npc_dialog_end => $self->{id}) if $self->{id};
      delete $self->{conn}{npc_dialog};
      $self->{conn}->disconnect_ext ($self->{id});
   }

   $self->SUPER::destroy;
}

1

