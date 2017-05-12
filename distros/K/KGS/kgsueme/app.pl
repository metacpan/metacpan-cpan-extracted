package app;

use KGS::Protocol::Client;

use Scalar::Util;

use base KGS::Listener;

use Glib::Object::Subclass
   Gtk2::Window;

my %context_id;

our $self;

sub status {
   my ($type, $text) = @_;

   $::self->{status}->pop ($context_id{$type}) if $context_id{$type};
   $::self->{status}->push ($context_id{$type} ||= $::self->{status}->get_context_id ($type), $text) if $text;
}

sub new {
   my ($self, %arg) = @_;

   $self = $self->Glib::Object::new;
   $self->{$_} = delete $arg{$_} for keys %arg;
   gtk::state $self, "main::window", undef, window_size => [700, 580];

   $self->set (allow_shrink => 1);

   Scalar::Util::weaken ($::self = $self); # singleton...

   $self->{protocol} = new KGS::Protocol::Client;

   $self->{roomlist} = new roomlist app => $self;

   $self->set_title ('kgsueme');
   $self->signal_connect (destroy => sub { %{$_[0]} = () });
   $self->signal_connect (delete_event => sub { main_quit Gtk2; 1 });

   $self->add (my $vbox = new Gtk2::VBox);

   $vbox->pack_start (($buttonbox = new Gtk2::HButtonBox), 0, 1, 0);
   $buttonbox->set_spacing (0);

   my $button = sub {
      $buttonbox->add (my $button = new Gtk2::Button $_[0]);
      signal_connect $button clicked => $_[1];
   };

   $button->("Login", sub { $self->login; });
   $button->("Roomlist", sub { $self->{roomlist}->show; });
   $button->("Save Layout", \&util::save_config);
   $button->("Logout", sub { $self->{conn}->send ("quit") if $self->{conn} });
   $button->("Quit", sub { main_quit Gtk2 });

   $vbox->pack_start ((my $hbox = new Gtk2::HBox), 0, 1, 0);

   $hbox->add (new Gtk2::Label "Login");

   $hbox->add ($self->{login} = new_with_max_length Gtk2::Entry 12);
   $self->{login}->set_text ($::config->{login});

   $hbox->add (new Gtk2::Label "Password");
   $hbox->add ($self->{password} = new Gtk2::Entry);
   $self->{password}->set (visibility => 0, is_focus => 1);
   $self->{password}->signal_connect (activate => sub { $self->login });

   $vbox->pack_start ((my $vpane = new Gtk2::VPaned), 1, 1, 0);
   $vpane->set (position_set => 1);
   gtk::state $vpane, "main::vpane", undef, position => 300;

   $vbox->pack_start(($self->{status} = new Gtk2::Statusbar), 0, 1, 0);

   $self->{gamelist} = new gamelist app => $self;
   $vpane->pack1 ($self->{gamelist}, 1, 1);

   $self->{rooms} = new Gtk2::Notebook;
   $self->{rooms}->set (enable_popup => 1, scrollable => 1);

   $vpane->pack2 ($self->{rooms}, 1, 1);

   $self->show_all;

   $self;
}

sub login {
   my ($self) = @_;

   $self->{protocol}->disconnect;

   # initialize new socket and connection
   my $sock = new IO::Socket::INET PeerHost => KGS::Protocol::KGSHOST, PeerPort => KGS::Protocol::KGSPORT
      or do {
         app::status ("connect", "connect: $!");
         $self->event_quit;
         return;
      };

   $self->{login}->set (sensitive => 0);
   $self->{password}->set (sensitive => 0);

   $sock->blocking (1);
   $self->{protocol}->handshake ($sock);
   $sock->blocking (0);

   $self->listen ($self->{protocol});
   $self->{roomlist}->listen ($self->{protocol});
   #$self->{gamelist}->listen ($conn);

   # now login
   $ENV{KGSUEME_CLIENTVER} ||= "1.4.2_03:Swing app:Sun Microsystems Inc."; # he asked for it...#d#
   $self->{protocol}->login ($ENV{KGSUEME_CLIENTVER} || "kgsueme $VERSION $^O", # allow users to overwrite
                             $self->{login}->get_text,
                             $self->{password}->get_text,
                             "en_US");

   my $input; $input = add_watch Glib::IO fileno $sock, [G_IO_IN, G_IO_ERR, G_IO_HUP], sub {
      # this is dorked
      my $buf;
      my $len = sysread $sock, $buf, 16384;
      if ($len) {
         $self->{protocol}->feed_data ($buf);
      } elsif (defined $len || (!$!{EINTR} and !$!{EAGAIN})) {
         remove Glib::Source $input;
         $self->{protocol}->disconnect;
         warn "disconnect: $!";#TODO#
         app::status ("disconnect", "$!");#TODO# not visible
      }
      1;
   }, G_PRIORITY_HIGH;
}

sub inject_login {
   my ($self, $msg) = @_;

   $self->{name} = $self->{conn}{name};

   $::config->{login} = $self->{name};

   app::status("login", "logged in as '$self->{name}' with status '$msg->{message}' ('$msg->{reason}')");

   if ($msg->{success}) {
      # auto-join
      $self->open_room (%$_) for values %{$::config->{rooms}};

      sound::play 3, "connect";
   } elsif ($msg->{result} eq "user unknown") {
      sound::play 2, "user_unknown";
   } else {
      sound::play 2, "warning";
   }
}

sub listen {
   my $self = shift;

   $self->SUPER::listen (@_, qw(login userpic idle_warn msg_chat chal_defaults upd_rooms));
}

sub inject_idle_warn {
   my ($self, $msg) = @_;

   $self->send ("idle_reset");
}

sub inject_msg_chat {
   my ($self, $msg) = @_;

   if ((lc $msg->{name2}) eq (lc $self->{name})) {
      unless ($self->{user}{lc $msg->{name}}) {
         $self->open_user (name => $msg->{name})->inject ($msg);
         sound::play 2, "ring";
      }
   }
}

sub inject_upd_rooms {
   my ($self, $msg) = @_;

   return if %{$self->{room}};

   # join default room
   for (@{$msg->{rooms}}) {
      $self->open_room (%$_) if $_->is_default;#d#
   }
}

sub inject_chal_defaults {
   my ($self, $msg) = @_;

   $self->{defaults} = $msg->{defaults};
}

my %userpic;
my %userpic_cb;

# static method to request the userimage and call the cb when it's available.
sub userpic {
   my ($self, $name, $cb) = @_;
   $self->get_userpic ($name, $cb);
}

sub get_userpic {
   my ($self, $name, $cb) = @_;

   if (exists $userpic{$name}) {
      $cb->($userpic{$name});
   } else {
      if (!exists $userpic_cb{$name}) {
         # after 10 seconds, flush callbacks
         $self->send (req_pic => name => $name);
         add Glib::Timeout 10000, sub {
            $_->() for @{delete $userpic_cb{$name} || []};
            0;
         };
      }
      push @{$userpic_cb{$name}}, $cb;
   }
}

sub inject_userpic {
   my ($self, $msg) = @_;

   $userpic{$msg->{name}} = $msg->{data};
   $_->($userpic{$msg->{name}}) for @{delete $userpic_cb{$msg->{name}} || []};
}

sub event_quit {
   my ($self) = @_;

   $self->SUPER::event_quit;

   $self->{login}->set (sensitive => 1);
   $self->{password}->set (sensitive => 1);

   sound::play 2, "warning";
}

sub open_game {
   my ($self, %arg) = @_;

   ($self->{game}{$arg{channel}} ||= new game %arg, conn => $self->{conn}, app => $self)
      ->join;
   Scalar::Util::weaken $self->{game}{$arg{channel}};
   $self->{game}{$arg{channel}};
}

sub open_room {
   my ($self, %arg) = @_;

   my $room = $self->{room}{$arg{channel}} ||= do {
      my $room = new room %arg, conn => $self->{conn}, app => $self;
      $room->show_all;
      $self->{rooms}->append_page ($room, new Gtk2::Label $room->{name});
      $room;
   };
   Scalar::Util::weaken $self->{room}{$arg{channel}};

   $room->join;
   $self->{room}{$arg{channel}};
}

sub open_user {
   my ($self, %arg) = @_;

   ($self->{user}{lc $arg{name}} ||= new user %arg, conn => $self->{conn}, app => $self)
      ->join;
   Scalar::Util::weaken $self->{user}{lc $arg{name}};
   $self->{user}{lc $arg{name}};
}

sub do_command {
   my ($self, $chat, $cmd, $arg, %arg) = @_;

   if ($cmd eq "say") {
      if (my $context = $arg{game} || $arg{room} || $arg{user}) {
         $context->say ($arg);
      } else {
         $chat->append_text ("\n<error>no context for message</error>");
      }
   } elsif ($cmd eq "whois" or $cmd eq "w") {
      $self->open_user (name => $arg);
   } else {
      $chat->append_text ("\n<error>unknown command</error>");
   }
}

1;

