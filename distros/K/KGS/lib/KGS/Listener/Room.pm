=head1 NAME

KGS::Listener::Room - handle room-related messages for you.

=head1 SYNOPSIS

  use base KGS::Listener::Room;

  # maybe overwrite new
  sub new { ... }

  sub event_update_games {
     ...
  }

  sub event_roominfo {
     ...
  }

=head1 DESCRIPTION

None yet. Please see L<KGS::Listener> and L<KGS::Listener::Channel>.

Automatically listens and handles the following messages for you and calls
event methods:

  join_room: part_room: upd_games: desc_room: msg_room: upd_game del_game

=head2 METHODS

=over 4

=cut

package KGS::Listener::Room;

use base KGS::Listener::Channel;

sub listen {
   my $self = shift;
   $self->SUPER::listen(@_,
                        qw(join_room: part_room: upd_games: desc_room: msg_room:
                           upd_game del_game));
}

=item $room->join

Uses $room->{channel} and $room->{conn}{name} to join the channel.

See C<event_join>.

=cut

sub join {
   my ($self) = @_;
   $self->{games} = {};
   $self->SUPER::join("join_room");
}

=item $room->part

Departs from the room. See C<event_part>.

=cut

sub part {
   my ($self) = @_;
   $self->SUPER::part("part_room");
}

=item $room->say ($msg)

Utter something in the room.

=cut

sub say {
   my ($self, $msg) = @_;
   return unless length $msg;
   $self->send(msg_room => channel => $self->{channel}, name => $self->{conn}{name}, message => $msg);
}

=item $room->req_roominfo

Request a room description. See C<event_roominfo>.

=cut

sub req_roominfo {
   my ($self) = @_;

   $self->send(req_desc => channel => $self->{channel});
}

=item $room->req_games

Request a non-incremental update of the game list. Should be called every
minute or so.

See C<event_update_games>.

=cut

sub req_games {
   my ($self) = @_;
   $self->send(req_games => channel => $self->{channel});
}

sub inject_join_room {
   my ($self, $msg) = @_;

   $self->add_users ($msg->{users});
}

sub inject_part_room {
   my ($self, $msg) = @_;

   $self->del_users ([$msg->{user}]);
}

sub inject_upd_games {
   my ($self, $msg) = @_;

   my @added;
   my @updated;
   my $game;
   for (@{$msg->{games}}) {
      if ($game = $self->{games}{$_->{channel}}) {
         push @updated, $game;
      } else {
         $game = $self->{games}{$_->{channel}} = bless {}, KGS::Game;
         push @added, $game;
      }
      while (my ($k, $v) = each %$_) { $game->{$k} = $v };
   }

   $self->event_update_games (\@added, \@updated, []);
}

sub inject_upd_game {
   my ($self, $msg) = @_;
   return unless exists $self->{games}{$msg->{game}{channel}};

   $self->inject_upd_games ({ games => [ $msg->{game} ] });
}

sub inject_del_game {
   my ($self, $msg) = @_;

   return unless $self->{games}{$msg->{channel}};
   $self->event_update_games ([], [], [delete $self->{games}{$msg->{channel}}]);
}

sub inject_msg_room {
   my ($self, $msg) = @_;

   # nop, should event_*
   #d#
}

sub inject_desc_room {
   my ($self, $msg) = @_;

   $self->{owner}       = $msg->{owner};
   $self->{description} = $msg->{description};

   $self->event_update_roominfo;
}

=item $room->event_join

Called when the user successfully joined the room. This I<can> be called late,
after messages for this room have already been received.

=cut

=item $room->event_part

Called when the user left the room.

=cut

#TODO# should only do this on DESTROY

sub _clear {
   my ($self) = @_;

   $self->event_update_games ([], [], [values %{delete $self->{games} || {}}]);
}

sub event_part {
   my ($self) = @_;

   $self->SUPER::event_part;
   _clear ($self);
}

sub event_quit {
   my ($self) = @_;

   $self->SUPER::event_quit;
   _clear ($self);
}

=item $room->event_update_games ($add, $update, $remove)

Called whenever the game list is updated, either incrementally or on
request. The three parameters are arrayrefs with lists of <KGS::Game>s
that have been newly added (C<$add>), existed but got parameters
(movecount, status etc.) updated (C<$update>) or have been removed
C<$remove>.

You do not need to use these arguments, as the list of games is always
kept up-to-date in C<< $room->{games}{id}{KGS::Game} >>, so you can just
use this hash instead.

=cut

sub event_update_games { }

=item $room->event_update_roominfo

Called whenever the room info gets updated, either on request or server-initiated.

The owner name can be accessed as C<< $room->{owner} >>, while the
descriptive text is stored in C<< $room->{description} >>.

   $self->{owner}       = $msg->{owner};
   $self->{description} = $msg->{description};

=cut

sub event_update_roominfo { }

=back

=cut

1;



