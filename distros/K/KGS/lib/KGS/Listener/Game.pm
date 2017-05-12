package KGS::Listener::Game;

use base KGS::Listener::Channel;
use base KGS::Game::Tree;

sub listen {
   my $self = shift;
   $self->SUPER::listen (@_,
                         qw(upd_observers: del_observer: upd_game: del_game:
                            set_tree: add_tree: upd_tree: resign_game:
                            req_undo: set_teacher: superko: final_result:
                            owner_left: teacher_left: req_result: challenge:
                            set_gametime: new_game: reject_challenge:
                            out_of_time: game_done: set_comments: add_comments:
                            more_comments: already_playing));
}

sub join {
   my ($self) = @_;
   return if $self->{joined};

   $self->SUPER::join ("join_game");
}

sub part {
   my ($self) = @_;
   $self->SUPER::part ("part_game");
}

sub say {
   my ($self, $msg) = @_;
   $self->send (msg_game => channel => $self->{channel}, message => $msg);
}

sub done {
   my ($self) = @_;
   $self->send (game_done => channel => $self->{channel}, id => $self->{doneid} & 0x7fffffff);
}

sub inject_upd_observers {
   my ($self, $msg) = @_;

   $self->add_users ($msg->{users});
}

sub inject_del_observer {
   my ($self, $msg) = @_;

   $self->del_users ([$msg]);
}

sub inject_upd_game {
   my ($self, $msg) = @_;

   my $game = $msg->{game};

   while (my ($k, $v) = each %$game) { $self->{$k} = $v }
   $self->event_update_game;
}

sub inject_set_teacher {
   my ($self, $msg) = @_;

   length $msg->{name}
      ? $self->{teacher} = $msg->{name}
      : delete $self->{teacher};

   $self->event_update_game;
}

sub inject_owner_left {
   my ($self, $msg) = @_;

   $self->event_owner_left ($msg->{message});
}

sub inject_teacher_left {
   my ($self, $msg) = @_;

   $self->event_teacher_left ($msg->{message});
}

sub inject_del_game {
   my ($self, $msg) = @_;

   $self->del_users (values %{$self->{users}});
}

sub inject_set_tree {
   my ($self, $msg) = @_;

   $self->update_tree ($msg->{tree})
      and $self->event_update_tree;

   $self->{loaded} = 1;
}

sub inject_add_tree {
   my ($self, $msg) = @_;

   $self->update_tree ($msg->{tree});
   $self->send (get_tree => channel => $self->{channel}, node => @{$self->{tree}} - 1);
}

sub inject_set_comments {
   my ($self, $msg) = @_;

   $self->update_tree ([
      [set_node => $msg->{node}],
      [comment => undef], # delete comments
      [comment => $msg->{comments}],
      [set_node => $self->{curnode}{id} - 1], # check wether required by protocol
   ]);
}

sub inject_add_comments {
   my ($self, $msg) = @_;

   $self->update_tree ([
      [set_node => $msg->{node}],
      [comment => $msg->{comments}],
      [set_node => $self->{curnode}{id} - 1], # check wether required by protocol
   ]);
}

sub inject_more_comments {
   my ($self, $msg) = @_;

   $self->send ($msg); # yes!
}

sub inject_upd_tree {
   my ($self, $msg) = @_;

   return unless $self->{loaded};

   $self->update_tree ($msg->{tree})
      and $self->event_update_tree;

   delete $self->{doneid} if $self->{curnode}{score};
}

sub inject_reject_challenge {
   my ($self, $msg) = @_;

   $self->event_reject_challenge ($msg);
}

sub inject_challenge {
   my ($self, $msg) = @_;

   $self->event_challenge ($msg);
}

sub inject_already_playing {
   my ($self, $msg) = @_;

   $self->event_already_playing ($msg);
}

sub inject_resign_game {
   my ($self, $msg) = @_;

   $self->event_resign_game ($msg->{player});
}

sub inject_out_of_time {
   my ($self, $msg) = @_;

   $self->event_out_of_time ($msg->{player});
}

sub inject_game_done {
   my ($self, $msg) = @_;

   $self->{doneid} = $msg->{id};
   $self->{done} = [$msg->{black}, $msg->{white}];

   $self->event_done;
}

sub event_join {
   my ($self) = @_;

   $self->SUPER::event_join;
   $self->init_tree unless $self->{joined};
}

# sub inject_del_game { # what to do? when?

=item event_update_game

=cut

# ()
sub event_update_game { }

# $msg
sub event_challenge { }

# $player
sub event_out_of_time { }

# $player
sub event_resign_game { }

# ()
sub event_resign_done { }

# ()
sub event_owner_left { }
sub event_teacher_left { }

sub event_reject_challenge {
   my ($self) = @_;

   $self->event_part;
}

# ()
sub event_already_playing {
   my ($self) = @_;

   $self->event_part;
}

1;



