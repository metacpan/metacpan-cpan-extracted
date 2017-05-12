package DC::MessageDistributor;

use common::sense;

sub new {
   my $this  = shift;
   my $class = ref($this) || $this;
   my $self  = { @_ };
   bless $self, $class;

   $self->{dockbar}->add_dock (
      $self->{log} = DC::UI::ChatView->new (
         expand        => 1,
         can_close     => 0,
         can_undock    => 0,
         info => {
            id            => "",
            title         => "Log",
            tooltip       => "<b>Server Log</b>. This text viewer contains all recent message sent by the server.",
            entry_tooltip => "<b>Command Entry</b>. If you enter something and press return/enter here, "
                             . "the line you entered will be sent to the server as a command.",
            reply         => ''
         }
      )
   );

   $self->{dockbar}->select_dockable ($self->{log});

   return $self
}

# called by MAPWIDGET activate console event
sub activate_console {
   # nop
}

# adding channel
sub add_channel {
   my ($self, $chaninfo) = @_;

   $self->{info}->{$chaninfo->{id}} = $chaninfo;
   $self->touch_channel ($chaninfo->{id});
}

# set max paragraphs
sub set_max_par {
   my ($self, $par) = @_;
   for ($self->{log}, values %{$self->{chatview}}) {
      $_->set_max_par ($par);
   }
}

# set fontsize for all chatviews
sub set_fontsize {
   my ($self, $s) = @_;

   for ($self->{log}, values %{$self->{chatview}}) {
      $_->set_fontsize ($s);
   }
}

# push message in
sub message {
   my ($self, $para) = @_;
   my $id = $para->{type};

   if (exists $self->{info}->{$id}) {
      unless (exists $self->{chatview}->{$id}) {
         $self->touch_channel ($id);
      }

      my $cv = $self->{chatview}->{$id};

      unless ($cv) {
         warn "message couldn't be delivered to chatview with "
              ."id '$id', sending it to main log.";
         $self->{log}->message ($para);
         return;
      }

      $cv->message ($para);

   } else {
      $self->{log}->message ($para);
   }
}

sub touch_channel {
   my ($self, $id) = @_;

   if (exists $self->{chatview}->{$id}) {
      $self->update_chat ($id);
   } else {
      $self->init_chat ($id);
   }
}

sub update_chat {
   my ($self, $id) = @_;

   $self->{chatview}->{$id}->update_info ($self->{info}->{$id});
}

sub init_chat {
   my ($self, $id) = @_;

   my $chaninfo = $self->{info}->{$id};
   my $dock = $self->{chatview}->{$id} =
      DC::UI::ChatView->new (
         expand => 1,
         info   => $chaninfo,
      );
   $dock->connect (close_dock => sub {
      delete $self->{chatview}->{$id};
      0
   });
   $self->{dockbar}->add_dock ($dock);
}

1;
