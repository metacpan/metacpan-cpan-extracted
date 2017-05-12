use utf8;

use Scalar::Util ();

### GO CLOCK WIDGET #########################################################

package game::goclock;

# Lo and Behold! I admit it! The rounding stuff etc.. in goclock
# is completely borked.

use Time::HiRes ();

use KGS::Constants;

use Glib::Object::Subclass
   Gtk2::Label;

sub INIT_INSTANCE {
   my $self = shift;

   $self->signal_connect (destroy => sub { $_[0]->stop });

   $self->{set}    = sub { };
   $self->{format} = sub { "???" };
}

sub FINALIZE_INSTANCE {
   my $self = shift;

   $self->stop;
}

sub configure {
   my ($self, $timesys, $main, $interval, $count) = @_;

   if ($timesys == TIMESYS_ABSOLUTE) {
      $self->{format} = sub {
         if ($_[0] < 0) {
            "TIMEOUT";
         } else {
            util::format_time $_[0];
         }
      };

   } elsif ($timesys == TIMESYS_BYO_YOMI) {
      my $low = $interval * $count;

      $self->{format} = sub {
         if ($_[0] < 0) {
            "TIMEOUT";
         } elsif ($_[0] > $low) {
            util::format_time $_[0] - $low;
         } else {
            sprintf "%s (%d)",
                    util::format_time int (($_[0] - 1) % $interval + 1),
                    ($_[0] - 1) / $interval;
         }
      };

   } elsif ($timesys == TIMESYS_CANADIAN) {
      $self->{format} = sub {
         if ($_[0] < 0) {
            "TIMEOUT";
         } elsif (!$self->{moves}) {
            util::format_time $_[0] - $low;
         } else {
            my $time = int (($_[0] - 1) % $interval + 1);

            sprintf "%s/%d =%d",
                    util::format_time $time,
                    $self->{moves},
                    $self->{moves} > 1
                       ? $time / $self->{moves}
                       : $interval;
         }
      };

   } else {
      # none, or unknown
      $self->{format} = sub { "-" }
   }
}

sub refresh {
   my ($self, $timestamp) = @_;
   my $timer = $self->{time} + $self->{start} - $timestamp;

   # we round the timer value slightly... the protocol isn't exact anyways,
   # and this gives smoother timers ;)
   my $timer2 = int $timer + 0.4;

   $self->set_text ($self->{format}->($timer2));

   $timer - int $timer;
}

sub set_time {
   my ($self, $start, $time, $moves) = @_;

   $self->{time}  = $time;
   $self->{moves} = $moves;

   if ($start) {
      $self->{start} = $start;
      $self->start;
   } else {
      $self->stop;
      $self->refresh ($self->{start});
   }
}

sub start {
   my ($self) = @_;

   $self->stop;

   my $timeout; $timeout = sub {
      my $next = $self->refresh (Time::HiRes::time) * 1000;
      $next += 1000 if $next < 0;
      $self->{timeout} = add Glib::Timeout $next, $timeout;
      0;
   };

   $timeout->();
}

sub stop {
   my ($self) = @_;

   remove Glib::Source delete $self->{timeout} if $self->{timeout};
}

### USER PANEL ##############################################################

package game::userpanel;

use KGS::Constants;

use Glib::Object::Subclass
   Gtk2::Frame,
   properties => [
      Glib::ParamSpec->IV ("colour", "colour", "User Colour",
                           COLOUR_BLACK, COLOUR_WHITE, COLOUR_BLACK,
                           [qw(construct-only readable writable)]),
   ];

sub INIT_INSTANCE {
   my ($self) = @_;

   $self->add ($self->{window} = my $window = new Gtk2::EventBox); # for bg

   $window->add (my $vbox = new Gtk2::VBox);

   $vbox->pack_start (($self->{name} = new Gtk2::Label "-"), 1, 1, 0);
   $vbox->pack_start (($self->{info} = new Gtk2::Label "-"), 1, 1, 0);
   $vbox->pack_start (($self->{clock} = new game::goclock), 1, 1, 0);

   $vbox->add ($self->{imagebox} = new Gtk2::VBox);

   $self;
}

sub SET_PROPERTY {
   my ($self, $pspec, $value) = @_;

   $self->{$pspec->get_name} = $value;

   $self->set_name ("userpanel-$self->{colour}");
}

sub configure {
   my ($self, $app, $user, $rules) = @_;

   if ($self->{name}->get_text ne $user->as_string) {
      $self->{name}->set_text ($user->as_string);

      $self->{imagebox}->remove ($_) for $self->{imagebox}->get_children;
      unless ($::config{suppress_userpic}) {
        $self->{imagebox}->add (gtk::image_from_data undef);
      }
      $self->{imagebox}->show_all;

      if ($user->has_pic) {
         # the big picture...
         $app->userpic ($user->{name}, sub {
            return unless $self->{imagebox};

            if ($_[0]) {
               $self->{imagebox}->remove ($_) for $self->{imagebox}->get_children;
               unless ($::config{suppress_userpic}) {
                 $self->{imagebox}->add (gtk::image_from_data $_[0]);
               }
               $self->{imagebox}->show_all;
            }
         });
      }
   }
   
   $self->{clock}->configure (@{$rules}{qw(timesys time interval count)});
}

sub set_captures {
   my ($self, $captures) = @_;

   $self->{info}->set_text ("$captures pris.");
}

sub set_timer {
   my ($self, $start, $time, $moves) = @_;

   $self->{clock}->set_time ($start, $time, $moves);
}

### GAME WINDOW #############################################################

package game;

use Scalar::Util qw(weaken);

use KGS::Constants;
use KGS::Game::Board;

use Gtk2::GoBoard;
use Gtk2::GoBoard::Constants;

use base KGS::Game;
use base KGS::Listener::Game;

use Glib::Object::Subclass
   Gtk2::Window;

use POSIX qw(ceil);

sub new {
   my ($self, %arg) = @_;

   $self = $self->Glib::Object::new;
   $self->{$_} = delete $arg{$_} for keys %arg;

   gtk::state $self, "game::window", undef, window_size => [620, 460];
   $self->set (allow_shrink => 1);

   $self->signal_connect (destroy => sub {
      $self->unlisten;
      delete $self->{app}{game}{$self->{channel}};
      %{$_[0]} = ();
   });#d#

   $self->add (my $hpane = new Gtk2::HPaned);
   gtk::state $hpane, "game::hpane", undef, position => 420;

   # LEFT PANE

   $hpane->pack1 (($self->{left} = new Gtk2::VBox), 1, 0);
   
   $hpane->pack1((my $vbox = new Gtk2::VBox), 1, 1);

   # board box (aspect/canvas)
   
   # RIGHT PANE

   $hpane->pack2 ((my $vbox = new Gtk2::VBox), 1, 1);
   $hpane->set (position_set => 1);

   $vbox->pack_start ((my $frame = new Gtk2::Frame), 0, 1, 0);

   {
      $frame->add (my $vbox = new Gtk2::VBox);
      $vbox->add ($self->{title} = new Gtk2::Label "-");
      $self->{title}->set (visible => 0, no_show_all => 1); # workaround for refresh-bug

      $vbox->add (my $hbox = new Gtk2::HBox);

      $hbox->pack_start (($self->{board_label} = new Gtk2::Label), 0, 0, 0);

      $self->{moveadj} = new Gtk2::Adjustment 1, 1, 1, 1, 5, 0;

      $hbox->pack_start ((my $scale = new Gtk2::HScale $self->{moveadj}), 1, 1, 0);
      $scale->set_draw_value (0);
      $scale->set_digits (0);

      $self->{moveadj}->signal_connect (value_changed => sub {
         $self->{showmove} = int $self->{moveadj}->get_value;
         $self->update_board;
      });
   }

   $vbox->pack_start ((my $hbox = new Gtk2::HBox 1), 0, 1, 0);

   $hbox->add ($self->{userpanel}[$_] = new game::userpanel colour => $_)
      for COLOUR_WHITE, COLOUR_BLACK;

   $vbox->pack_start ((my $buttonbox = new Gtk2::HButtonBox), 0, 1, 0);

   $buttonbox->add ($self->{button_pass} =
      Gtk2::Button->Glib::Object::new (label => "Pass", visible => 0, no_show_all => 1));
   $self->{button_pass}->signal_connect (clicked => sub {
      $self->{board_click}->(255, 255) if $self->{board_click};
   });
   $buttonbox->add ($self->{button_undo} =
      Gtk2::Button->Glib::Object::new (label => "Undo", visible => 0, no_show_all => 1));
   $self->{button_undo}->signal_connect (clicked => sub {
      $self->send (req_undo => channel => $self->{channel});
   });
   $buttonbox->add ($self->{button_resign} =
      Gtk2::Button->Glib::Object::new (label => "Resign", visible => 0, no_show_all => 1));
   $self->{button_resign}->signal_connect (clicked => sub {
      $self->send (resign_game => channel => $self->{channel}, player => $self->{colour});
   });
   
   $vbox->pack_start (($self->{chat} = new chat app => $self->{app}), 1, 1, 0);

   $self->{chat}->signal_connect (tag_event => sub {
      my (undef, $tag, $event, $content) = @_;
   });

   $self->set_channel ($self->{channel});

   $self->show_all;

   $self;
}

sub set_channel {
   my ($self, $channel) = @_;

   $self->{channel} = $channel;

   if (defined $self->{channel}) {
      $self->listen ($self->{conn});

      $self->{rules_inlay} = $self->{chat}->new_switchable_inlay ("Game Setup:", sub { $self->draw_setup (@_) }, 1);
      $self->{users_inlay} = $self->{chat}->new_switchable_inlay ("Users:", sub { $self->draw_users (@_) }, 1);

      $self->signal_connect (delete_event => sub { $self->part; 1 });
      $self->{chat}->signal_connect (command => sub {
         my ($chat, $cmd, $arg) = @_;
         if ($cmd eq "rsave") {
            local $Storable::forgive_me = 1;
            #Storable::nstore { tree => $self->{tree}, curnode => $self->{curnode}, move => $self->{move} }, $arg;#d#
            Storable::nstore { %$self }, $arg;#d#
         } else {
            $self->{app}->do_command ($chat, $cmd, $arg, userlist => $self->{userlist}, game => $self);
         }
      });
   }
}

### JOIN/LEAVE ##############################################################

sub join {
   my ($self) = @_;
   return if $self->{joined};

   $self->SUPER::join;
}

sub part {
   my ($self) = @_;

   $self->hide;
   $self->SUPER::part;
}

sub event_join {
   my ($self) = @_;

   $self->SUPER::event_join (@_);
   $self->init_tree;
   $self->event_update_game;
}

sub event_part {
   my ($self) = @_;

   $self->SUPER::event_part;
   $self->destroy;
}

sub event_quit {
   my ($self) = @_;

   $self->SUPER::event_quit;
   $self->destroy;
}

### USERS ###################################################################

sub draw_users {
   my ($self, $inlay) = @_;

   for (sort keys %{$self->{users}}) {
      $inlay->append_text ("\t<user>" . $self->{users}{$_}->as_string . "</user>");
   }
}

sub event_update_users {
   my ($self, $add, $update, $remove) = @_;

#   $self->{userlist}->update ($add, $update, $remove);

   $self->{challenge}{$_->{name}} && (delete $self->{challenge}{$_->{name}})->{inlay}->destroy
      for @$remove;

   $self->{users_inlay}->refresh;

   my %important;
   $important{$self->{black}{name}}++;
   $important{$self->{white}{name}}++;
   $important{$self->{owner}{name}}++;

   if (my @users = grep $important{$_->{name}}, @$add) {
      $self->{chat}->append_text ("\n<leader>Joins:</leader>");
      $self->{chat}->append_text (" <user>" . $_->as_string . "</user>") for @users;
   }
   if (my @users = grep $important{$_->{name}}, @$remove) {
      $self->{chat}->append_text ("\n<leader>Parts:</leader>");
      $self->{chat}->append_text (" <user>" . $_->as_string . "</user>") for @users;
   }
}

### GAME INFO ###############################################################

sub draw_setup {
   my ($self, $inlay) = @_;

   return unless $self->{joined};

   my $rules = $self->{rules};

   my $text = "";

   $text .= "\nTeacher: <user>" . (util::toxml $self->{teacher}) . "</user>"
      if $self->{teacher};

   $text .= "\nOwner: <user>" . (util::toxml $self->{owner}->as_string) . "</user>"
      if $self->{owner}->is_valid;

   if ($self->is_inprogress) {
      $text .= "\nPlayers: <user>" . (util::toxml $self->{white}->as_string) . "</user>"
               . " vs. <user>" . (util::toxml $self->{black}->as_string) . "</user>";
   }
   $text .= "\nType: " . util::toxml $gametype{$self->type};

   $text .= "\nRuleset: " . $ruleset{$rules->{ruleset}};

   $text .= "\nTime: ";

   if ($rules->{timesys} == TIMESYS_NONE) {
      $text .= "UNLIMITED";
   } elsif ($rules->{timesys} == TIMESYS_ABSOLUTE) {
      $text .= util::format_time $rules->{time};
      $text .= " ABS";
   } elsif ($rules->{timesys} == TIMESYS_BYO_YOMI) {
      $text .= util::format_time $rules->{time};
      $text .= sprintf " + %s (%d) BY", util::format_time $rules->{interval}, $rules->{count};
   } elsif ($rules->{timesys} == TIMESYS_CANADIAN) {
      $text .= util::format_time $rules->{time};
      $text .= sprintf " + %s/%d CAN", util::format_time $rules->{interval}, $rules->{count};
   }
   
   $text .= "\nFlags:";
   $text .= " private"   if $self->is_private;
   $text .= " started"   if $self->is_inprogress;
   $text .= " adjourned" if $self->is_adjourned;
   $text .= " scored"    if $self->is_scored;
   $text .= " saved"     if $self->is_saved;

   if ($self->is_inprogress) {
      $text .= "\nHandicap: " . $self->{handicap};
      $text .= "\nKomi: " . $self->{komi};
      $text .= "\nSize: " . $self->size_string;
   }

   if ($self->is_scored) {
      $text .= "\nResult: " . $self->score_string;
   }

   $inlay->append_text ("<infoblock>$text</infoblock>");

}

sub event_update_game {
   my ($self) = @_;

   $self->SUPER::event_update_game;

   return unless $self->{joined};

   $self->{colour} = $self->player_colour ($self->{conn}{name});
   
   $self->{user}[COLOUR_BLACK] = $self->{black};
   $self->{user}[COLOUR_WHITE] = $self->{white};

   # show board
   if ($self->is_inprogress) {
      if (!$self->{board}) {
         $self->{left}->add ($self->{board} = new Gtk2::GoBoard size => $self->{size});
         $self->{board}->signal_connect (button_release => sub {
            return unless $self->{cur_board};
            if ($_[1] == 1) {
               $self->{board_click}->($_[2], $_[3]) if $self->{board_click};
            }
         });
         $self->{board}->show_all;
      }
      if (my $ch = delete $self->{challenge}) {
         $_->{inlay}->destroy for values %$ch;
      }
      $self->update_cursor;
   }

   my $title = defined $self->{channel}
                  ? $self->owner->as_string . " " . $self->opponent_string
                  : "Game Window";
   $self->set_title ("KGS Game $title");
   $self->{title}->set_text ($title); # title gets redrawn wrongly
   $self->{title}->show; # workaround for refresh-bug

   $self->{rules_inlay}->refresh;

   if (exists $self->{teacher}) {
      $self->{teacher_inlay} ||= $self->{chat}->new_inlay;
      $self->{teacher_inlay}->clear;
      $self->{teacher_inlay}->append_text ("\n<header>Teacher:</header> <user>"
                                           . (util::toxml $self->{teacher}) . "</user>");
   } elsif ($self->{teacher_inlay}) {
      (delete $self->{teacher_inlay})->clear;
   }

   $self->update_cursor;
}

sub event_update_rules {
   my ($self, $rules) = @_;

   $self->{rules} = $rules;

   if ($self->{user}) {
      # todo. gets drawn wrongly

      $self->{userpanel}[$_]->configure ($self->{app}, $self->{user}[$_], $rules)
         for COLOUR_BLACK, COLOUR_WHITE;
   }

   sound::play 3, "gamestart";
   $self->{rules_inlay}->refresh;
}

### BOARD DISPLAY ###########################################################

sub update_timers {
   my ($self, $timers) = @_;

   my $running = $self->{showmove} == @{$self->{path}} && !$self->{teacher};

   for my $colour (COLOUR_BLACK, COLOUR_WHITE) {
      my $t = $timers->[$colour];
      $self->{userpanel}[$colour]->set_timer (
            $running && $colour == $self->{whosemove} && $t->[0],
            $t->[1] || $self->{rules}{time}
                       + ($self->{rules}{timesys} == TIMESYS_BYO_YOMI
                         && $self->{rules}{interval} * $self->{rules}{count}),
            $t->[2]);
   }
}

sub inject_set_gametime {
   my ($self, $msg) = @_;

   $self->{timers} = [
      [$msg->{NOW}, $msg->{black_time}, $msg->{black_moves}],
      [$msg->{NOW}, $msg->{white_time}, $msg->{white_moves}],
   ];

   $self->update_timers ($self->{timers})
      if $self->{showmove} == @{$self->{path}};
}

sub update_cursor {
   my ($self) = @_;

   return unless $self->{cur_board};

   if ($self->{rules}{ruleset} == RULESET_JAPANESE) {
      if ($self->{curnode}{move} == 0) {
         $self->{whosemove} = $self->{handicap} ? COLOUR_WHITE : COLOUR_BLACK;
      } else {
         $self->{whosemove} = 1 - $self->{cur_board}{last};
      }
   } else {
      # Chinese, Aga, NZ all have manual placement
      if ($self->{curnode}{move} < $self->{handicap}) {
         $self->{whosemove} = COLOUR_BLACK;
      } elsif ($self->{curnode}{move} == $self->{handicap}) {
         $self->{whosemove} = $self->{handicap} ? COLOUR_WHITE : COLOUR_BLACK;
      } else {
         $self->{whosemove} = 1 - $self->{cur_board}{last};
      }
   }

   my $running = $self->{showmove} == @{$self->{path}} && $self->is_active;

   delete $self->{board_click};

   if ($self->{teacher} eq $self->{app}{conn}) {
      #TODO# # teaching mode not implemented
      $self->{button_pass}->set (label => "Pass", sensitive => 1);
      $self->{button_pass}->show;
      $self->{button_undo}->hide;
      $self->{button_resign}->hide;
      $self->{board}->set (cursor => undef);

   } elsif ($running && $self->{colour} != COLOUR_NONE) {
      # during game
      $self->{button_undo}->show;
      $self->{button_resign}->show;

      if ($self->{cur_board}{score}) {
         # during scoring
         $self->{button_pass}->set (label => "Done", sensitive => 1);
         $self->{button_pass}->show;
         $self->{board}->set (cursor => sub {
            $_[0] & (MARK_B | MARK_W)
               ? $_[0] ^ MARK_GRAYED
               : $_[0];
         });
         $self->{board_click} = sub {
            if ($_[0] == 255) {
               $self->{button_pass}->sensitive (0);
               $self->done;
            } else {
               $self->send (mark_dead =>
                  channel => $self->{channel},
                  x       => $_[0],
                  y       => $_[1],
                  dead    => !($self->{cur_board}{board}[$_[0]][$_[1]] & MARK_GRAYED),
               );
            }
         };

      } elsif ($self->{colour} == $self->{whosemove}) {
         # normal move
         $self->{button_pass}->set (label => "Pass", sensitive => 1);
         $self->{button_pass}->show;
         $self->{board}->set (cursor => sub {
            $self->{cur_board}
               && $self->{cur_board}->is_valid_move ($self->{colour}, $_[1], $_[2],
                                         $self->{rules}{ruleset} == RULESET_NEW_ZEALAND)
               ? $_[0] | MARK_GRAYED | ($self->{colour} == COLOUR_WHITE ? MARK_W : MARK_B)
               : $_[0];
         });
         $self->{board_click} = sub {
            return unless
               $self->{cur_board}->is_valid_move ($self->{colour}, $_[0], $_[1],
                                      $self->{rules}{ruleset} == RULESET_NEW_ZEALAND);
            $self->send (game_move => channel => $self->{channel}, x => $_[0], y => $_[1]);
            $self->{board}->set (cursor => undef);
            delete $self->{board_click};
            $self->{button_pass}->sensitive (0);
         };
      } else {
         $self->{button_pass}->set (label => "Pass", sensitive => 0);
         $self->{button_pass}->show;
         $self->{board}->set (cursor => undef);
      }
   } else {
      $self->{button_undo}->hide;
      $self->{button_resign}->hide;
      $self->{button_pass}->hide;
      $self->{board}->set (cursor => undef);
      #TODO# # implement coordinate-grabbing
   }
}

sub update_board {
   my ($self) = @_;

   return unless $self->{path};

   $self->{board_label}->set_text ("Move " . ($self->{showmove} - 1));

   $self->{cur_board} = new KGS::Game::Board $self->{size};
   $self->{cur_board}->interpret_path ([@{$self->{path}}[0 .. $self->{showmove} - 1]]);

   $self->{userpanel}[$_]->set_captures ($self->{cur_board}{captures}[$_])
      for COLOUR_WHITE, COLOUR_BLACK;

   $self->{board}->set_board ($self->{cur_board});

   if ($self->{cur_board}{score}) {
      $self->{score_inlay} ||= $self->{chat}->new_inlay;
      $self->{score_inlay}->clear;
      $self->{score_inlay}->append_text ("\n<header>Scoring</header>"
                                         . "\n<score>"
                                         . "White: $self->{cur_board}{score}[COLOUR_WHITE], "
                                         . "Black: $self->{cur_board}{score}[COLOUR_BLACK]"
                                         . "</score>");
   } elsif ($self->{score_inlay}) {
      (delete $self->{score_inlay})->clear;
   }

   $self->update_cursor;

   if ($self->{showmove} == @{$self->{path}}) {
      $self->{timers} = [
         [$self->{lastmove_time}, @{$self->{cur_board}{timer}[0]}],
         [$self->{lastmove_time}, @{$self->{cur_board}{timer}[1]}],
      ];
      $self->update_timers ($self->{timers});
   } else {
      $self->update_timers ([
         [0, @{$self->{cur_board}{timer}[0]}],
         [0, @{$self->{cur_board}{timer}[1]}],
      ]);
   }

}

sub event_update_tree {
   my ($self) = @_;

   (delete $self->{undo_inlay})->clear
      if $self->{undo_inlay};

   $self->{path} = $self->get_path;

   if ($self->{moveadj}) {
      my $upper = $self->{moveadj}->upper;
      my $pos = $self->{moveadj}->get_value;
      my $move = scalar @{$self->{path}};

      $self->{moveadj}->upper ($move);
      
      $self->{moveadj}->changed;
      if ($pos == $upper) {
         $self->{moveadj}->value ($move);
         $self->{moveadj}->value_changed;
      }
   }
}

sub event_update_comments {
   my ($self, $node, $comment, $newnode) = @_;
   $self->SUPER::event_update_comments ($node, $comment, $newnode);

   my $text;

   $text .= "\n<header>Move <move>$node->{move}</move>, Node <node>$node->{id}</node></header>"
      if $newnode;

   for (split /\n/, $comment) {
      $text .= "\n";
      if (s/^([0-9a-zA-Z]+ \[[0-9dkp\?\-]+\])://) {
         $text .= "<user>" . (util::toxml $1) . "</user>:";
      }
      
      # coords only for 19x19 so far
      $_ = util::toxml $_;
      s{
         (
            \b
            (?:[bw])?
            [, ]{0,2}
            [a-hj-t] # valid for upto 19x19
            \s?
            [1-9]?[0-9]
            \b
         )
      }{
         "<coord>$1</coord>";
      }sgexi;

      $text .= $_;
   }

   $self->{chat}->append_text ($text);
}

sub event_move {
   my ($self, $pass) = @_;

   sound::play 1, $pass ? "pass" : "move";
}

### GAMEPLAY EVENTS #########################################################

sub event_resign_game {
   my ($self, $player) = @_;

   sound::play 3, "resign";
   $self->{chat}->append_text ("\n<infoblock><header>Resign</header>"
                               . "\n<user>"
                               . (util::toxml $self->{user}[$player]->as_string)
                               . "</user> resigned."
                               . "\n<user>"
                               . (util::toxml $self->{user}[1 - $player]->as_string)
                               . "</user> wins the game."
                               . "</infoblock>");
}

sub event_out_of_time {
   my ($self, $player) = @_;

   sound::play 3, "timewin";
   $self->{chat}->append_text ("\n<infoblock><header>Out of Time</header>"
                               . "\n<user>"
                               . (util::toxml $self->{user}[$msg->{player}]->as_string)
                               . "</user> ran out of time and lost."
                               . "\n<user>"
                               . (util::toxml $self->{user}[1 - $msg->{player}]->as_string)
                               . "</user> wins the game."
                               . "</infoblock>");
}

sub event_owner_left {
   my ($self) = @_;

   $self->{chat}->append_text ("\n<infoblock><header>Owner left</header>"
                               . "\nThe owner of this game left.</infoblock>");
}

sub event_teacher_left {
   my ($self) = @_;

   $self->{chat}->append_text ("\n<infoblock><header>Teacher left</header>"
                               . "\nThe teacher left the game.</infoblock>");
}

sub event_done {
   my ($self) = @_;

   if ($self->{done}[1 - $self->{colour}] && !$self->{done}[$self->{colour}]) {
      sound::play 2, "info" unless $inlay->{count};
      $self->{chat}->append_text ("\n<infoblock><header>Press Done</header>"
                                  . "\nYour opponent pressed done. Now it's up to you.");
   }
   if ($self->{doneid} & 0x80000000) {
      sound::play 2, "info" unless $inlay->{count};
      $self->{chat}->append_text ("\n<infoblock><header>Press Done Again</header>"
                                  . "\nThe board has changed.");
   }

   $self->{button_pass}->sensitive (!$self->{done}[$self->{colour}]);

   $self->{chat}->set_end;
}

sub inject_final_result {
   my ($self, $msg) = @_;

   $self->{chat}->append_text ("<infoblock>\n<header>Game Over</header>"
                               . "\nWhite Score " . (util::toxml $msg->{whitescore}->as_string)
                               . "\nBlack Score " . (util::toxml $msg->{blackscore}->as_string)
                               . "</infoblock>"
                              );
}

sub inject_req_undo {
   my ($self, $msg) = @_;

   my $inlay = $self->{undo_inlay} ||= $self->{chat}->new_inlay;
   return if $inlay->{ignore};

   sound::play 2, "warning" unless $inlay->{count};
   $inlay->{count}++;

   $inlay->clear;
   $inlay->append_text ("\n<undo>Undo requested ($inlay->{count} times)</undo>\n");
   $inlay->append_button ("Grant", sub {
      (delete $self->{undo_inlay})->clear;
      $self->send (grant_undo => channel => $self->{channel});
   });
   $inlay->append_button ("Ignore", sub {
      $inlay->clear;
      $inlay->{ignore} = 1;
      # but leave inlay, so further undo requests get counted
   });

   $self->{chat}->set_end;
}

sub inject_new_game {
   my ($self, $msg) = @_;

   if ($msg->{cid} != $self->{cid}) {
      $self->part;
      warn "ERROR: challenge id mismatch, PLEASE REPORT, especially the circumstances (many games open? etc..)\n";#d#
   }

   $self->{chat}->append_text ("\n<header>Game successfully created on server.</header>");
   delete $self->{cid};
}

### CHALLENGE HANDLING ######################################################

sub draw_challenge {
   my ($self, $id) = @_;

   my $info  = $self->{challenge}{$id};
   my $inlay = $info->{inlay};
   my $rules = $info->{rules};

   my $as_black = $info->{black}{name} eq $self->{conn}{name} ? 1 : 0;;
   my $opponent = $as_black ? $info->{white} : $info->{black};

   my ($size, $time, $interval, $count, $type);

   if (!defined $self->{channel}) {
      $inlay->append_text ("\nNotes: ");
      $inlay->append_widget (gtk::textentry \$info->{notes}, 20, "");
      $inlay->append_text ("\nGlobal Offer: ");
      $inlay->append_optionmenu (\$info->{flags},
         0 => "No",
         2 => "Yes",
      );
   } else {
      $inlay->append_text ("\nNotes: " . util::toxml $info->{notes});
   }

   $inlay->append_text ("\nType: ");
   $type = $inlay->append_optionmenu (
      \$info->{gametype},
      GAMETYPE_DEMONSTRATION                   , "Demonstration (not yet)",
      GAMETYPE_DEMONSTRATION | GAMETYPE_PRIVATE, "Demonstration (P) (not yet)",
      GAMETYPE_TEACHING                        , "Teaching (not yet)",
      GAMETYPE_TEACHING      | GAMETYPE_PRIVATE, "Teaching (P) (not yet)",
      GAMETYPE_SIMUL                           , "Simul (not yet!)",
      GAMETYPE_FREE                            , "Free",
      GAMETYPE_RATED                           , "Rated",
      sub {
         $size->set_history (2) if $_[0] eq GAMETYPE_RATED;
      },
   );

   if (defined $self->{channel}) {
      $inlay->append_text ("\nMy Colour: ");
      $inlay->append_optionmenu (
         \$as_black,
         0 => "White",
         1 => "Black",
         sub {
            if ($info->{$_[0] ? "black" : "white"}{name} ne $self->{conn}{name}) {
               ($info->{black}, $info->{white}) = ($info->{white}, $info->{black});
            }
         }
      );
   }

   $inlay->append_text ("\nRuleset: ");
   $inlay->append_optionmenu (
      \$info->{rules}{ruleset},
      RULESET_JAPANESE   , "Japanese",
      RULESET_CHINESE    , "Chinese",
      RULESET_AGA        , "AGA",
      RULESET_NEW_ZEALAND, "New Zealand",
   );

   $inlay->append_text ("\nSize: ");
   $size = $inlay->append_optionmenu (
      \$info->{rules}{size},
      (9 => 9, 13 => 13, 19 => 19, map +($_, $_), 2..38),
      sub {
         $type->set_history (5) # reset to free
            if $_[0] != 19 && $info->{gametype} == GAMETYPE_RATED;
      },
   );

   if (defined $self->{channel}) {
      $inlay->append_text ("\nHandicap: ");
      $inlay->append_optionmenu (\$info->{rules}{handicap}, map +($_, $_), 0..9);

      $inlay->append_text ("\nKomi: ");
      $inlay->append_widget (gtk::numentry \$info->{rules}{komi}, 5);
   }

   $inlay->append_text ("\nTimesys: ");
   $inlay->append_optionmenu (
      \$info->{rules}{timesys},
      &TIMESYS_NONE     => "None",
      &TIMESYS_ABSOLUTE => "Absolute",
      &TIMESYS_BYO_YOMI => "Byo Yomi",
      &TIMESYS_CANADIAN => "Canadian",
      sub {
         my ($new) = @_;

         if ($new eq TIMESYS_NONE) {
            $time->hide;
            $interval->hide;
            $count->hide;
         } else {
            $time->show;
            $time->set_text ($self->{app}{defaults}{time});
            if ($new eq TIMESYS_ABSOLUTE) {
               $interval->hide;
               $count->hide;
            } else {
               $interval->show;
               $count->show;
               if ($new eq TIMESYS_BYO_YOMI) {
                  $interval->set_text ($self->{app}{defaults}{byo_time});
                  $count->set_text ($self->{app}{defaults}{byo_period});
               } elsif ($new eq TIMESYS_CANADIAN) {
                  $interval->set_text ($self->{app}{defaults}{can_time});
                  $count->set_text ($self->{app}{defaults}{can_period});
               }
            }
         }
      }
   );

   $inlay->append_text ("\nMain Time: ");
   $time = $inlay->append_widget (gtk::timeentry \$info->{rules}{time}, 5);
   $inlay->append_text ("\nInterval: ");
   $interval = $inlay->append_widget (gtk::timeentry \$info->{rules}{interval}, 5);
   $inlay->append_text ("\nPeriods/Stones: ");
   $count = $inlay->append_widget (gtk::numentry \$info->{rules}{count}, 5);

   $inlay->append_text ("\n");

   if (!defined $self->{channel}) {
      $inlay->append_button ("Create Challenge", sub {
         $inlay->clear;
         $self->{cid} = $self->{conn}->alloc_clientid;
         $self->send (new_game => 
            channel  => delete $self->{roomid},
            gametype => $info->{gametype},
            cid      => $self->{cid},
            flags    => $info->{flags},
            rules    => $info->{rules},
            notes    => $info->{notes},
         );
      });
   } else {
      $inlay->append_button ("OK", sub {
         $inlay->clear;
         $self->send (challenge => 
            channel  => $self->{channel},
            black    => $info->{black},
            white    => $info->{white},
            gametype => $info->{gametype},
            cid      => $info->{cid},
            rules    => $info->{rules},
         );
      });
      if (exists $self->{challenge}{""}) {
         $inlay->append_button ("Reject", sub {
            $inlay->clear;
            $self->send (reject_challenge => 
               channel  => $self->{channel},
               name     => $opponent->{name},
               gametype => $info->{gametype},
               cid      => $info->{cid},
               rules    => $info->{rules},
            );
         });
      }
   }
}

sub new_game_challenge {
   my ($self) = @_;

   my $d = $self->{app}{defaults};

   $self->{challenge}{""} = {
      gametype => $d->{gametype},
      flags    => 0,
      notes    => $d->{stones},
      rules    => {
         ruleset  => $d->{ruleset},
         size     => $d->{size},
         timesys  => $d->{timesys},
         time     => $d->{time},
         interval => $d->{timesys} == TIMESYS_BYO_YOMI ? $d->{byo_time}    : $d->{can_time},
         count    => $d->{timesys} == TIMESYS_BYO_YOMI ? $d->{byo_periods} : $d->{can_stones},
      },

      inlay => $self->{chat}->new_inlay,
   };
   $self->draw_challenge ("");
}

sub event_challenge {
   my ($self, $info) = @_;

   my $as_black = $info->{black}->{name} eq $self->{conn}{name};
   my $opponent = $as_black ? $info->{white} : $info->{black};

   my $id = $opponent->{name};

   sound::play 2, "info";

   $self->{challenge}{$id} = $info;
   $self->{challenge}{$id}{inlay} = $self->{chat}->new_switchable_inlay (
      exists $self->{challenge}{""}
         ? "Challenge from " . $opponent->as_string
         : "Challenge to " . $opponent->as_string,
      sub {
         $self->{challenge}{$id}{inlay} = $_[0];
         $self->draw_challenge ($id);
      },
      !exists $self->{challenge}{""} # only open when not offerer
   );
}

1;

