package Hoppy::Room::Memory;
use strict;
use warnings;
use Hoppy::User;
use base qw(Hoppy::Base);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->create_room('global');
    return $self;
}

sub create_room {
    my $self    = shift;
    my $room_id = shift;
    unless ( $self->{rooms}->{$room_id} ) {
        $self->{rooms}->{$room_id} = {};
    }
}

sub delete_room {
    my $self    = shift;
    my $room_id = shift;
    if ( $room_id ne 'global' ) {
        my $room = $self->{rooms}->{$room_id};
        for my $user_id ( keys %$room ) {
            $self->delete_user($user_id);
        }
        delete $self->{rooms}->{$room_id};
    }
}

sub login {
    my $self   = shift;
    my $args   = shift;
    my $poe    = shift;
    my $c      = $self->context;
    my $result = 1;
    if ( $c->service->{auth_login} ) {
        $result = $c->service->{auth_login}->work( $args, $poe );
        return 0 unless $result;
    }
    my $user_id    = $args->{user_id};
    my $password   = $args->{password};
    my $session_id = $args->{session_id};
    my $room_id    = $args->{room_id} || 'global';
    delete $c->{not_authorized}->{$session_id};
    my $user = Hoppy::User->new(
        user_id    => $user_id,
        session_id => $session_id
    );
    $self->{rooms}->{$room_id}->{$user_id} = $user;
    $self->{where_in}->{$user_id}          = $room_id;
    $self->{sessions}->{$session_id}       = $user_id;
    return $result;
}

sub logout {
    my $self   = shift;
    my $args   = shift;
    my $poe    = shift;
    my $c      = $self->context;
    my $result = 1;
    if ( $c->service->{auth_logout} ) {
        $result = $c->service->{auth_logout}->work( $args, $poe );
        return 0 unless $result;
    }
    my $user_id = $args->{user_id};
    my $user    = $self->fetch_user_from_user_id($user_id);
    delete $self->{sessions}->{ $user->session_id };
    my $room_id = delete $self->{where_in}->{$user_id};
    delete $self->{rooms}->{$room_id}->{$user_id};
    $self->context->{not_authorized}->{ $user->session_id } = 1;
    return $result;
}

sub fetch_user_from_user_id {
    my $self    = shift;
    my $user_id = shift;
    return unless ($user_id);
    my $room_id = $self->{where_in}->{$user_id};
    return $self->{rooms}->{$room_id}->{$user_id};
}

sub fetch_user_from_session_id {
    my $self       = shift;
    my $session_id = shift;
    return unless ($session_id);
    my $user_id = $self->{sessions}->{$session_id};
    return $self->fetch_user_from_user_id($user_id);
}

sub fetch_users_from_room_id {
    my $self    = shift;
    my $room_id = shift;
    my @users   = values %{ $self->{rooms}->{$room_id} };
    return \@users;
}

1;
__END__

=head1 NAME

Hoppy::Room::Memory - Room on memory. It manages users and their sessions.

=head1 SYNOPSIS

  use Hoppy;

  my $server = Hoppy->new;
  my $room = $server->room; # get room object from the Hoppy.

  # longin and logout are handled automatically.
  $room->login(...);
  $room->logout(...);

  # create or delete a new room.
  $room->create_room('hoge');
  $room->delete_room('hoge');

  # you can fetch user(s) object from any ID.
  my $user  = $room->fetch_user_from_user_id($user_id);
  my $user  = $room->fetch_user_from_session_id($session_id);
  my $users = $room->fetch_users_from_room_id($room_id);

=head1 DESCRIPTION

Room on memory. It manages users and their sessions.

=head1 METHODS

=head2 new

=head2 create_room($room_id); 

=head2 delete_room($room_id);

=head2 login(\%args,$poe_object);

  %args = (
    user_id    => $user_id,
    session_id => $session_id,
    password   => $password,  #optional
    room_id    => $room_id,   #optional
  );

=head2 logout(\%args, $poe_object);

  %args = ( user_id => $user_id );

=head2 fetch_user_from_user_id($user_id) 

=head2 fetch_user_from_session_id($session_id) 

=head2 fetch_users_from_room_id($room_id) 

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut