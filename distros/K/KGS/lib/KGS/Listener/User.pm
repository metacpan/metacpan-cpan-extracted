package KGS::Listener::User;

use base KGS::Listener;

sub listen {
   my $self = shift;
   $self->SUPER::listen(@_,
                        qw(msg_chat usergraph game_record userinfo notify_event));
}

sub userinfo {
   my ($self) = @_;

   return if $self->{userinfo};

   $self->send (req_userinfo => name => $self->{name});
}

sub game_record {
   my ($self) = @_;

   return if $self->{game_record};

   $self->send (req_game_record =>
                name => $self->{name});
}

sub usergraph {
   my ($self) = @_;

   return if $self->{usergraph};

   $self->send (req_usergraph =>
                name => $self->{name});
}

sub say {
   my ($self, $msg) = @_;

   $self->send (msg_chat =>
                name => $self->{conn}{name},
                name2 => $self->{name},
                message => $msg);
}

sub _name {
   my ($self, $name) = @_;

   if ((lc $name) eq (lc $self->{name})) {
      if ($name ne $self->{name}) {
         $self->{name} = $name;
         $self->event_name;
      }
      return 1;
   } else {
      return 0;
   }
}

sub inject_msg_chat {
   my ($self, $msg) = @_;

   return unless $self->_name ($msg->{name}) || $self->_name ($msg->{name2});

   $self->event_msg ($msg->{name}, $msg->{message})
}

sub inject_usergraph {
   my ($self, $msg) = @_;

   return unless $self->_name ($msg->{name});

   $self->{usergraph} = $msg->{data};

   $self->event_usergraph;
}

sub inject_game_record {
   my ($self, $msg) = @_;

   return unless $self->_name ($msg->{name});

   push @{$self->{game_record}}, @{$msg->{games}};

   if ($msg->{more}) {
      $self->send (req_game_record =>
                   name      => $self->{name},
                   timestamp => $msg->{games}[0]{timestamp});
   } else {
      $self->event_game_record;
   }
}

sub inject_notify_event {
   my ($self, $msg) = @_;

   return unless $self->_name ($msg->{user}{name});

   if ($msg->{event} == 0) {
      $self->{flags} = $msg->{user}{flags};
   }

   # update gamerecord etc.
   warn "\007notify_event in User.pm not yet implemented!\n";
}

sub inject_userinfo {
   my ($self, $msg) = @_;

   return unless $self->_name ($msg->{user}{name});

   $self->{userinfo} = $msg;

   $self->event_userinfo;
}

sub event_userinfo { }
sub event_usergraph { }
sub event_msg { }
sub event_game_record { }
sub event_name { }

1;



