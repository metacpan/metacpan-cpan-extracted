package room;

use KGS::Constants;

use base KGS::Listener::Room;

use Glib::Object::Subclass
   Gtk2::Frame;

sub new {
   my ($self, %arg) = @_;

   $self = $self->Glib::Object::new;
   $self->{$_} = delete $arg{$_} for keys %arg;

   $self->signal_connect (destroy => sub {
      delete $::config->{rooms}{$self->{channel}};
      delete $self->{app}{room}{$self->{channel}};
      (remove Glib::Source delete $self->{gameupdate}) if $self->{gameupdate};
      $self->unlisten;
      %{$_[0]} = ();
   });

   $self->listen ($self->{conn}, qw(msg_room:));

   $self->signal_connect (delete_event => sub { $self->part; 1 });

   $self->add (my $hpane = new Gtk2::HPaned);
   gtk::state $hpane, "room::hpane", undef, position => 500;

   $hpane->pack1 (($self->{chat} = new chat app => $self->{app}), 1, 0);
   
   $self->{chat}->signal_connect (command => sub {
      my ($chat, $cmd, $arg) = @_;
      $self->{app}->do_command ($chat, $cmd, $arg, userlist => $self->{userlist}, room => $self);
   });

   $hpane->pack2 ((my $vbox = new Gtk2::VBox), 1, 0);

   $vbox->pack_start ((my $button = new_with_label Gtk2::Button "Leave"), 0, 1, 0);
   $button->signal_connect (clicked => sub { $self->part });
   
   $vbox->pack_start ((my $button = new_with_label Gtk2::Button "New Game"), 0, 1, 0);
   $button->signal_connect (clicked => sub { $self->new_game });  
   $vbox->pack_start((my $sw = new Gtk2::ScrolledWindow), 1, 1, 0);

   $sw->set_policy ("automatic", "always");

   $sw->add ($self->{userlist} = new userlist);

   $self;
}

sub FINALIZE_INSTANCE { print "FIN room\n" } # never called MEMLEAK #d#TODO#

sub part {
   my ($self) = @_;

   $self->hide;
   $self->SUPER::part;
}

sub inject_msg_room {
   my ($self, $msg) = @_;

   # secret typoe ;-)
   $self->{chat}->append_text ("\n<user>" . (util::toxml $msg->{name})
                               . "</user>: " . (util::toxml $msg->{message}));
}

sub event_update_users {
   my ($self, $add, $update, $remove) = @_;

   $self->{userlist}->update ($add, $update, $remove);
}

sub event_update_games {
   my ($self, $add, $update, $remove) = @_;

   $self->{app}{gamelist}->update ($self, $add, $update, $remove);

   # try to identify any new games assigned to us. stupid protocol
   # first updates the game, joins you and THEN tells you that
   # which of the games you asked for this is.

   for (@$add) {
      if (($_->{black}{name} eq $self->{conn}{name}
           || $_->{white}{name} eq $self->{conn}{name}
           || $_->{owner}{name} eq $self->{conn}{name})
          && (my $game = shift @{$self->{new_game}})) {
         $game->inject_upd_game ({ game => $_ });
         $game->set_channel ($game->{channel});
      }
   }
}

sub event_join {
   my ($self) = @_;
   $self->SUPER::event_join;

   $::config->{rooms}{$self->{channel}} = { channel => $self->{channel}, name => $self->{name} };

   # mysteriously enough, we have to request game updates manually
   $self->{gameupdate} ||= add Glib::Timeout INTERVAL_GAMEUPDATES * 1000, sub {
      $self->req_games;
      1;
   };

   $self->show_all;
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

sub event_update_roominfo {
   my ($self) = @_;

   $self->{chat}->append_text("\n<user>" . (util::toxml $self->{owner}) . "</user>\n"
                              . "<description>" . (util::toxml $self->{description}) . "</description>\n");
}

sub new_game {
   my ($self) = @_;

   my $game = new game conn => $self->{conn}, app => $self->{app}, roomid => $self->{channel};
   $game->new_game_challenge;
   $game->show_all;

   push @{$self->{new_game}}, $game;
}

1;

