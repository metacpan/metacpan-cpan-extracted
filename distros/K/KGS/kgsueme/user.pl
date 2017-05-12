package user;

use List::Util;

use base KGS::Listener::User;

use Glib::Object::Subclass
   Gtk2::Window;

use Gtk2::SimpleList;

sub new {
   my ($self, %arg) = @_;
   $self = $self->Glib::Object::new;
   $self->{$_} = delete $arg{$_} for keys %arg;

   $self->listen ($self->{conn});

   $self->send (notify_add => name => $self->{name})
      unless (lc $self->{name}) eq (lc $self->{app}{name});

   gtk::state $self, "user::window", undef, window_size => [500, 500];

   $self->event_name;

   $self->signal_connect (destroy => sub { %{$_[0]} = () });
   #$self->signal_connect (delete_event => sub { $self->destroy; 1 });
   $self->signal_connect (delete_event => sub { $self->hide; 1 });

   my $notebook = new Gtk2::Notebook;

   $notebook->signal_connect (switch_page => sub {
      my ($notebook, undef, $page) = @_;

      $self->game_record if $page == 1;
      $self->usergraph   if $page == 2;
   });

   $self->add ($notebook);

   $self->{chat} = new chat;
   $self->{chat}->signal_connect(command => sub {
      my ($chat, $cmd, $arg) = @_;
      $self->{app}->do_command ($chat, $cmd, $arg, user => $self);
   });

   $self->{info_inlay} = $self->{chat}->new_switchable_inlay("Info:", sub { $self->draw_info(@_) }, 1);

   $notebook->append_page ($self->{chat}, (new_with_mnemonic Gtk2::Label "_Chat"));

   $self->{page_record} = new Gtk2::ScrolledWindow;
   $self->{page_record}->set_policy ("automatic", "always");
   $self->{page_record}->add ($self->{record_list} = Gtk2::SimpleList->new(
      Time  => "text",
      White => "text",
      Black => "text",
      Size  => "int",
      H     => "int",
      Komi  => "text",
      Score => "text",
   ));
   my $i = 0;
   $_->set_sort_column_id ($i++) for $self->{record_list}->get_columns;

   $notebook->append_page ($self->{page_record}, (new_with_mnemonic Gtk2::Label "_Record"));

   $self->{page_graph} = new Gtk2::Curve;
   $notebook->append_page ($self->{page_graph}, (new_with_mnemonic Gtk2::Label "_Graph"));

   $self->userinfo;

   $self;
}

sub draw_info {
   my ($self, $inlay) = @_;
   return unless defined $self->{userinfo};
   $inlay->append_text (
      "<infoblock>"
      . "\n<leader>Realname:</leader> "   . (util::toxml $self->{userinfo}{realname})
      . "\n<leader>Email:</leader> "      . (util::toxml $self->{userinfo}{email})
      . "\n<leader>Flags:</leader> "      . (util::toxml $self->{userinfo}{user}->flags_string)
      . "\n<leader>Rank:</leader> "       . (util::toxml $self->{userinfo}{user}->rank_string)
      . "\n<leader>Registered:</leader> " . (util::toxml util::date_string($self->{userinfo}{regdate}))
      . "\n<leader>Last Login:</leader> " . (util::toxml util::date_string($self->{userinfo}{lastlogin}))
      . "\n<leader>Comment:</leader>\n"   . (util::toxml $self->{userinfo}{info})
      . "\n<leader>Picture:</leader>"
      . "</infoblock>\n"
   );
   if ($self->{userinfo}{user}->has_pic) {
      $self->{app}->userpic ($self->{name}, sub {
         $inlay->append_widget(gtk::image_from_data $_[0])
            if $_[0];
      });
   }
}

sub join {
   my ($self) = @_;

   $self->show_all;
}

sub event_name {
   my ($self) = @_;

   $self->set_title ("KGS User $self->{name}");
}

sub event_userinfo {
   my ($self) = @_;
   $self->{info_inlay}->refresh;
}

sub event_game_record {
   my ($self) = @_;

   for (@{$self->{game_record}}) {
      push @{$self->{record_list}->{data}}, 
         [
            util::date_string $_->{timestamp},
            $_->{white}->as_string, 
            $_->{black}->as_string, 
            $_->size, 
            (sprintf "%.1d", $_->handicap),
            $_->komi,
            $_->score_string,
         ];
   }
}

sub event_usergraph {
   my ($self) = @_;

   my $graph = $self->{usergraph};

   my $curve = $self->{page_graph};

   if (@$graph) {
      $curve->set_range (0, (scalar @graph) - 1, (List::Util::min @$graph) - 1, (List::Util::max @$graph) + 1);
      $curve->set_vector (@$graph);
   }
}

sub event_msg {
   my ($self, $name, $message) = @_;

   $self->{chat}->append_text ("\n<user>$name</user>: " . util::toxml $message);
}

sub destroy {
   my ($self) = @_;

   $self->send (notify_del => name => $self->{name})
      unless (lc $self->{name}) eq (lc $self->{app}{name});

   $self->SUPER::destroy;
}

1;

